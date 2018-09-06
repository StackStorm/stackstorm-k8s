# `stackstorm-enterprise-ha` Helm Chart
StackStorm Enterprise K8s Helm Chart, optimized for running StackStorm in HA environment.

It will install 2 replicas for each component of StackStorm microservices for redundancy, as well as backends like
RabbitMQ HA, MongoDB replicaset and etcd cluster that st2 replies on for MQ, DB and distributed coordination respectively.

It's more than welcome to configure each component in-depth to fit specific availability/scalability demands.

## Requirements
* [Kubernetes](https://kubernetes.io/docs/setup/pick-right-solution/) cluster
* [Helm](https://docs.helm.sh/using_helm/#install-helm) and [Tiller](https://docs.helm.sh/using_helm/#initialize-helm-and-install-tiller)

## Usage
1) Edit `values.yaml` with configuration for the StackStorm Enterprise HA K8s cluster.
> NB! It's highly recommended to set your own secrets as file contains unsafe defaults like self-signed SSL certificates, SSH keys,
> StackStorm access and DB/MQ passwords!

2) Pull 3rd party Helm dependencies:
```
helm dependency update
```

3) Install the chart:
```
helm install --set secrets.st2.license=<ST2_LICENSE_KEY> .
```

4) Upgrade.
Once you make any changes to values, upgrade the cluster:
```
helm upgrade --set secrets.st2.license=<ST2_LICENSE_KEY> <release-name> .
```

## Components
### st2web
By default, st2web includes a Pod Deployment and a Service for st2web Enterprise Web UI.
Service uses NodePort, so installing this chart will not provision a LoadBalancer or Ingress (TODO!).
Depending on your Kubernetes cluster configuration you may need to add additional configuration to access the example service.

## Tips & Tricks
Grab all logs for entire StackStorm cluster with dependent services in Helm release:
```
kubectl logs -l release=<release-name>
```

Grab all logs only for stackstorm backend services, excluding st2web and DB/MQ/etcd:
```
kubectl logs -l release=<release-name>,tier=backend
```
