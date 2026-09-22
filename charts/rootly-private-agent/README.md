# Rootly Private Agent

> **Early preview:** interfaces, permissions, and configuration may change before
> general availability.

> **Unreleased:** generic HTTP, Grafana Tempo, Grafana Pyroscope, Argo CD, Kafka, and
> multi-cluster Kubernetes provider configuration is staged for the next
> compatible chart and agent image release. The currently published chart does
> not include these changes yet.

Rootly Private Agent runs inside a customer Kubernetes cluster and gives Rootly
AI SRE outbound-only, policy-bounded access to private infrastructure. The
combined runtime supports Kubernetes, Prometheus, Loki, allowlisted Streamable
HTTP MCP providers, databases, fixed-origin internal HTTP APIs, Grafana Tempo
trace queries, and Grafana Pyroscope profile queries. The native Argo CD adapter
adds bounded, read-only GitOps application and deployment context.

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

Each `providers.kubernetes[]` entry is one independently named and policy-bounded
cluster. An entry without `kubeconfigFile` uses the Pod's ServiceAccount; at most
one entry can use in-cluster authentication. Additional clusters reference an
absolute kubeconfig path mounted into the Pod and can select an explicit context:

```yaml
providers:
  kubernetes:
    - id: production
      displayName: Production
      kubeconfigFile: ""
      context: ""
      policy:
        allowedNamespaces: ["*"]
        allowClusterScoped: true
        defaultListLimit: 500
        maximumListLimit: 1000
        defaultWatchSeconds: 30
        maximumWatchSeconds: 60
        maximumResultBytes: 2097152
        allowPodLogs: false
        allowInsecureLogBackendTLS: false
        defaultLogBytes: 262144
        maximumLogBytes: 1048576
        defaultLogSeconds: 30
        maximumLogSeconds: 60
    - id: staging
      displayName: Staging
      kubeconfigFile: /run/secrets/kubernetes/staging.yaml
      context: staging
      policy:
        allowedNamespaces: ["default", "payments"]
        allowClusterScoped: false
        defaultListLimit: 500
        maximumListLimit: 1000
        defaultWatchSeconds: 30
        maximumWatchSeconds: 60
        maximumResultBytes: 2097152
        allowPodLogs: true
        allowInsecureLogBackendTLS: false
        defaultLogBytes: 262144
        maximumLogBytes: 1048576
        defaultLogSeconds: 30
        maximumLogSeconds: 60

extraVolumes:
  - name: kubernetes-kubeconfigs
    secret:
      secretName: rootly-private-agent-kubeconfigs
extraVolumeMounts:
  - name: kubernetes-kubeconfigs
    mountPath: /run/secrets/kubernetes
    readOnly: true
```

The legacy singleton `providers.kubernetes.enabled` shape is intentionally not
accepted. If every Kubernetes entry uses a mounted kubeconfig, set
`rbac.create: false`; the Pod then disables ServiceAccount token automounting.
To disable Kubernetes entirely, set `providers.kubernetes: []` together with
`rbac.create: false`; the rendered agent configuration preserves an explicit
empty list.
When `context` is empty, the agent uses the kubeconfig's `current-context`.
Relative CA, client-certificate, client-key, and token-file references resolve
from the kubeconfig directory; `exec` and legacy `auth-provider` authentication
plugins are rejected. The selected API server must use HTTPS with certificate
verification enabled; plaintext endpoints, embedded URL credentials, query
strings, fragments, and `insecure-skip-tls-verify` are rejected.

Enabling `providers.kubernetes[].policy.allowPodLogs` for the in-cluster entry
additionally grants `get` on `pods/log`. ConfigMaps and logs may contain sensitive
customer data, so scope `allowedNamespaces` and enable logs deliberately.

## Private provider credentials

