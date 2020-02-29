# Official Alpine Linux image
FROM alpine:3.11.3

# KRB5 Configuration
ENV KRB5CCNAME=/dev/shm/ccache
ENV KRB5_CONFIG=/dev/shm/krb5-client.conf

# Required packages
ENV APK_PACKAGES \
  krb5 \
  ca-certificates

COPY klist.sh /

RUN set -x && \
    \
    env && \
    \
    echo "==> Upgrading apk and system..."  && \
    apk update && apk upgrade && \
    \
    echo "==> Installing required packages..."  && \
    apk add --no-cache ${APK_PACKAGES} && \
    mkdir /krb5 && chmod 755 /krb5 && \
    rm -f /etc/krb5.conf && \
    \
    echo "==> Cleaning up..."  && \
    chmod +x /klist.sh && \
    unset http_proxy https_proxy

ENTRYPOINT ["/klist.sh"]
