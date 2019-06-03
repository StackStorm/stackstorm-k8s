# `stackstorm-ha` Helm chart Tests

This directory contains Helm chart tests, powered by [BATS](https://github.com/sstephenson/bats) Bash Automated Testing System.
Despite the minimum amount of smoke tests written, they ensure that StackStorm was really deployed,
works correctly at its core and alive end-to-end without checking deeply specific functionality or configuration.
If something is terribly wrong, - it'll show up via failed tests.

> Note! As part of the automated CI system, tests are performed on every PR via CircleCI.
> To identify any possible regressions related to upstream Dockerfiles used in chart, nightly CI task was also configured that'll trigger e2e periodically.

To run the tests manually:
```
helm test <release-name>
```

To show the test results:
```
kubectl logs <release-name>-st2tests
```

See https://helm.sh/docs/developing_charts/#chart-tests with more information about Helm chart tests.
