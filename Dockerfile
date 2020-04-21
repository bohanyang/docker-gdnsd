FROM alpine:3.11

ARG GDNSD_VERSION=3.2.2

# Create a system group; Create a system user; Don't assign a password; Don't create home directory
RUN addgroup -S gdnsd && adduser -G gdnsd -S -D -H gdnsd

# https://github.com/gdnsd/gdnsd/blob/master/INSTALL
RUN set -ex; \
    apk add --no-cache su-exec; \
    apk add --no-cache --virtual .build-deps \
        gcc \
        gnupg \
        g++ \
        libev-dev \
        libmaxminddb-dev \
        libsodium-dev \
        make \
        perl \
        ragel \
        userspace-rcu-dev \
    ; \
    mkdir /usr/src; \
    cd /usr/src; \
    wget "https://github.com/gdnsd/gdnsd/releases/download/v$GDNSD_VERSION/gdnsd-$GDNSD_VERSION.tar.xz"; \
    wget "https://github.com/gdnsd/gdnsd/releases/download/v$GDNSD_VERSION/gdnsd-$GDNSD_VERSION.tar.xz.asc"; \
    gpg --keyserver hkps://hkps.pool.sks-keyservers.net --recv-key 950CAAED148E99B5; \
    gpg --verify "gdnsd-$GDNSD_VERSION.tar.xz.asc" "gdnsd-$GDNSD_VERSION.tar.xz"; \
    rm "gdnsd-$GDNSD_VERSION.tar.xz.asc"; \
    su-exec gdnsd:gdnsd tar -xof "gdnsd-$GDNSD_VERSION.tar.xz"; \
    rm "gdnsd-$GDNSD_VERSION.tar.xz"; \
    cd "gdnsd-$GDNSD_VERSION"; \
    su-exec gdnsd:gdnsd ./configure; \
    su-exec gdnsd:gdnsd make -j"$(nproc)"; \
    make install; \
    cd ..; \
    rm -rf "gdnsd-$GDNSD_VERSION"; \
    runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' /usr/local/sbin/gdnsd* \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --virtual .run-deps $runDeps; \
    apk del .build-deps

CMD ["su-exec", "gdnsd:gdnsd", "start"]
