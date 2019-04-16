#!/bin/sh

set -e

if [ "${KUBERNETES_CERTIFICATE}" == "" ]
then
  kubectl config set-cluster helm --insecure-skip-tls-verify=true --server=${API_SERVER}
else
  kubectl config set-cluster helm --server=${API_SERVER}
  kubectl config set clusters.helm.certificate-authority-data ${KUBERNETES_CERTIFICATE}
fi

kubectl config set-context helm --cluster=helm --user=helm
kubectl config set-credentials helm --token=${KUBERNETES_TOKEN}
kubectl config use-context helm

IFS=","
for cmd in ${PLUGIN_HELM_COMMANDS}
do
  sh -ex -c "$cmd"
done
