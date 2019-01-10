# `stackstorm-ha` Helm Chart
[![Build Status](https://circleci.com/gh/StackStorm/stackstorm-ha/tree/master.svg?style=shield)](https://circleci.com/gh/StackStorm/stackstorm-ha)

K8s Helm Chart for running StackStorm cluster in HA mode.

It will install 2 replicas for each component of StackStorm microservices for redundancy, as well as backends like
RabbitMQ HA, MongoDB HA Replicaset and etcd cluster that st2 replies on for MQ, DB and distributed coordination respectively.

It's more than welcome to fine-tune each component settings to fit specific availability/scalability demands.

## Requirements
* [Kubernetes](https://kubernetes.io/docs/setup/pick-right-solution/) cluster
* [Helm](https://docs.helm.sh/using_helm/#install-helm) and [Tiller](https://docs.helm.sh/using_helm/#initialize-helm-and-install-tiller)

## Usage
1) Edit `values.yaml` with configuration for the StackStorm HA K8s cluster.
> NB! It's highly recommended to set your own secrets as file contains unsafe defaults like self-signed SSL certificates, SSH keys,
> StackStorm access and DB/MQ passwords!

2) Pull 3rd party Helm dependencies:
```
helm dependency update
```

3) Install the chart
```
helm install .
```

4) Upgrade
Once you make any changes to values, upgrade the cluster:
```
helm upgrade <release-name> .
```

