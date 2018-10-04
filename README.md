# StackStorm K8s Helm Chart Repository index
K8s Helm repository index for `stackstorm-ha` chart that codifies StackStorm
High Availability fleet as a simple to use reproducible infrastructure-as-code app.

Source code, issues, feature requests: [github.com/StackStorm/stackstorm-ha](https://github.com/StackStorm/stackstorm-ha)

## Usage
```
helm repo add stackstorm https://helm.stackstorm.com/
helm install stackstorm/stackstorm-ha
```

### Enterprise (Optional)
```
helm install \
  --set enterprise.enabled=true \
  --set enterprise.license=<ST2_LICENSE_KEY> \
  stackstorm/stackstorm-ha
```

> Don't have StackStorm Enterprise License?<br>
> 90-day free trial can be requested at [stackstorm.com/#product](https://stackstorm.com/#product)
