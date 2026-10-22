#!/usr/bin/env bash
# Lists the human Linux accounts on EVERY instance of an environment's scale set.
# Use it to prove offboarding: remove a user from envs/common.tfvars, apply,
# wait for the rolling upgrade, run this again, and the account is gone everywhere.
#
#   ./scripts/whoami-on-instances.sh dev
#
# Needs: az CLI logged in. Uses Run Command, so no SSH access is required.
set -euo pipefail

ENV="${1:?usage: $0 <dev|staging|prod>}"
cd "$(dirname "$0")/.."

RG="$(./scripts/tf.sh "$ENV" output -raw resource_group_name)"
VMSS="$(./scripts/tf.sh "$ENV" output -raw vmss_name)"

echo "Expected (from Terraform):"
./scripts/tf.sh "$ENV" output -json users | jq -r 'to_entries[] | "  \(.key)\(if .value then " (sudo)" else "" end)"'
echo

ids="$(az vmss list-instances -g "$RG" -n "$VMSS" --query "[].instanceId" -o tsv)"
if [ -z "$ids" ]; then
  echo "No running instances (scaled to zero outside business hours?)."
  exit 0
fi

for id in $ids; do
  echo "== $VMSS instance $id"
  az vmss run-command invoke -g "$RG" -n "$VMSS" --instance-id "$id" \
    --command-id RunShellScript \
    --scripts "getent passwd | awk -F: '\$3 >= 1000 && \$3 < 65534 {print \"  \" \$1}'; echo; echo '  sudoers:'; getent group sudo | cut -d: -f4 | tr ',' '\n' | sed 's/^/    /'" \
    --query "value[0].message" -o tsv | sed -n '/\[stdout\]/,/\[stderr\]/p' | sed '1d;$d'
done
