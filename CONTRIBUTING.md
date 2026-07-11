# Contributing Guidelines

Contributions are welcome via GitHub pull requests.

## How to Contribute

1. Fork this repository, develop, and test your changes
2. Submit a pull request

### Technical Requirements

* Must follow [Helm best practices](https://helm.sh/docs/topics/chart_best_practices/)
* Must pass CI jobs for linting and installing changed charts with [chart-testing](https://github.com/helm/chart-testing)
* Chart version must be bumped in `Chart.yaml` for any chart changes

### Testing Locally

```shell
# Lint
helm lint charts/rootly-edge-connector

# Template
helm template test charts/rootly-edge-connector --set rootly.apiKey=rec_test123 --set 'actionsYaml=on: {}'

# Run chart-testing
ct lint --config ct.yaml
```
