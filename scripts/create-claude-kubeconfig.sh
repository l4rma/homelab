#!/usr/bin/env bash
# Generates a read-only kubeconfig for Claude Code from the claude-readonly
# ServiceAccount token (kubernetes/infrastructure/claude-readonly). Output is never committed.
set -euo pipefail

ADMIN_CONTEXT="homelab"
NAMESPACE="claude"
SECRET="claude-readonly-token"
OUT="${HOME}/.kube/claude-readonly.yaml"

admin() { kubectl --context "$ADMIN_CONTEXT" "$@"; }

if ! admin get secret "$SECRET" -n "$NAMESPACE" >/dev/null 2>&1; then
  echo "ERROR: secret $NAMESPACE/$SECRET not found (context: $ADMIN_CONTEXT)." >&2
  echo "Flux has probably not synced kubernetes/infrastructure/claude-readonly yet." >&2
  echo "Check: kubectl get kustomization -n flux-system" >&2
  exit 1
fi

TOKEN="$(admin get secret "$SECRET" -n "$NAMESPACE" -o jsonpath='{.data.token}' | base64 -d)"
CA="$(admin get secret "$SECRET" -n "$NAMESPACE" -o jsonpath='{.data.ca\.crt}')"
if [[ -z "$TOKEN" || -z "$CA" ]]; then
  echo "ERROR: secret $NAMESPACE/$SECRET exists but has no token yet. Try again in a few seconds." >&2
  exit 1
fi

CLUSTER_NAME="$(kubectl config view -o jsonpath="{.contexts[?(@.name==\"$ADMIN_CONTEXT\")].context.cluster}")"
SERVER="$(kubectl config view -o jsonpath="{.clusters[?(@.name==\"$CLUSTER_NAME\")].cluster.server}")"
if [[ -z "$SERVER" ]]; then
  echo "ERROR: could not find server address for context $ADMIN_CONTEXT." >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT")"
umask 077
cat > "$OUT" <<EOF
apiVersion: v1
kind: Config
clusters:
  - name: homelab
    cluster:
      server: ${SERVER}
      certificate-authority-data: ${CA}
users:
  - name: claude-readonly
    user:
      token: ${TOKEN}
contexts:
  - name: claude@homelab
    context:
      cluster: homelab
      user: claude-readonly
current-context: claude@homelab
EOF
chmod 600 "$OUT"
echo "Wrote $OUT"

echo
echo "== Test: kubectl get nodes"
KUBECONFIG="$OUT" kubectl get nodes

echo
echo "== Test: can-i get secrets -A (expect: no)"
KUBECONFIG="$OUT" kubectl auth can-i get secrets -A || true

echo
echo "== Test: can-i delete pods -A (expect: no)"
KUBECONFIG="$OUT" kubectl auth can-i delete pods -A || true
