# Rootly Helm Charts

Official Helm charts for Rootly products.

## Charts

- [Rootly Catalog Sync](charts/rootly-catalog-sync/) — Keep services, teams, and metadata in sync from external sources
- [Rootly Edge Connector](charts/rootly-edge-connector/) — Execute custom actions in response to Rootly alerts and incidents
- [Rootly Private Agent](charts/rootly-private-agent/) — Connect Rootly AI SRE to private Kubernetes and observability data

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

# Private Agent (early preview)
helm install rootly-private-agent rootly/rootly-private-agent \
  --namespace rootly-private-agent \
  --create-namespace \
  --set-file enrollment.token=./enrollment-token
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

# Private Agent (early preview)
helm install rootly-private-agent oci://ghcr.io/rootlyhq/helm-charts/rootly-private-agent \
  --version 0.1.0 \
  --namespace rootly-private-agent \
  --create-namespace \
  --set-file enrollment.token=./enrollment-token
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

[Apache 2.0](LICENSE)
