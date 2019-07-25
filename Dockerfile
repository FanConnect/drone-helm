FROM alpine

ENV KUBE_LATEST_VERSION="v1.14.0" \
    HELM_LATEST_VERSION="v2.14.2"

RUN set -ex \
 && apk add --update --no-cache ca-certificates bash \
 && apk add --update --no-cache -t deps curl git binutils \
 && curl -L https://storage.googleapis.com/kubernetes-release/release/${KUBE_LATEST_VERSION}/bin/linux/amd64/kubectl \
      -o /usr/local/bin/kubectl \
 && chmod +x /usr/local/bin/kubectl \
 && curl https://storage.googleapis.com/kubernetes-helm/helm-${HELM_LATEST_VERSION}-linux-amd64.tar.gz \
      -o helm-${HELM_LATEST_VERSION}-linux-amd64.tar.gz \
 && tar -xvf helm-${HELM_LATEST_VERSION}-linux-amd64.tar.gz \
 && rm -f /helm-${HELM_LATEST_VERSION}-linux-amd64.tar.gz \
 && mv linux-amd64/helm /usr/local/bin \
 && helm init --client-only \
 && helm plugin install https://github.com/databus23/helm-diff \
 && helm plugin install https://github.com/futuresimple/helm-secrets \
 && strip /usr/local/bin/sops \
 && apk del --purge deps

COPY entrypoint.sh /usr/local/bin/

ENTRYPOINT ["entrypoint.sh"]
