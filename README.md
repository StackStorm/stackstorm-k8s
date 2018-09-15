# `stackstorm-enterprise-ha` Helm Chart
StackStorm Enterprise K8s Helm Chart for running StackStorm Enterprise cluster in HA mode.

It will install 2 replicas for each component of StackStorm microservices for redundancy, as well as backends like
RabbitMQ HA, MongoDB HA Replicaset and etcd cluster that st2 replies on for MQ, DB and distributed coordination respectively.

It's more than welcome to fine-tune each component settings to fit specific availability/scalability demands.

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

> Don't have StackStorm Enterprise License?<br>
> 90-day free trial can be requested at https://stackstorm.com/#product

4) Upgrade.
Once you make any changes to values, upgrade the cluster:
```
helm upgrade <release-name> .
```

## Components
### st2client
A helper container to switch into and run st2 CLI commands against the deployed StackStorm Enterprise cluster.
All resources like credentials, configs, RBAC, packs, keys and secrets are shared with this container.
```
# obtain st2client pod name
ST2CLIENT=$(kubectl get pod -l app=st2client,support=enterprise -o jsonpath="{.items[0].metadata.name}")

# run a single st2 client command
kubectl exec -it ${ST2CLIENT} -- st2 --version

# switch into a container shell and use st2 CLI
kubectl exec -it ${ST2CLIENT} /bin/bash
```

### [st2web](https://docs.stackstorm.com/latest/reference/ha.html#nginx-and-load-balancing)
st2web is a StackStorm Web UI admin dashboard. By default, st2web K8s config includes a Pod Deployment and a Service.
`2` replicas (configurable) of st2web serve the st2 web app and proxify requests to st2auth, st2api, st2stream.
Service uses NodePort, so installing this chart will not provision a K8s resource of type LoadBalancer or Ingress (TODO!).
Depending on your Kubernetes cluster setup you may need to add additional configuration to access the Web UI service or expose it to public net.

### [st2auth](https://docs.stackstorm.com/reference/ha.html#st2auth) 
All authentication is managed by `st2auth` service.
K8s configuration includes a Pod Deployment backed by `2` replicas by default and Service of type ClusterIP listening on port `9100`.
Multiple st2auth processes can be behind a load balancer in an active-active configuration and you can increase number of replicas per your discretion.

### [st2api](https://docs.stackstorm.com/reference/ha.html#st2api)
Service hosts the REST API endpoints that serve requests from WebUI, CLI, ChatOps and other st2 components.
K8s configuration consists of Pod Deployment with `2` default replicas for HA and ClusterIP Service accepting HTTP requests on port `9101`.
Being one of the most important of StackStorm services with a lot of logic involved,
it's recommended to increase number of replicas to distribute the load if you'd plan increased load demands.

### [st2stream](https://docs.stackstorm.com/reference/ha.html#st2stream)
StackStorm st2stream - exposes a server-sent event stream, used by the clients like WebUI and ChatOps to receive update from the st2stream server.
Similar to st2auth and st2api, st2stream K8s configuration includes Pod Deployment with `2` replicas for HA (can be increased in `values.yaml`)
and ClusterIP Service listening on port `9102`.

### [st2rulesengine](https://docs.stackstorm.com/reference/ha.html#st2rulesengine)
st2rulesengine evaluates rules when it sees new triggers and decides if new action execution should be requested.
K8s config includes Pod Deployment with `2` (configurable) replicas by default for HA.

