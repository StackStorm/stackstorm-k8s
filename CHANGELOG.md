# Changelog

## In Development
* Advanced Feature: Make securityContext (on Deployments/Jobs) and podSecurityContext (on Pods) configurable. This allows dropping all capabilities, for example. You can override the securityContext for `st2actionrunner`, `st2sensorcontainer`, and `st2client` if your actions or sensors need, for example, additional capabilites that the rest of StackStorm does not need. (#271) (by @cognifloyd)
* Prefix template helpers with chart name and format helper comments as template comments. (#272) (by @cognifloyd)
* New feature: Add `extra_volumes` to all python-based st2 deployments. This can facilitate changing log levels by loading logging conf file(s) from a custom ConfigMap. (#276) (by @cognifloyd)
* Initialize basic unittest infrastructure using `helm-unittest`. Added tests for custom annotations. (#284)

## v0.80.0
* Switch st2 to `v3.6` as a new default stable version (#274)
* Explicitly differentiate sensor modes: `all-sensors-in-one-pod` vs `one-sensor-per-pod`. Exposes the mode in new `stackstorm/sensor-mode` annotation. (#222) (by @cognifloyd)
* Allow adding custom env variables to any Deployment or Job. (#120) (by @AngryDeveloper)
* Template the contents of st2.config and the values in st2chatops.env. This allows adding secrets defined elsewhere in values. (#249) (by @cognifloyd)
* Set default/sample RBAC config files to "" (empty string) to prevent adding them. This is needed because they cannot be removed by overriding the roles/mappings values. (#247) (by @cognifloyd)
* Make configuring `stackstorm/sensor-mode=all-sensors-in-one-pod` more obvious by using `st2.packs.sensors` only for `one-sensor-per-pod`. `all-sensors-in-one-pod` mode now only uses values from `st2sensorcontainer`. (#246) (by @cognifloyd)
* Use "--convert" when loading keys into datastore (in key-load Job) so that `st2.keyvalue[].value` can be any basic JSON data type. (#253) (by @cognifloyd)
* New feature: Add `extra_volumes` to `st2actionrunner`, `st2client`, `st2sensorcontainer`. This is useful for loading volumes to be used by actions or sensors. This might include secrets (like ssl certificates) and configuration (like system-wide ansible.cfg). (#254) (by @cognifloyd)
* Some `helm upgrades` do not need to run all the jobs. An upgrade that only touches RBAC config, for example, does not need to run the register-content job. Use `--set 'jobs.skip={apikey_load,key_load,register_content}'` to skip the other jobs. (#255) (by @cognifloyd)
* Refactor deployments/jobs to inject st2 username/password via `envFrom` instead of via `env`. (#257) (by @cognifloyd)
* New feature: Add `envFromSecrets` to `st2actionrunner`, `st2client`, `st2sensorcontainer`, and jobs. This is useful for adding custom secrets to the environment. This complements the `extra_volumes` feature (loading secrets as files) to facilitate loading secrets that are not easily injected via the filesystem. (#259) (by @cognifloyd)
* New feature to include `nodeSelector`, `affinity` and `tolerations` to `st2client`, allowing more flexibility to pod positioning. (#263) (by @sandesvitor)
* Template `~/.st2/config`. This allows customizing the settings used by the `st2client` and jobs pods for using the st2 apis. (#262) (by @cognifloyd)
* Fix indent for lifecycle postStart hook of `st2web` pod. (#268) (by @cognifloyd)
* Advanced Feature: Allow `st2web` to serve HTTPS when the ssl certs are provided via `st2web.extra_volumes`. To enable this, add `ST2WEB_HTTPS: "1"` to `st2web.env` in your values file. (#264) (by @cognifloyd)
* Custom annotations now apply to deployments and jobs, not just pods. (#270) (by @cognifloyd)
* BREAKING CHANGE: Auto-generate `datastore_crypto_key` on install if not provided. This way all HA installs will have a datastore_crypto_key configured. This is only a breaking change for installations that do not want a `datastore_crypto_key`. To disable set `datastore_crypto_key` to `disable` instead of setting it to `""`, `null`, or leaving it unset. (#266) (by @cognifloyd)

## v0.70.0
* New feature: Shared packs volumes `st2.packs.volumes`. Allow using cluster-specific persistent volumes to store packs, virtualenvs, and (optionally) configs. This enables using `st2 pack install`. It even works with `st2packs` images in `st2.packs.images`. (#199) (by @cognifloyd)
* Updated redis constant sentinel ID which will allow other sentinel peers to update to the new given IP in case of pod failure or worker node reboots. (#191) (by @manisha-tanwar)
* Removed reference to st2-license pullSecrets, which was missed when removing enterprise flags (#192) (by @cognifloyd)
* Add optional imagePullSecrets to ServiceAccount using `serviceAccount.pullSecret` from values.yaml. If pods do not have imagePullSecrets (eg without `image.pullSecret` in values.yaml), k8s populates them from the ServiceAccount. (#196 & #239) (by @cognifloyd)
* Reformat some yaml strings so that single quotes wrap strings that include double quotes (#194) (by @cognifloyd)
* st2chatops change: If `st2chatops.env.ST2_API_KEY` is defined, do not set `ST2_AUTH_USERNAME` or `ST2_AUTH_PASSWORD` env vars any more. (#197) (by @cognifloyd)
* Add image.tag overrides for all deployments. (#200) (by @cognifloyd)
* If your k8s cluster admin requires custom annotations (eg: to indicate mongo or rabbitmq usage), you can now add those to each set of pods. (#195) (by @cognifloyd)
* BREAKING CHANGE: Move secrets.st2.* values into st2.* (#203) (by @cognifloyd)
* Auto-generate password and ssh_key secrets. (#203) (by @cognifloyd)
* Add optional hubot-scripts volume to st2chatops pod. To add this, define `st2chatops.hubotScriptsVolume`. (#207) (by @cognifloyd)
* Add advanced pod placment (nodeSelector, affinity, tolerations) to specs for batch Jobs pods. (#193) (by @cognifloyd)
* Allow adding dnsPolicy and/or dnsConfig to all pods. (#201) (by @cognifloyd)
* Move st2-config-vol volume definition and list of st2-config-vol volumeMounts to helpers to reduce duplication (#198) (by @cognifloyd)
* Fix permissions for /home/stanley/.ssh/stanley_rsa using the postStart lifecycle hook (#219) (by @cognifloyd)
* Make system_user configurable when using custom st2actionrunner images that do not provide stanley (#220) (by @cognifloyd)
* Allow providing scripts in values for use in lifecycle postStart hooks of all deployments. (#206) (by @cognifloyd)
* Add preRegisterContentCommand in an initContainer for register-content job to run last-minute content customizations (#213) (by @cognifloyd)
* Fix a bug when datastore cryto keys are not able to read by the rules engine. ``datastore_crypto_key`` volume is now mounted on the ``st2rulesengine`` pods (#223) (by @moti1992)
* Minimize required sensor config by using default values from st2sensorcontainer for each sensor in st2.packs.sensors (#221) (by @cognifloyd)
* Do not template rabbitmq secrets file unless rabbitmq subchart is enabled. (#242) (by @cognifloyd)
* Automatically stringify st2chatop.env values if needed. (#241) (by @cognifloyd)

## v0.60.0
* Switch st2 version to `v3.5dev` as a new latest development version (#187)
* Change st2packs definition to a list, to support multiple st2packs containers (#166) (by @moonrail)
* Enabled RBAC/LDAP configuration for OSS version, removed enterprise flags (#182) (by @hnanchahal)
* Fixed datastore_crypto_key secret name for rules engine (#188) (by @lordpengwin)

## v0.52.0
* Improve resource allocation and scheduling by adding resources requests cpu/memory values for st2 Pods (#179)
* Avoid cluster restart loop situations by making st2 Pod initContainers to wait for DB/MQ connection (#178)
* Add option to define config.js for st2web (#165) (by @moonrail)

## v0.51.0
* Added Redis with Sentinel to replace etcd as a coordination backend (#169)

## v0.50.0
* Drop Helm `v2` support and fully migrate to Helm `v3` (#163)
* Switch dependencies from deprecated `helm/charts` to new Bitnami Subcharts (#163)

## v0.41.0
* Fix Helm 2 repository location to a new working URL https://charts.helm.sh/stable (#164) (by @manisha-tanwar)

## v0.40.0
* Switch st2 version to `v3.4dev` as a new latest development version (#157)
* Disable Enterprise testing in CI (#157)
* Change pullPolicy to "IfNotPresent", as Docker-Hub Ratelimits now (#159) (by @moonrail)
* Update `rabbitmq-ha` 3rd party chart from `1.44.1` to `1.46.1` (#158) (by @moonrail)
* Enable `rabbitmqErlangCookie` for `rabbitmq-ha` by default, to ensure cluster-redeployments do not fail (#158) (by @moonrail)
* Add `forceBoot` for `rabbitmq-ha` by default, to ensure cluster-redeployments do not fail due to unclean exits (#158) (by @moonrail)
* Add option to define pull secret for st2 images (#162) (by @moonrail)

## v0.32.0
* Fix a bug when datastore encrypted keys didn't work in scheduled rules. datastore_crypto_key is now shared with the ``st2scheduler`` pods (#148) (by @rahulshinde26)
* Change NOTES.txt template for using ST2 CLI to include namespace argument in 'kubectl exec' command (#150) (by @rahulshinde26)
* Move the apiVersion `extensions/v1beta1` to `networking.k8s.io/v1beta1` for ingress (#149) (by @jb-abbadie)

## v0.31.0
* Fix chart compatibility with Helm versions >= `2.16.8` by downgrading `mongodb-replicaset` from `3.14.0` to `3.12.0` (#137) (by @AbhyudayaSharma)
* Allow injection of datastore key in cluster (#115) (by @AngryDeveloper)

## v0.30.0
* Pin st2 version to `v3.3dev` as a new latest development version (#129)
* Migrate from `py2` `Ubuntu Xenial` to `py3` `Ubuntu Bionic` as a base StackStorm OS (StackStorm/st2-dockerfiles#16, #129)
* Switch from MongoDB `3.4` to `4.0` for the mongodb-ha Helm chart (#129)
* Update `etcd-operator` 3rd party chart from `0.10.0` to latest `0.10.3` (#129)
* Update `rabbitmq-ha` 3rd party chart from `1.36.4` to `1.44.1` (#129)
* Update `mongodb-replicaset` 3rd party chart from `3.9.6` to `3.14.0` (#129)
* Update CI infrastructure env, run tests on updated Helm `v2.16.7`, latest minikube `v1.10.1` and K8s `1.18` (#129)

## v0.28.0
* Added support for custom image repository (#131) (by @ytjohn)

## v0.27.0
* Added support to toggle etcd-operator as a coordination backend (#127) (by @rrahman-nv)

## v0.26.0
* Added custom annotations to sensorcontainer and actionrunner Pods (#123) (by @stefangusa)
* Improve Helm values recommendations to configure 3rd party chart dependencies `rabbitmq-ha` and `mongodb-ha` in prod (#125) (by @stefangusa)

## v0.25.0
* Change ingress name from `<release name>-ingress` to `<release name>-st2web-ingress`, useful when using `stackstorm-ha` as a requirement for another chart. (#112) (by @erenatas)
* Fix st2web ingress which should have been defined as an Integer instead of a String (#111) (by @erenatas)
* Add an option to inject hostAliases in the st2actionrunner containers (#114)
* Add support for Service Accounts (#117) (by @Vince-Chenal)

## v0.24.0
* Fix st2web ingress to use `/` path by default instead of `/*`, useful for nginx ingress controller (#103) (by @erenatas)
* Add ability of templating on `st2.keyvalue` in Helm Values (#108) (by @erenatas)
* Update Ingress documentation in Helm values (#105) (by @AngryDeveloper)

## v0.23.0
* Add support for latest K8s version `1.16`, update e2e CI
* Fix `StatefulSet` validation failure due to new K8s APIs, update `rabbitmq-ha` 3rd party chart to `v1.36.4` (#85)

## v0.22.0
* Add an option to pull custom st2packs image from private Docker repository (#87)
* Remove local 'docker-registry' dependency for hosting custom packs in-cluster that doesn't fit prod expectations (#88)

## v0.21.0
* Change etcd dependency from incubator/etcd to stable/etcd-operator (#81) (by @trstruth)

## v0.20.0
* Add option to disable MongoDB and RabbitMQ in-cluster deployment and configuration (#79) (by @trstruth)
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
* Mongodb authentication is enabled by default (#63) (by @Lomonosow)

## v0.12.0
* Move `st2web.annotations` to `st2web.service.annotations` to match `values.yaml` (#66)

## v0.11.0
* Add st2chatops support (#55) (by @mosn, @rapittdev)

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
