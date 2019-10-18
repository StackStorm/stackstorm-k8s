# Changelog

## In Development

## v0.22.0
* Add an option to pull custom st2packs image from private Docker repository (#87)
* Remove local 'docker-registry' dependency for hosting custom packs in-cluster that doesn't fit prod expectations (#89)

## v0.21.0
* Change etcd dependency from incubator/etcd to stable/etcd-operator (#81)

## v0.20.0
* Add option to disable MongoDB and RabbitMQ in-cluster deployment and configuration (#79)
* Compose multi-node connection string for MongoDB cluster instead of using loadbalancer single host (#80)

## v0.19.0
* Configure RabbitMQ Queue mirroring by default, see https://www.rabbitmq.com/ha.html (#78)

## v0.18.0
* Pin st2 to `v3.2dev` as a new latest development version (#77)

## v0.17.0
* Add chart e2e `helm test` with BATS. Run CI checks with minikube and CircleCI on every PR/push and nightly.

## v0.16.0
* st2web now uses HTTP by default (#72). We now recommend you rely on `LoadBalancer` or `Ingress` to add HTTPS layer on top of it.

## v0.15.0
* Add support for ingress (#68)

## v0.14.0
* Pin st2 version to `v3.1dev` as a new latest development version (#67)

## v0.13.0
* Mongodb authentication is enabled by default (#63)

## v0.12.0
* Move `st2web.annotations` to `st2web.service.annotations` to match `values.yaml` (#66)

## v0.11.0
* Add st2chatops support (@mosn, @rapittdev) (#55)

## v0.10.0
* Bump versions of all dependencies (#50)
* Allow st2sensorcontainer to be partitioned (#51)
* Replace single-node `etcd` coordination backend with 3-node etcd HA cluster, deployed as a Helm dependency (#52)
* Fixed improper job load order for enterprise edition failing due to missing RBAC roles & assignments (#53)

## v0.9.0
* Add new Helm value setting `st2.apikeys` to allow importing predefined ST2 API keys (#36)

## v0.8.4
* Pin st2 version to `v3.0dev` as a new latest development version (#41)

## v0.8.3
* Switch st2 version from `v3.0dev` to `v2.10dev` due to new release plans (#40)

## v0.8.2
* Fix LoadBalancer templating to utilize correct service endpoints in NOTES (#39)

## v0.8.1
* Ensure st2sensorcontainer is re-deployed on `st2.packs.configs` change (#37)

## v0.8.0
* Add ability to specify service type for st2web (#35)

## v0.7.1
* Fix st2web re-deployment is not triggered when updating SSL cert (#33)

## v0.7.0
* Add new Helm `st2.keyvalue` to import data into st2 K/V storage  (#30)
* Include new st2 component `st2scheduler`, introduced in st2 `v2.10` (#32)

## v0.6.0
* Add StackStorm FOSS (community version), make Enterprise install optional (#22)
* Rename chart `stackstorm-enterprise-ha` -> `stackstorm-ha` (#26)

## v0.5.1
*  Move some of the defaults into original st2.conf

## v0.5.0
* Add st2packs, - a way to use custom st2 packs as a shareable Docker image via sidecar containers

## v0.4.0
* Initial public version, referencing StackStorm Enterprise HA as a Helm chart