### [st2timersengine](https://docs.stackstorm.com/reference/ha.html#st2timersengine)
st2timersengine is responsible for scheduling all user specified [timers](https://docs.stackstorm.com/rules.html#timers) aka st2 cron.
Only single replica is created via K8s Deployment as timersengine can't work in active-active mode at the moment
(multiple timers will produce duplicated events) and it relies on K8s failover/reschedule capabilities to address cases of process failure.

### [st2workflowengine](https://docs.stackstorm.com/reference/ha.html#st2workflowengine)
st2workflowengine drives the execution of orquesta workflows and actually schedules actions to run. 
Multiple st2workflowengine processes can run in active-active mode and so `2` K8s Deployment replicas are created.
All the workflow engine processes will share the load and pick up more work if one or more of the processes become available.

### [st2notifier](https://docs.stackstorm.com/reference/ha.html#st2notifier)
Multiple st2notifier processes can run in active-active mode, using connections to RabbitMQ and MongoDB and generating triggers based on
action execution completion as well as doing action rescheduling.
In an HA deployment minimum 2 replicas of st2notifier is running, requiring co-ordination backend, which is `etcd` in this case.

### [st2sensorcontainer](https://docs.stackstorm.com/reference/ha.html#st2sensorcontainer)
st2sensorcontainer manages StackStorm sensors: starts, stops and restarts them as a subprocesses.
At the moment K8s configuration consists of Deployment with hardcoded `1` replica.
Future plans (#12) to re-work this setup and benefit from Docker-friendly [single-sensor-per-container mode](https://github.com/StackStorm/st2/pull/4179)
(since st2 `v2.9`) as a way of [Sensor Partitioning](https://docs.stackstorm.com/latest/reference/sensor_partitioning.html), distributing the computing load
between many pods and relying on K8s failover/reschedule mechanisms, instead of running everything on 1 single instance of st2sensorcontainer.

### [st2actionrunner](https://docs.stackstorm.com/reference/ha.html#st2actionrunner)
Stackstorm workers that actually execute actions.
`5` replicas for K8s Deployment are configured by default to increase the ability of StackStorm to execute actions.
This is the first thing to lift if you have a lot of actions to execute in your StackStorm cluster.

### [st2garbagecollector](https://docs.stackstorm.com/reference/ha.html#st2garbagecollector)
Service that cleans up old executions and other operations data based on setup configurations.
Having `1` st2garbagecollector replica for K8s Deployment is enough, considering its periodic execution nature.
By default this process does nothing and needs to be configured in st2.conf settings (via `values.yaml`).
Purging stale data can significantly improve cluster abilities to perform faster and so it's recommended to configure `st2garbagecollector` in production.

### [MongoDB HA ReplicaSet](https://github.com/helm/charts/tree/master/stable/mongodb-replicaset)
StackStorm uses MongoDB as a database engine. External Helm Chart is used to configure MongoDB HA [ReplicaSet](https://docs.mongodb.com/manual/tutorial/deploy-replica-set/).
By default `3` nodes (1 primary and 2 secondaries) of MongoDB are deployed via K8s StatefulSet.
For more advanced MongoDB configuration, refer to official [mongodb-replicaset](https://github.com/helm/charts/tree/master/stable/mongodb-replicaset)
Helm chart settings, which might be fine-tuned via `values.yaml`.

### [RabbitMQ HA](https://docs.stackstorm.com/latest/reference/ha.html#rabbitmq)
RabbitMQ is a message bus StackStorm relies on for inter-process communication and load distribution.
External Helm Chart is used to deploy [RabbitMQ cluster](https://www.rabbitmq.com/clustering.html) in Highly Available mode.
By default `3` nodes of RabbitMQ are deployed via K8s StatefulSet.
For more advanced RabbitMQ configuration, please refer to official [rabbitmq-ha](https://github.com/helm/charts/tree/master/stable/rabbitmq-ha)
Helm chart repository, - all settings could be overridden via `values.yaml`.

### [etcd](https://docs.stackstorm.com/latest/reference/ha.html#zookeeper-redis)
StackStorm employs `etcd` as a distributed coordination backend, required for StackStorm cluster components to work properly in HA scenario.
Currently, due to low demands, only `1` instance of `etcd` is created via K8s Deployment.
Future plans to rely on official Helm chart and configure etcd/Raft cluster properly with `3` nodes by default (TODO #48).

## Tips & Tricks
Grab all logs for entire StackStorm cluster with dependent services in Helm release:
```
kubectl logs -l release=<release-name>
```

Grab all logs only for stackstorm backend services, excluding st2web and DB/MQ/etcd:
```
kubectl logs -l release=<release-name>,tier=backend
```

# Installing packs in the cluster

In the kubernetes cluster, the `st2 pack install` command will not work. Instead, you need to bake the packs into a custom
docker image, and push it to a private or public docker registry. The image will provide /opt/stackstorm/{packs,virtualenvs}
via a sidecar container in pods which need access to the packs.

If you do not already have an appropriate docker registry, we made it very easy to deploy one in your k8s cluster.
See below for details.

## Install custom packs in the cluster

### Build st2packs image

To build the st2packs image which contains your required packs installed in `/opt/stackstorm/packs` and `/opt/stackstorm/virtualenvs`,
define the `PACKS` build argument using a space separated list of pack names. For example, to install the `email` and `vault`
packs (in addition to the default system packs), run:

Set DOCKER_REGISTRY to the docker registry URL. If using the private docker registry in the k8s cluster, use `localhost:5000`.

```
cd st2packs
docker build --build-arg PACKS="<pack names>" -t ${DOCKER_REGISTRY}/st2packs:latest .
docker push ${DOCKER_REGISTRY}/st2packs:latest
```

Read https://github.com/helm/charts/tree/master/incubator/kube-registry-proxy for more details on how to install this chart.

### Push st2packs image to a docker registry

If you're pushing to a private docker registry in the k8s cluster, you will need to port forward from your local host to the registry. You can use:

```
kubectl port-forward $(kubectl get pod -l app=docker-registry -o jsonpath="{.items[0].metadata.name}") 5000:5000
```

NOTE: If running on MacOS, before deploying the image, open another terminal and execute:

```
docker run --privileged --pid=host socat:latest nsenter -t 1 -u -n -i socat TCP-LISTEN:5000,fork TCP:docker.for.mac.localhost:5000
```

To deploy the image to the registry, execute:

```
docker push ${DOCKER_REGISTRY}/st2packs:latest
```

### How to provide custom pack configs

Update the `pack.configs` section of `stackstorm-enterprise-ha/values.yaml`:

For example:

```
pack
  configs:
    email.yaml: |
      ---
      # example email pack config file

    vault.yaml: |
      ---
      # example vault pack config file
```
