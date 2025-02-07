# Rationale

This policy has been created to cover the following use case.

We have an application within a pipeline that creates ```Namespaces``` for tenants. Each time a request is received to create a ```Namespace``` the application creates 3 kubernetes resources by default.
- The ```Namespace``` itself whose name has to be prefixed with ```tnt-```
- A ```Secret``` called ```secret-dockercfg``` of type ```kubernetes.io/dockercfg``` 
- A ```NetworkPolicy``` called ```default-deny-all```.

# RBAC

In terms of RBAC, excessive permissions have to be granted to the service account to perform the specified tasks. We should create the following ClusterRoles and their respective ClusterRolesBindings to bind them to the service account.

```yaml
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: create-tnt-ns-clusterrole-namespaces-secrets
rules:
- apiGroups: [""]
  resources: ["namespaces", "secrets"]
  verbs: ["create", "get", "list"]
```

```yaml
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: create-tnt-ns-clusterrole-netpols
rules:
- apiGroups: ["networking.k8s.io"]
  resources: ["networkpolicies"]
  verbs: ["create", "get", "list"]
```

Taking a look at the verbs, we can see that the permissions are extremely  permissive. Therefore this policy is created to ensure that the service account only performs the tasks it has to perform.


# What does the policy do?

- Check that the user creating the resources is the ```create-tnt-ns``` service account
- Check that the name of the namespace starts with the prefix ```tnt-```
- Check that the name of the secret is ```secret-dockercfg``` and is of type ```kubernetes.io/dockercfg```
- Check that the name of the Networkpolicy is ```default-deny-all```

If all conditions are met, the creation of the resources is allowed.

# Policy deployment using helm

Before you can define a constraint, you must first define a ```ConstraintTemplate```, which describes both the Rego that enforces the constraint and the schema of the constraint.

Because of this dependence, two helm charts have been created. One for ```templates``` and one for ```constraints``` You must first install the templates and then the constraints.

```bash
$ cd helm-charts
$ helm upgrade --install opa-templates -n opa-policies --create-namespace opa-templates/
$ helm upgrade --install opa-constraints -n opa-policies opa-constraints/
```

# Testing the policy using helm

```bash
$ helm test opa-constraints -n opa-policies
```

# Testing the policy manually using minikube

## Install minikube

[minikube start](https://minikube.sigs.k8s.io/docs/start/?arch=%2Flinux%2Fx86-64%2Fstable%2Fbinary+download)

## Create kubernetes user

```bash
$ mkdir $HOME/certs && cd $HOME/certs
$ openssl genrsa -out create-tnt-ns.key 2048
$ openssl req -new -key create-tnt-ns.key -out create-tnt-ns-csr.pem -subj "/CN=create-tnt-ns/O=devops-team/"
$ openssl x509 -req -in create-tnt-ns-csr.pem -CA $HOME/.minikube/ca.crt -CAkey $HOME/.minikube/ca.key -CAcreateserial -out create-tnt-ns.crt -days 10000
 ```

## Create kubectl config context

```bash
kubectl config set-credentials create-tnt-ns --client-certificate=$HOME/certs/create-tnt-ns.crt --client-key=$HOME/certs/create-tnt-ns.key
kubectl config set-context create-tnt-ns --cluster=minikube --user create-tnt-ns
```

## Create RBAC Resources

```bash
$ kubectl config use-context minikube
$ cd code/rbac
$ kubectl apply -f rbac-create-tnt-ns.yaml
```

## Run the integration tests scripts

Run the bash scripts in the [create-tnt-ns](../../../../../../code/scripts/create-tnt-ns/) folder to test the policy.

```bash
$ cd code/scripts/create-tnt-ns
$ ls -1
01-tenant-namespace-wrong-name.sh
02-tenant-secret-wrong-name.sh
03-tenant-secret-wrong-type.sh
04-tenant-netpol-wrong-name.sh
05-tenant-tasks-ok.sh
```