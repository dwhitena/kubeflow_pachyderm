FROM alpine

ENV KUBE_LATEST_VERSION="v1.9.3"

RUN apk add --update ca-certificates \
 && apk add --update -t deps curl \
 && curl -L https://storage.googleapis.com/kubernetes-release/release/${KUBE_LATEST_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl \
 && chmod +x /usr/local/bin/kubectl \
 && apk del --purge deps \
&& rm /var/cache/apk/*

ADD tf_job.sh .
ADD tf_job.yaml .
