# `stackstorm-ha` Helm chart Tests

This directory contains Helm chart unit and integration tests (under `tests/unit/` and `tests/integration/` respectively).

## Unit tests

Unit tests (`tests/unit/*_test.yaml`) use [`helm-unittest`](https://github.com/quintush/helm-unittest).
`helm-unittest` uses a yaml-based test file to ensure that the templates generate expected features.
For example, they can ensure that custom annotations are applied consistently to all of the deployments.
Unit tests do not require a running kubernetes cluster.

Before running unit tests, install the `helm-unittest` plugin and ensure you have sub-charts installed:
```
helm plugin install https://github.com/quintush/helm-unittest
helm dependency update
```

To run the tests manually from the chart's root dir:
```
helm unittest --helm3 -f tests/unit/*_test.yaml .
```

> Note! If you need to add unit tests, file names should follow this pattern: `tests/unit/name_your_test.yaml`

See https://github.com/quintush/helm-unittest/blob/master/DOCUMENT.md for details on writing unit tests.

## Integration tests

Integration tests (under `tests/integration/`) use `helm-test` and are powered by [BATS](https://github.com/sstephenson/bats) (Bash Automated Testing System).
As integratin tests, these require a running kubernetes cluster where helm can do test deployments of this chart.

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

See https://helm.sh/docs/topics/chart-tests/ with more information about Helm chart tests.