### Enterprise (Optional)
By default, StackStorm Community FOSS version is configured via Helm chart. If you want to install [StackStorm Enterprise (EWC)](https://docs.stackstorm.com/install/ewc_ha.html), run:
```
helm install --set enterprise.enabled=true --set enterprise.license=<ST2_LICENSE_KEY> .
```
It will pull enterprise images from private Docker registry as well as allows configuring features like RBAC and LDAP.
See Helm `values.yaml`, `enterprise` section for configuration examples.

> Don't have StackStorm Enterprise License?<br>
> 90-day free trial can be requested at https://stackstorm.com/#product

## Components

The Community FOSS Dockerfiles used to generate the docker images for each st2 component are available at
[st2-dockerfiles](https://github.com/stackstorm/st2-dockerfiles).

### st2client
A helper container to switch into and run st2 CLI commands against the deployed StackStorm cluster.
All resources like credentials, configs, RBAC, packs, keys and secrets are shared with this container.
```
# obtain st2client pod name
ST2CLIENT=$(kubectl get pod -l app=st2client -o jsonpath="{.items[0].metadata.name}")

# run a single st2 client command
kubectl exec -it ${ST2CLIENT} -- st2 --version

# switch into a container shell and use st2 CLI
kubectl exec -it ${ST2CLIENT} /bin/bash
```

### [st2web](https://docs.stackstorm.com/latest/reference/ha.html#nginx-and-load-balancing)
st2web is a StackStorm Web UI admin dashboard. By default, st2web K8s config includes a Pod Deployment and a Service.
`2` replicas (configurable) of st2web serve the web app and proxy requests to st2auth, st2api, st2stream.
> **Note!** By default, st2web is a NodePort Service and is not exposed to the public net.
  If your Kubernetes cluster setup supports the LoadBalancer service type, you can edit the corresponding helm values to configure st2web as a LoadBalancer service in order to expose it and the services it proxies to the public net.

### [st2auth](https://docs.stackstorm.com/reference/ha.html#st2auth)
All authentication is managed by `st2auth` service.
K8s configuration includes a Pod Deployment backed by `2` replicas by default and Service of type ClusterIP listening on port `9100`.
Multiple st2auth processes can be behind a load balancer in an active-active configuration and you can increase number of replicas per your discretion.

### [st2api](https://docs.stackstorm.com/reference/ha.html#st2api)
Service hosts the REST API endpoints that serve requests from WebUI, CLI, ChatOps and other st2 components.
K8s configuration consists of Pod Deployment with `2` default replicas for HA and ClusterIP Service accepting HTTP requests on port `9101`.
Being one of the most important StackStorm services with a lot of logic involved,
we recommend you increase the number of replicas if you expect increased load.

### [st2stream](https://docs.stackstorm.com/reference/ha.html#st2stream)
StackStorm st2stream - exposes a server-sent event stream, used by the clients like WebUI and ChatOps to receive updates from the st2stream server.
Similar to st2auth and st2api, st2stream K8s configuration includes Pod Deployment with `2` replicas for HA (can be increased in `values.yaml`)
and ClusterIP Service listening on port `9102`.

### [st2rulesengine](https://docs.stackstorm.com/reference/ha.html#st2rulesengine)
st2rulesengine evaluates rules when it sees new triggers and decides if new action execution should be requested.
K8s config includes Pod Deployment with `2` (configurable) replicas by default for HA.

### [st2timersengine](https://docs.stackstorm.com/reference/ha.html#st2timersengine)
st2timersengine is responsible for scheduling all user specified [timers](https://docs.stackstorm.com/rules.html#timers) aka st2 cron.
Only a single replica is created via K8s Deployment as timersengine can't work in active-active mode at the moment
(multiple timers will produce duplicated events) and it relies on K8s failover/reschedule capabilities to address cases of process failure.

### [st2workflowengine](https://docs.stackstorm.com/reference/ha.html#st2workflowengine)
st2workflowengine drives the execution of orquesta workflows and actually schedules actions to run by another component `st2actionrunner`.
Multiple st2workflowengine processes can run in active-active mode and so minimum `2` K8s Deployment replicas are created by default.
All the workflow engine processes will share the load and pick up more work if one or more of the processes become available.
> **Note!**
> As Mistral is going to be deprecated and removed from StackStorm platform soon, Helm chart relies only on
>  [Orquesta st2workflowengine](https://docs.stackstorm.com/orchestra/index.html) as a new native workflow engine.

### [st2scheduler](https://docs.stackstorm.com/reference/ha.html#st2scheduler)
TODO: Description TBD

### [st2notifier](https://docs.stackstorm.com/reference/ha.html#st2notifier)
Multiple st2notifier processes can run in active-active mode, using connections to RabbitMQ and MongoDB and generating triggers based on
action execution completion as well as doing action rescheduling.
In an HA deployment there must be a minimum of `2` replicas of st2notifier running, requiring a coordination backend,
which in our case is `etcd`.

### [st2sensorcontainer](https://docs.stackstorm.com/reference/ha.html#st2sensorcontainer)
st2sensorcontainer manages StackStorm sensors: starts, stops and restarts them as a subprocesses.
At the moment K8s configuration consists of Deployment with hardcoded `1` replica.
Future plans are to re-work this setup and benefit from Docker-friendly [single-sensor-per-container mode #4179](https://github.com/StackStorm/st2/pull/4179)
(since st2 `v2.9`) as a way of [Sensor Partitioning](https://docs.stackstorm.com/latest/reference/sensor_partitioning.html), distributing the computing load
between many pods and relying on K8s failover/reschedule mechanisms, instead of running everything on `1` single instance of st2sensorcontainer.

### [st2actionrunner](https://docs.stackstorm.com/reference/ha.html#st2actionrunner)
Stackstorm workers that actually execute actions.
`5` replicas for K8s Deployment are configured by default to increase StackStorm ability to execute actions without excessive queuing.
Relies on `etcd` for coordination. This is likely the first thing to lift if you have a lot of actions
to execute per time period in your StackStorm cluster.

### [st2garbagecollector](https://docs.stackstorm.com/reference/ha.html#st2garbagecollector)
Service that cleans up old executions and other operations data based on setup configurations.
Having `1` st2garbagecollector replica for K8s Deployment is enough, considering its periodic execution nature.
By default this process does nothing and needs to be configured in st2.conf settings (via `values.yaml`).
Purging stale data can significantly improve cluster abilities to perform faster and so it's recommended to configure st2garbagecollector in production.

### [MongoDB HA ReplicaSet](https://github.com/helm/charts/tree/master/stable/mongodb-replicaset)
StackStorm works with MongoDB as a database engine. External Helm Chart is used to configure MongoDB HA [ReplicaSet](https://docs.mongodb.com/manual/tutorial/deploy-replica-set/).
By default `3` nodes (1 primary and 2 secondaries) of MongoDB are deployed via K8s StatefulSet.
For more advanced MongoDB configuration, refer to official [mongodb-replicaset](https://github.com/helm/charts/tree/master/stable/mongodb-replicaset)
Helm chart settings, which might be fine-tuned via `values.yaml`.

### [RabbitMQ HA Cluster](https://docs.stackstorm.com/latest/reference/ha.html#rabbitmq)
RabbitMQ is a message bus StackStorm relies on for inter-process communication and load distribution.
External Helm Chart is used to deploy [RabbitMQ cluster](https://www.rabbitmq.com/clustering.html) in Highly Available mode.
By default `3` nodes of RabbitMQ are deployed via K8s StatefulSet.
For more advanced RabbitMQ configuration, please refer to official [rabbitmq-ha](https://github.com/helm/charts/tree/master/stable/rabbitmq-ha)
Helm chart repository, - all settings could be overridden via `values.yaml`.

### [etcd](https://docs.stackstorm.com/latest/reference/ha.html#zookeeper-redis)
StackStorm employs etcd as a distributed coordination backend, required for StackStorm cluster components to work properly in HA scenario.
Currently, due to low demands, only `1` instance of etcd is created via K8s Deployment.
Future plans to switch to official Helm chart and configure etcd/Raft cluster properly with `3` nodes by default (TODO).

### Docker registry
If you do not already have an appropriate docker registry for storing custom st2 packs images, we made it
very easy to deploy one in your k8s cluster. You can optionally enable in-cluster Docker registry via
`values.yaml` by setting `docker-registry.enabled: true` and additional 3rd party charts [docker-registry](https://github.com/helm/charts/tree/master/stable/docker-registry)
and [kube-registry-proxy](https://github.com/helm/charts/tree/master/incubator/kube-registry-proxy) will be configured.

## Install custom st2 packs in the cluster
In the kubernetes cluster, the `st2 pack install` command will not work. Instead, you need to bake the packs into a custom
docker image, and push it to a private or public docker registry. The image will provide `/opt/stackstorm/{packs,virtualenvs}`
via a sidecar container in pods which need access to the packs.

If you do not already have an appropriate docker registry, we made it very easy to deploy one in your k8s cluster.
See below for details.

### Build st2packs image
To build the st2packs image which contains your required packs installed in `/opt/stackstorm/packs` and
`/opt/stackstorm/virtualenvs`, define the `PACKS` build argument using a space separated list of pack names.
Set DOCKER_REGISTRY to the docker registry URL. If using the private docker registry in the k8s cluster,
set `DOCKER_REGISTRY`to `localhost:5000`.

Please see https://hub.docker.com/r/stackstorm/st2packs/ for details on how to build your custom `st2packs` image.

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
Update the `pack.configs` section of `stackstorm-ha/values.yaml`:

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
Don't forget running Helm upgrade to apply new changes.


## Tips & Tricks
Grab all logs for entire StackStorm cluster with dependent services in Helm release:
```
kubectl logs -l release=<release-name>
```

Grab all logs only for stackstorm backend services, excluding st2web and DB/MQ/etcd:
```
kubectl logs -l release=<release-name>,tier=backend
```
