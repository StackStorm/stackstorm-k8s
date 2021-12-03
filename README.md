# `stackstorm-ha` Helm Chart
[![Build Status](https://circleci.com/gh/StackStorm/stackstorm-ha/tree/master.svg?style=shield)](https://circleci.com/gh/StackStorm/stackstorm-ha)
[![Artifact HUB](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/stackstorm-ha)](https://artifacthub.io/packages/helm/stackstorm/stackstorm-ha)

K8s Helm Chart for running StackStorm cluster in HA mode.

It will install 2 replicas for each component of StackStorm microservices for redundancy, as well as backends like
RabbitMQ HA, MongoDB HA Replicaset and Redis cluster that st2 replies on for MQ, DB and distributed coordination respectively.

It's more than welcome to fine-tune each component settings to fit specific availability/scalability demands.

## Requirements
* [Kubernetes](https://kubernetes.io/docs/setup/pick-right-solution/) cluster
* [Helm](https://docs.helm.sh/using_helm/#install-helm) `v3.5` or greater

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

## Configuration

The default configuration values for this chart are described in `values.yaml`.

## Ingress

Ingress is worth considering if you want to expose multiple services under the same IP address, and
these services all use the same L7 protocol (typically HTTP). You only pay for one load balancer if
you are using native cloud integration, and because Ingress is "smart", you can get a lot of
features out of the box (like SSL, Auth, Routing, etc.). See the ingress section in `values.yaml`
for configuration details.

You will first need to deploy an ingress controller of your preference. See
https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/#additional-controllers
for more information.

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
By default, st2web uses HTTP instead of HTTPS. We recommend you rely on `LoadBalancer` or `Ingress` to add HTTPS layer on top of it.
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
`st2scheduler` is responsible for handling ingress action execution requests.
`2` replicas for K8s Deployment are configured by default to increase StackStorm scheduling throughput.

### [st2notifier](https://docs.stackstorm.com/reference/ha.html#st2notifier)
Multiple st2notifier processes can run in active-active mode, using connections to RabbitMQ and MongoDB and generating triggers based on
action execution completion as well as doing action rescheduling.
In an HA deployment there must be a minimum of `2` replicas of st2notifier running, requiring a coordination backend,
which in our case is `Redis`.

### [st2sensorcontainer](https://docs.stackstorm.com/reference/ha.html#st2sensorcontainer)
st2sensorcontainer manages StackStorm sensors: It starts, stops and restarts them as subprocesses.
By default, deployment is configured with `1` replica containing all the sensors.

st2sensorcontainer also supports a more Docker-friendly single-sensor-per-container mode as a way of
[Sensor Partitioning](https://docs.stackstorm.com/latest/reference/sensor_partitioning.html). This
distributes the computing load between many pods and relies on K8s failover/reschedule mechanisms,
instead of running everything on a single instance of st2sensorcontainer. The sensor(s) must be
deployed as part of the custom packs image.

As an example, override the default Helm values as follows:

```
st2:
  packs:
    sensors:
      - name: github
        ref: githubwebhook.GitHubWebhookSensor
      - name: circleci
        ref: circle_ci.CircleCIWebhookSensor
```

### [st2actionrunner](https://docs.stackstorm.com/reference/ha.html#st2actionrunner)
Stackstorm workers that actually execute actions.
`5` replicas for K8s Deployment are configured by default to increase StackStorm ability to execute actions without excessive queuing.
Relies on `redis` for coordination. This is likely the first thing to lift if you have a lot of actions
to execute per time period in your StackStorm cluster.

### [st2garbagecollector](https://docs.stackstorm.com/reference/ha.html#st2garbagecollector)
Service that cleans up old executions and other operations data based on setup configurations.
Having `1` st2garbagecollector replica for K8s Deployment is enough, considering its periodic execution nature.
By default this process does nothing and needs to be configured in st2.conf settings (via `values.yaml`).
Purging stale data can significantly improve cluster abilities to perform faster and so it's recommended to configure st2garbagecollector in production.

### [st2chatops](https://docs.stackstorm.com/chatops/index.html)
StackStorm ChatOps service, based on hubot engine, custom stackstorm integration module and preinstalled list of chat adapters.
Due to Hubot limitation, st2chatops doesn't provide mechanisms to guarantee high availability and so only single `1` node of st2chatops is deployed.
This service is disabled by default. Please refer to Helm `values.yaml` about how to enable and configure st2chatops with ENV vars for your preferred chat service.

### [MongoDB ReplicaSet](https://github.com/bitnami/charts/tree/master/bitnami/mongodb)
StackStorm works with MongoDB as a database engine. External Helm Chart is used to configure MongoDB [ReplicaSet](https://docs.mongodb.com/manual/tutorial/deploy-replica-set/).
By default `3` nodes (1 primary and 2 secondaries) of MongoDB are deployed via K8s StatefulSet.
For more advanced MongoDB configuration, refer to bitnami [mongodb](https://github.com/bitnami/charts/tree/master/bitnami/mongodb)
Helm chart settings, which might be fine-tuned via `values.yaml`.

The deployment of MongoDB to the k8s cluster can be disabled by setting the mongodb-ha.enabled key in values.yaml to false.  *Note: Stackstorm relies heavily on connections to a MongoDB instance.  If the in-cluster deployment of MongoDB is disabled, a connection to an external instance of MongoDB must be configured.  The st2.config key in values.yaml provides a way to configure stackstorm.  See [Configure MongoDB](https://docs.stackstorm.com/install/config/config.html#configure-mongodb) for configuration details.*

### [RabbitMQ HA Cluster](https://docs.stackstorm.com/latest/reference/ha.html#rabbitmq)
RabbitMQ is a message bus StackStorm relies on for inter-process communication and load distribution.
External Helm Chart is used to deploy [RabbitMQ cluster](https://www.rabbitmq.com/clustering.html) in Highly Available mode.
By default `3` nodes of RabbitMQ are deployed via K8s StatefulSet.
For more advanced RabbitMQ configuration, please refer to bitnami [rabbitmq](https://github.com/bitnami/charts/tree/master/bitnami/rabbitmq)
Helm chart repository, - all settings could be overridden via `values.yaml`.

The deployment of RabbitMQ to the k8s cluster can be disabled by setting the rabbitmq-ha.enabled key in values.yaml to false.  *Note: Stackstorm relies heavily on connections to a RabbitMQ instance.  If the in-cluster deployment of RabbitMQ is disabled, a connection to an external instance of RabbitMQ must be configured.  The st2.config key in values.yaml provides a way to configure stackstorm.  See [Configure RabbitMQ](https://docs.stackstorm.com/install/config/config.html#configure-rabbitmq) for configuration details.*

### [redis](https://docs.stackstorm.com/latest/reference/ha.html#zookeeper-redis)
StackStorm employs redis sentinel as a distributed coordination backend, required for st2 cluster components to work properly in HA scenario.
`3` node Redis cluster with Sentinel enabled is deployed via external bitnami Helm chart dependency [redis](https://github.com/bitnami/charts/tree/master/bitnami/redis).
As any other Helm dependency, it's possible to further configure it for specific scaling needs via `values.yaml`.

## Install custom st2 packs in the cluster
There are two ways to install st2 packs in the k8s cluster.

1. The `st2packs` method is the default. This method will work for practically all clusters, but `st2 pack install` does not work. The packs are injected via `st2packs` images instead.

2. The other method defines shared/writable `volumes`. This method allows `st2 pack install` to work, but requires a persistent storage backend to be available in the cluster. This chart will not configure a storage backend for you.

NOTE: In general, we recommend using only one of these methods. See the NOTE under Method 2 below about how both methods can be used together with care.

### Method 1: st2packs images (the default)
The `st2packs` method is the default. `st2 pack install` does not work because this chart (by default) uses read-only `emptyDir` volumes for `/opt/stackstorm/{packs,virtualenvs}`.
Instead, you need to bake the packs into a custom docker image, push it to a private or public docker registry and reference that image in Helm values.
Helm chart will take it from there, sharing `/opt/stackstorm/{packs,virtualenvs}` via a sidecar container in pods which require access to the packs
(the sidecar is the only place where the volumes are writable).

#### Building st2packs image
For your convenience, we created a new `st2-pack-install <pack1> <pack2> <pack3>` utility and included it in a container that will help to install custom packs during the Docker build process without relying on live DB and MQ connection.
Please see https://github.com/StackStorm/st2packs-dockerfiles/ for instructions on how to build your custom `st2packs` image.

#### How to provide custom pack configs
Update the `st2.packs.configs` section of Helm values:

For example:
```
  configs:
    email.yaml: |
      ---
      # example email pack config file

    vault.yaml: |
      ---
      # example vault pack config file
```
Don't forget running Helm upgrade to apply new changes.

NOTE: On `helm upgrade` any configs in `st2.packs.configs` will overwrite the contents of `st2.packs.volumes.configs` (optional part of Method 2, described below).

#### Pull st2packs from a private Docker registry
If you need to pull your custom packs Docker image from a private repository, create a Kubernetes Docker registry secret and pass it to Helm values.
See [K8s documentation](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) for more info.
```
# Create a Docker registry secret called 'st2packs-auth'
kubectl create secret docker-registry st2packs-auth --docker-server=<your-registry-server> --docker-username=<your-name> --docker-password=<your-password>
```
Once secret created, reference its name in helm value: `st2.packs.images[].pullSecret`.

### Method 2: Shared Volumes
This method requires cluster-specific storage setup and configuration. As the storage volumes are both writable and shared, `st2 pack install` should work like it does for standalone StackStorm installations. The volumes get mounted at `/opt/stackstorm/{packs,virtualenvs}` in the containers that need read or write access to those directories. With this method, `/opt/stackstorm/configs` can also be mounted as a writable volume (in which case the contents of `st2.packs.configs` takes precedence on `helm upgrade`).

NOTE: With care, `st2packs` images can be used with `volumes`. Just make sure to keep the `st2packs` images up-to-date with any changes made via `st2 pack install`.
If a pack is installed via an `st2packs` image and then it gets updated with `st2 pack install`, a subsequent `helm upgrade` will revert back to the version in the `st2packs` image.

#### Configure the storage volumes
Enable the `st2.packs.voluems` section of Helm values and add volume definitions for both `packs` and `virtualenvs`.
Each of the volume definitions should be customized for your cluster and storage solution.

For example, to use persistentVolumeClaims:
```
  volumes:
    enabled: true
    packs:
      persistentVolumeClaim:
        claim-name: pvc-st2-packs
    virtualenvs:
      persistentVolumeClaim:
        claim-name: pvc-st2-virtualenvs
```

Or, for example, to use NFS:
```
  volumes:
    enabled: true
    packs:
      nfs:
        server: nfs.example.com
        path: /var/nfsshare/packs
    virtualenvs:
      nfs:
        server: nfs.example.com
        path: /var/nfsshare/virtualenvs
```

Please consult the documentation for your cluster's storage solution to see how to add the storage backend to your cluster and how to define volumes that use your storage backend.

#### How to provide custom pack configs
You may either use the `st2.packs.configs` section of Helm values (like Method 1, see above),
or add another shared writable volume similar to `packs` and `virtualenvs`. This volume gets mounted
to `/opt/stackstorm/configs` instead of the `st2.packs.config` values.

NOTE: If you define a configs volume and specify `st2.packs.configs`, anything in `st2.packs.configs` takes precdence during `helm upgrade`, overwriting config files already in the volume.

For example, to use persistentVolumeClaims:
```
  volumes:
    enabled: true
    ... # define packs and virtualenvs volumes as shown above
    configs:
      persistentVolumeClaim:
        claim-name: pvc-st2-pack-configs
```

Or, for example, to use NFS:
```
  volumes:
    enabled: true
    ... # define packs and virtualenvs volumes as shown above
    configs:
      nfs:
        server: nfs.example.com
        path: /var/nfsshare/configs
```

#### Caveat: Mounting and copying packs
If you use something like NFS where you can mount the shares outside of the StackStorm pods, there are a couple of things to keep in mind.

Though you could manually copy packs into the `packs` shared volume, be aware that StackStorm does not automatically register any changed content.
So, if you manually copy a pack into the `packs` shared volume, then you also need to trigger updating the virtualenv and registering the content,
possibly using APIs like:
[packs/install](https://api.stackstorm.com/api/v1/packs/#/packs_controller.install.post), and
[packs/register](https://api.stackstorm.com/api/v1/packs/#/packs_controller.register.post)
You will have to repeat the process each time the packs code is modified.

#### Caveat: System packs
After Helm installs, upgrades, or rolls back a StackStorm install, it runs an `st2-register-content` batch job.
This job will copy and register system packs. If you have made any changes (like disabling default aliases), those changes will be overwritten.

NOTE: Upgrades will not remove files (such as a renamed or removed action) if they were removed in newer StackStorm versions.
This mirrors the how pack registration works. Make sure to review any upgrade notes and manually handle any removals.

## Tips & Tricks
Grab all logs for entire StackStorm cluster with dependent services in Helm release:
```
kubectl logs -l release=<release-name>
```

Grab all logs only for stackstorm backend services, excluding st2web and DB/MQ/redis:
```
kubectl logs -l release=<release-name>,tier=backend
```

## Extending this chart
If you have any suggestions or ideas about how to extend this chart functionality,
we welcome you to collaborate in [Issues](https://github.com/stackstorm/stackstorm-ha/issues)
and contribute via [Pull Requests](https://github.com/stackstorm/stackstorm-ha/pulls).
However if you need something very custom and specific to your infra that doesn't fit official chart plans,
we strongly recommend you to create a parent Helm chart with custom K8s objects and referencing `stackstorm-ha` chart
as a child dependency.
This approach allows not only extending sub-chart with custom objects and templates within the same deployment,
but also adds flexibility to include many sub-chart dependencies and pin versions as well as include all the sub-chart values in one single place.
This approach is infra-as-code friendly and more reproducible. See official Helm documentation about
[Subcharts](https://helm.sh/docs/chart_template_guide/#subcharts-and-global-values) and [Dependencies](https://helm.sh/docs/developing_charts/#managing-dependencies-manually-via-the-charts-directory).
