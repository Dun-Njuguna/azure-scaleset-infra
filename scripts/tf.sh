#!/usr/bin/env bash
# Runs Terraform against ONE environment, always pairing its backend (state)
# with its tfvars, so you can't plan prod with dev's state or vice versa.
#
#   ./scripts/tf.sh dev plan
#   ./scripts/tf.sh dev apply            # applies the plan saved by 'plan'
#   ./scripts/tf.sh prod output app_url
#   ./scripts/tf.sh staging destroy
set -euo pipefail

usage() { echo "usage: $0 <dev|staging|prod> <init|plan|apply|destroy|output|...> [args]" >&2; exit 1; }

ENV="${1:-}"; CMD="${2:-}"
if [ -z "$ENV" ] || [ -z "$CMD" ]; then usage; fi
shift 2
case "$ENV" in dev|staging|prod) ;; *) usage ;; esac

TF="${TF:-terraform}"
cd "$(dirname "$0")/.."

# Shared values, then the environment, then optional git-ignored local overrides.
VAR_FILES=(-var-file=envs/common.tfvars -var-file="envs/$ENV.tfvars")
for f in envs/common.local.tfvars "envs/$ENV.local.tfvars"; do
  [ -f "$f" ] && VAR_FILES+=("-var-file=$f")
done

PLAN_FILE="$ENV.tfplan"

confirm_prod() {
  if [ "$ENV" = "prod" ]; then
    read -r -p "You are about to $1 PROD. Type 'prod' to continue: " answer
    [ "$answer" = "prod" ] || { echo "Aborted."; exit 1; }
  fi
}

# Re-initialise against this environment's state every time. -reconfigure
# makes sure we never silently keep the previous environment's backend.
"$TF" init -input=false -reconfigure -backend-config="envs/$ENV.backend.hcl" > /dev/null

case "$CMD" in
  init)
    echo "Initialised against $ENV state."
    ;;
  plan)
    "$TF" plan "${VAR_FILES[@]}" -out="$PLAN_FILE" "$@"
    echo "Saved plan: $PLAN_FILE  ->  ./scripts/tf.sh $ENV apply"
    ;;
  apply)
    if [ -f "$PLAN_FILE" ]; then
      confirm_prod "apply a saved plan to"
      "$TF" apply "$PLAN_FILE"
      rm -f "$PLAN_FILE"
    else
      confirm_prod "apply to"
      "$TF" apply "${VAR_FILES[@]}" "$@"
    fi
    ;;
  destroy)
    confirm_prod "DESTROY"
    "$TF" destroy "${VAR_FILES[@]}" "$@"
    ;;
  output|state|show|providers)
    "$TF" "$CMD" "$@"
    ;;
  *)
    "$TF" "$CMD" "${VAR_FILES[@]}" "$@"
    ;;
esac
