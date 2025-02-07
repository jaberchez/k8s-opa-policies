#! /bin/bash

name="tnt-test"
k8sfile="/tmp/test.yaml"

trap "kubectl config use-context minikube &> /dev/null; test -e ${k8sfile} && rm -f ${k8sfile}" EXIT

echo -n  "Changing kubectl context to create-tnt-ns ... "
msg=$(kubectl config use-context create-tnt-ns 2>&1)
[[ $? != 0 ]] && { echo "ERROR"; echo "$msg"; exit 1; }
echo "OK"

echo -n "Creating namespace $name ... "
cat <<END > $k8sfile
apiVersion: v1
kind: Namespace
metadata:
  name: $name
END

msg=$(kubectl apply -f $k8sfile --dry-run=server 2>&1)
[[ $? != 0 ]] && { echo "ERROR"; echo "$msg"; exit 1; }
echo "OK"

name="secret-dockercfg"

echo -n "Creating $name Secret into default namespace ... "

cat <<END > $k8sfile
apiVersion: v1
kind: Secret
metadata:
  name: $name
  namespace: default
type: kubernetes.io/dockercfg
data:
  .dockercfg: e30= # Empty object {}
END

msg=$(kubectl apply -f $k8sfile --dry-run=server 2>&1)
[[ $? != 0 ]] && { echo "ERROR"; echo "$msg"; exit 1; }
echo "OK"

name="default-deny-all"

echo -n "Creating $name NetworkPolicy into default namespace ... "

cat <<END > $k8sfile
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: $name
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
