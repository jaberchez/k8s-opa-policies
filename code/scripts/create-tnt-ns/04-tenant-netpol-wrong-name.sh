#! /bin/bash

nameNetpol="fake-name"
k8sfile="/tmp/test.yaml"

trap "kubectl config use-context minikube &> /dev/null; test -e ${k8sfile} && rm -f ${k8sfile}" EXIT

echo -n "Changing kubectl context to create-tnt-ns ... "
msg=$(kubectl config use-context create-tnt-ns 2>&1)
[[ $? != 0 ]] && { echo "ERROR"; echo "$msg"; exit 1; }
echo "OK"

echo -n "Creating $nameNetpol NetworkPolicy into default namespace ... "

cat <<END > $k8sfile
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: $nameNetpol
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
END

msg=$(kubectl apply -f $k8sfile --dry-run=server 2>&1)
[[ $? != 0 ]] && { echo "ERROR"; echo "$msg"; exit 1; }
echo "OK"
exit 0
