# Official Alpine Linux image
FROM alpine:3.11.6

LABEL maintainer="Ryan Craig"

# http://label-schema.org/rc1/ namespace labels
LABEL org.label-schema.schema-version="1.0"
#LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.name="devtestlabs/krb5-sidecar"
LABEL org.label-schema.description="MIT KRB5 sidecar container"
#LABEL org.label-schema.url=$ORG_WEB_URL
#LABEL org.label-schema.vcs-url=$VCS_URL
#LABEL org.label-schema.vcs-ref=$VCS_REF
LABEL org.label-schema.vendor="devtestlabs.xyz"
#LABEL org.label-schema.version=$BUILD_VERSION
LABEL org.label-schema.docker.cmd='docker run ...TODO...'

# KRB5 configuration
ENV KRB5CCNAME=/dev/shm/ccache
ENV KRB5_KTNAME=/krb5/common/krb5.keytab
ENV KRB5_CLIENT_KTNAME=/krb5/common/client.keytab
ENV KRB5_CONFIG=/etc/krb5.conf

# Required packages
ENV APK_PACKAGES \
  krb5 \
  ca-certificates

COPY scripts/entrypoint.sh /usr/local/bin
RUN ln -s /usr/local/bin/entrypoint.sh / # backwards compat

RUN set -x \
    && \
    env \
    && \
    echo "==> Upgrading apk and system..." \
    && apk update && apk upgrade \
    && \
    echo "==> Installing required packages..." \
    && apk add --no-cache ${APK_PACKAGES} \
    && \
    echo "===> Removing default KRB5 config file and provisioning custom config path..." \
    && rm -f /etc/krb5.conf && mkdir /etc/krb5.conf.d \
    && \
    echo "===> Cleaning up..." \
    && chmod +x /usr/local/bin/entrypoint.sh \
    && unset http_proxy https_proxy

VOLUME ["/krb5"]

ENTRYPOINT ["entrypoint.sh"]
