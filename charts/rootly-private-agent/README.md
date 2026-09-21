# Rootly Private Agent

> **Early preview:** interfaces, permissions, and configuration may change before
> general availability.

> **Unreleased:** generic HTTP provider configuration is staged for the next
> compatible chart and agent image release. The currently published chart does
> not include this provider yet.

Rootly Private Agent runs inside a customer Kubernetes cluster and gives Rootly
AI SRE outbound-only, policy-bounded access to private infrastructure. The
combined runtime supports Kubernetes, Prometheus, Loki, allowlisted Streamable
HTTP MCP providers, databases, and fixed-origin internal HTTP APIs.

## Install

Create a one-time enrollment token in **AI > Configurations > Private Agent**,
then install the chart without placing the token in a values file:

```sh
helm repo add rootly https://rootlyhq.github.io/helm-charts
helm repo update

helm upgrade --install rootly-private-agent rootly/rootly-private-agent \
  --namespace rootly-private-agent \
  --create-namespace \
  --set-file enrollment.token=./enrollment-token
```

For GitOps, create a Secret separately and set:

```yaml
enrollment:
  existingSecret: rootly-private-agent-enrollment
  secretKey: enrollment-token
```

The enrollment token is used once. Refreshed credentials are written to the
PersistentVolumeClaim, so persistence should remain enabled in production.

## Security defaults

- One replica owns one durable agent identity.
- The process runs as UID/GID 65532 with a read-only root filesystem, no Linux
  capabilities, no privilege escalation, and the runtime-default seccomp profile.
- No Service or Ingress is created. The agent initiates an HTTP/2 gRPC connection
  to `connect.rootly.com:443`.
- Secrets are not readable through Kubernetes RBAC.
- Pod logs are disabled until explicitly enabled.
- Kubernetes reads are also constrained by the customer-local policy rendered
  into `config.yaml`; Rootly cannot expand that policy remotely.

## Kubernetes permissions

The default ClusterRole grants `get`, `list`, and `watch` over the resources the
agent understands, including Pods, workloads, Events, Nodes, Namespaces,
Services, Endpoints, ConfigMaps, storage, quotas, CRDs, Argo Rollouts, KEDA,
Gateway API, and `networking.istio.io` resources. It grants `create` only for
`selfsubjectaccessreviews` and `selfsubjectrulesreviews`; these ask Kubernetes to
evaluate the agent's own access and do not mutate workloads or RBAC.

Enabling `providers.kubernetes.policy.allowPodLogs` additionally grants `get` on
`pods/log`. ConfigMaps and logs may contain sensitive customer data, so scope
`allowedNamespaces` and enable logs deliberately.

## Private provider credentials

Prometheus, Loki, MCP, PostgreSQL, MySQL, internal HTTP, and custom CA
credentials must be mounted as files using `extraVolumes` and
`extraVolumeMounts`; do not put secret values, database passwords, or inline
DSNs in Helm values. Database and HTTP providers reference mounted credential,
CA, and optional client certificate/key paths, and reload rotating credential
files without placing their contents in the rendered ConfigMap. See the
[Private Agent documentation](https://docs.rootly.com/private-agent#rootly-private-agent)
and [internal HTTP guide](https://docs.rootly.com/private-agent-http).

## NetworkPolicy

The optional NetworkPolicy is disabled because standard Kubernetes policy cannot
allow DNS hostnames. If enabled, supply egress rules for cluster DNS, the
Kubernetes API, `connect.rootly.com:443`, and every configured provider endpoint.

## Verifying the container image

Rootly publishes immutable multi-platform images and signs the manifest digest
with the private agent release workflow. With Cosign 3 or newer, resolve the
digest directly from the public registry and verify its keyless signature:

```sh
VERSION=0.1.0-beta.7
DIGEST="$(docker buildx imagetools inspect \
  "rootlyhub/rootly-private-agent:${VERSION}" \
  --format '{{.Manifest.Digest}}')"

cosign verify \
  --certificate-identity "https://github.com/rootlyhq/rootly-private-agent/.github/workflows/release.yml@refs/tags/v${VERSION}" \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  "rootlyhub/rootly-private-agent@${DIGEST}"
```

The chart pins the released image digest in `values.yaml`; the tag remains as a
human-readable version reference. See Rootly's
[Private Agent installation guide](https://docs.rootly.com/private-agent#verify-the-container-image)
for the canonical customer instructions.

## Licensing

The Helm chart source is licensed under Apache-2.0 as part of this repository.
The `rootly-private-agent` container and executable are proprietary and governed
by the separately included Rootly Private Agent Binary License. Public image
availability does not make the runtime open source.
