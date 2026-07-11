# Rootly Helm Charts

Official Helm charts for Rootly products.

## Charts

- [Rootly Edge Connector](charts/rootly-edge-connector/) — Execute custom actions in response to Rootly alerts and incidents

## Usage

### Using GitHub Pages repository

```shell
helm repo add rootly https://rootlyhq.github.io/helm-charts
helm repo update
```

Install a chart:

```shell
helm install rootly-edge-connector rootly/rootly-edge-connector \
  --set rootly.apiKey=rec_your_api_key \
  --set-file actionsYaml=actions.yml
```

### Using OCI registry

```shell
helm install rootly-edge-connector oci://ghcr.io/rootlyhq/helm-charts/rootly-edge-connector \
  --version 0.1.0 \
  --set rootly.apiKey=rec_your_api_key \
  --set-file actionsYaml=actions.yml
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

[Apache 2.0](LICENSE)
