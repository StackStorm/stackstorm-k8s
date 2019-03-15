# Changelog

## In Development

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
