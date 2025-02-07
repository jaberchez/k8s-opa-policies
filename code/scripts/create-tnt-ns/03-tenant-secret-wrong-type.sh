#! /bin/bash

nameSecret="secret-dockercfg"
namespaceFile="/tmp/test.yaml"

trap "kubectl config use-context minikube &> /dev/null; test -e ${namespaceFile} && rm -f ${namespaceFile}" EXIT

echo -n "Changing kubectl context to create-tnt-ns ... "
msg=$(kubectl config use-context create-tnt-ns 2>&1)
[[ $? != 0 ]] && { echo "ERROR"; echo "$msg"; exit 1; }
echo "OK"

echo -n "Creating $nameSecret Secret into default namespace ... "
cat <<END > $namespaceFile
apiVersion: v1
kind: Secret
metadata:
  name: $nameSecret
  namespace: default
type: Opaque
data:
  fakedata: YmFyCg==
END

msg=$(kubectl apply -f $namespaceFile --dry-run=server 2>&1)
[[ $? != 0 ]] && { echo "ERROR"; echo "$msg"; exit 1; }
echo "OK"
exit 0
