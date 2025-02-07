#! /bin/bash

namespaceName="test-tenant"
k8sfile="/tmp/test-tenant-ns.yaml"

trap "kubectl config use-context minikube &> /dev/null; test -e ${k8sfile} && rm -f ${k8sfile}" EXIT

echo -n  "Changing kubectl context to create-tnt-ns ... "
msg=$(kubectl config use-context create-tnt-ns 2>&1)
[[ $? != 0 ]] && { echo "ERROR"; echo "$msg"; exit 1; }
echo "OK"

echo -n "Creating namespace $namespaceName ... "
cat <<END > $k8sfile
apiVersion: v1
kind: Namespace
metadata:
  name: $namespaceName
END

msg=$(kubectl apply -f $k8sfile --dry-run=server 2>&1)
[[ $? != 0 ]] && { echo "ERROR"; echo "$msg"; exit 1; }
echo "OK"
exit 0
