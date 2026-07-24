# Rootly Helm Charts

Official Helm charts for Rootly products.

## Charts

- [Rootly Catalog Sync](charts/rootly-catalog-sync/) — Keep services, teams, and metadata in sync from external sources
- [Rootly Edge Connector](charts/rootly-edge-connector/) — Execute custom actions in response to Rootly alerts and incidents

## Usage

### Using GitHub Pages repository

```shell
helm repo add rootly https://rootlyhq.github.io/helm-charts
helm repo update
```

Install a chart:

```shell
# Catalog Sync (CronJob by default, or --set mode=watch for continuous)
helm install catalog-sync rootly/rootly-catalog-sync \
  --set rootly.apiKey=rootly_... \
  --set-string configYaml="$(cat rootly-catalog-sync.yaml)"

# Edge Connector
helm install rootly-edge-connector rootly/rootly-edge-connector \
  --set rootly.apiKey=rec_your_api_key \
  --set-file actionsYaml=actions.yml
```

### Using OCI registry

```shell
# Catalog Sync
helm install catalog-sync oci://ghcr.io/rootlyhq/helm-charts/rootly-catalog-sync \
  --version 0.1.0 \
  --set rootly.apiKey=rootly_... \
  --set-string configYaml="$(cat rootly-catalog-sync.yaml)"

# Edge Connector
helm install rootly-edge-connector oci://ghcr.io/rootlyhq/helm-charts/rootly-edge-connector \
  --version 0.1.0 \
  --set rootly.apiKey=rec_your_api_key \
  --set-file actionsYaml=actions.yml
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

[Apache 2.0](LICENSE)
