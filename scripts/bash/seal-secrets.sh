#!/bin/bash
set -e

# This script seals the secret template for use with Sealed Secrets controller
# Run this after the sealed-secrets controller is installed

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "Installing kubeseal CLI..."
wget -q https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/kubeseal-0.24.0-linux-amd64.tar.gz -O /tmp/kubeseal.tar.gz
tar xfz /tmp/kubeseal.tar.gz -C /tmp
chmod +x /tmp/kubeseal

echo "Sealing secret..."
/tmp/kubeseal -f "$PROJECT_DIR/k8s/journal/secret-template.yaml" \
  -w "$PROJECT_DIR/k8s/journal/sealed-secret.yaml" \
  --format yaml

echo "✓ Sealed secret created at k8s/journal/sealed-secret.yaml"
echo "  Now you can safely commit this to Git!"
echo "  You can delete secret-template.yaml if you want - the sealed version is what's deployed"
