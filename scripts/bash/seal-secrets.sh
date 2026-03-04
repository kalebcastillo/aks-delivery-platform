#!/bin/bash
set -e

# This script seals the secret template for use with Sealed Secrets controller
# Used by infra-bootstrap.sh to create encrypted secrets safe for Git

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SOURCE_SECRET_FILE="$PROJECT_DIR/.secrets/journal-secret.yaml"

# Install kubeseal if not already present
if ! command -v kubeseal &> /dev/null; then
  echo "Installing kubeseal CLI..."
  wget -q https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/kubeseal-0.24.0-linux-amd64.tar.gz -O /tmp/kubeseal.tar.gz
  tar xfz /tmp/kubeseal.tar.gz -C /tmp
  chmod +x /tmp/kubeseal
  KUBESEAL_CMD="/tmp/kubeseal"
else
  KUBESEAL_CMD="kubeseal"
fi

if [[ ! -f "$SOURCE_SECRET_FILE" ]]; then
  echo "Missing source secret file: $SOURCE_SECRET_FILE"
  echo "Create it locally (not committed) and re-run this script."
  exit 1
fi

echo "Sealing secret with kubeseal..."
$KUBESEAL_CMD -f "$SOURCE_SECRET_FILE" \
  -w "$PROJECT_DIR/k8s/journal/manifests/sealedsecret.yaml" \
  --format yaml \
  --name journal \
  --namespace default \
  --controller-namespace sealed-secrets

echo "✓ Sealed secret created at k8s/journal/manifests/sealedsecret.yaml"
echo "  This encrypted secret is safe to commit to Git"

