# `stackstorm-enterprise-ha` Helm Chart
StackStorm Enterprise K8s Helm Chart, optimized for running StackStorm in HA environment.

To install the chart:
```
helm dependency update

helm install .
```
For advanced configuration you may need to edit the default settings in `values.yaml`.

## st2web
By default, st2web includes a Pod Deployment and a Service for st2web Enterprise Web UI.
Service uses NodePort, so installing this chart will not provision a LoadBalancer or Ingress (TODO!).
Depending on your Kubernetes cluster configuration you may need to add additional configuration to access the example service.
