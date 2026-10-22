#!/usr/bin/env bash
# SSH to an app server through Azure Bastion, the ONLY way in.
#
#   ./scripts/ssh.sh dev              # shell on instance 0
#   ./scripts/ssh.sh dev 1            # shell on instance 1
#   ./scripts/ssh.sh dev 0 --db       # tunnel Postgres to localhost:5432 (via the server)
#
# Needs: az CLI logged in, the 'bastion' and 'ssh' az extensions (installed on
# first use), Bastion enabled with the Standard SKU, and your key in envs/common.tfvars.
# Basic SKU: use the portal instead (VM scale set -> Instances -> Connect -> Bastion).
set -euo pipefail

ENV="${1:?usage: $0 <dev|staging|prod> [instance-index] [--db]}"
INDEX="${2:-0}"
MODE="${3:-}"
SSH_USER="${SSH_USER:-$USER}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_ed25519}"
cd "$(dirname "$0")/.."

out() { ./scripts/tf.sh "$ENV" output -raw "$1"; }

RG="$(out resource_group_name)"
VMSS="$(out vmss_name)"
BASTION="$(./scripts/tf.sh "$ENV" output -json bastion | jq -r '.name // empty')"
if [ -z "$BASTION" ]; then
  echo "Bastion is disabled in $ENV. Set bastion.enabled = true in envs/$ENV.tfvars and apply." >&2
  exit 1
fi

mapfile -t IPS < <(az vmss nic list -g "$RG" --vmss-name "$VMSS" \
  --query "[].ipConfigurations[0].privateIPAddress" -o tsv)
if [ "${#IPS[@]}" -eq 0 ]; then
  echo "No running instances (scaled to zero outside business hours?)." >&2
  exit 1
fi
IP="${IPS[$INDEX]:?no instance with index $INDEX (have ${#IPS[@]})}"

if [ "$MODE" = "--db" ]; then
  PG="$(out postgres_fqdn)"
  echo "Tunnel: localhost:2222 -> Bastion -> $IP:22, then localhost:5432 -> $PG:5432"
  az network bastion tunnel --name "$BASTION" --resource-group "$RG" \
    --target-ip-address "$IP" --resource-port 22 --port 2222 > /dev/null &
  TUNNEL=$!
  trap 'kill $TUNNEL 2> /dev/null || true' EXIT
  sleep 5
  echo "Connected. In another terminal:  psql \"host=localhost port=5432 dbname=app user=pgadmin sslmode=require\""
  echo "Password: az keyvault secret show --vault-name $(out key_vault_name) --name postgres-password --query value -o tsv"
  echo "Ctrl+C to close."
  ssh -N -p 2222 -i "$SSH_KEY" -o StrictHostKeyChecking=accept-new \
    -L "5432:$PG:5432" "$SSH_USER@127.0.0.1"
else
  echo "SSH to $VMSS instance $INDEX ($IP) through $BASTION as $SSH_USER"
  az network bastion ssh --name "$BASTION" --resource-group "$RG" \
    --target-ip-address "$IP" --auth-type ssh-key \
    --username "$SSH_USER" --ssh-key "$SSH_KEY"
fi
