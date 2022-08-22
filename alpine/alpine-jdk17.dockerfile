FROM alpine:3.16.2

# Download and configure packages
# Do as one big step to reduce container size!
RUN apk add --no-cache --upgrade apk-tools busybox expat freetype less libcrypto1.1 libssl1.1 musl musl-utils openjdk17 python3 ssl_client supervisor wget xz && mkdir /var/log/supervisord && mkdir /etc/supervisord

ENTRYPOINT ["tail", "-f", "/dev/null"]