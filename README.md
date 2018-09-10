# StackStorm K8s Helm Chart Repository index
K8s Helm repository index for `stackstorm-enterprise-ha` chart that codifies StackStorm Enterprise
High Availability fleet as a simple to use reproducible infrastructure-as-code app.

## Usage
```
helm repo add stackstorm https://helm.stackstorm.com/
helm install --set secrets.st2.license=<ST2_LICENSE_KEY> stackstorm/stackstorm-enterprise-ha
```