Prometheus, Loki, Tempo, Pyroscope, Argo CD, MCP, PostgreSQL, MySQL, internal
HTTP, Kafka, and custom CA credentials must be mounted as files using `extraVolumes` and
`extraVolumeMounts`; do not put secret values, database passwords, or inline
DSNs in Helm values. Database and HTTP providers reference mounted credential,
CA, and optional client certificate/key paths, and reload rotating credential
files without placing their contents in the rendered ConfigMap. See the
[Private Agent documentation](https://docs.rootly.com/private-agent#rootly-private-agent),
[Grafana Tempo guide](https://docs.rootly.com/private-agent-tempo),
[Grafana Pyroscope guide](https://docs.rootly.com/private-agent-pyroscope),
[Argo CD guide](https://docs.rootly.com/private-agent-argocd),
[Kafka guide](https://docs.rootly.com/private-agent-kafka), and
[internal HTTP guide](https://docs.rootly.com/private-agent-http).

For Pyroscope, configure one or more direct endpoints or fixed Grafana data
source proxy prefixes. Keep credentials and tenant IDs in mounted files, and
use enforced label matchers to keep every query inside an approved population:

```yaml
providers:
  pyroscope:
    - id: profiles-production
      url: https://pyroscope.internal
      bearer_token_file: /run/secrets/pyroscope/token
      tenant_id_file: /run/secrets/pyroscope/tenant
      enforced_label_matchers: '{environment="production"}'
      policy:
        maximum_range_seconds: 3600
        maximum_nodes: 1024

extraVolumes:
  - name: pyroscope-credentials
    secret:
      secretName: rootly-private-agent-pyroscope
extraVolumeMounts:
  - name: pyroscope-credentials
    mountPath: /run/secrets/pyroscope
    readOnly: true
```

`tenant_id_file` fixes the Grafana tenant for every request. `enforced_label_matchers`
is an additional, optional boundary that the agent appends to every profile query.
Configure at least one of them for shared Pyroscope deployments; omit both only when
the endpoint itself is intentionally dedicated to this Private Agent's full scope.

For Argo CD, mount a dedicated read-only account token and reference its file:

```yaml
providers:
  argocd:
    - id: deployments-production
      url: https://argocd.internal
      token_file: /run/secrets/argocd/token
      policy:
        allowed_projects: [payments, platform]

extraVolumes:
  - name: argocd-token
    secret:
      secretName: rootly-private-agent-argocd
      items:
        - key: argocd-token
          path: token
extraVolumeMounts:
  - name: argocd-token
    mountPath: /run/secrets/argocd
    readOnly: true
```

Do not use an Argo CD administrator token. Cluster inventory is not advertised
unless `policy.allow_cluster_inventory` is explicitly enabled.

For Kafka, configure one entry per independently routed cluster. TLS is required
unless plaintext is explicitly enabled for local testing. This Amazon MSK
example uses the ECS task role, EKS workload identity, or EC2 instance profile
through the AWS default credential chain:

```yaml
providers:
  kafka:
    - id: events-staging-us-east-1
      bootstrap_servers:
        - boot-example.c1.kafka-serverless.us-east-1.amazonaws.com:9098
      tls:
        enabled: true
      sasl:
        mechanism: aws-msk-iam
        aws_region: us-east-1
      policy:
        allowed_topics: [staging.events.*]
        allow_message_reads: false
```

SASL/PLAIN, SCRAM-SHA-256, SCRAM-SHA-512, custom CAs, and mutual TLS are also
supported through mounted files. Message reads are disabled by default and
never join a consumer group or commit offsets.

## NetworkPolicy

The optional NetworkPolicy is disabled because standard Kubernetes policy cannot
allow DNS hostnames. If enabled, supply egress rules for cluster DNS, the
Kubernetes API, `connect.rootly.com:443`, and every configured provider endpoint.

## Verifying the container image

Rootly publishes immutable multi-platform images and signs the manifest digest
with the private agent release workflow. With Cosign 3 or newer, resolve the
digest directly from the public registry and verify its keyless signature:

```sh
VERSION=0.1.0-beta.12
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
