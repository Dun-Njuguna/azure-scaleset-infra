# Usage: make plan ENV=dev   |   make apply ENV=prod   |   make test
ENV ?= dev
TF  ?= terraform
export TF

.PHONY: help init plan apply destroy output fmt validate lint test test-users test-envs users

help: ## Show targets
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-12s %s\n", $$1, $$2}'

init: ## Init against ENV's state
	./scripts/tf.sh $(ENV) init

plan: ## Plan ENV and save the plan
	./scripts/tf.sh $(ENV) plan

apply: ## Apply ENV's saved plan
	./scripts/tf.sh $(ENV) apply

destroy: ## Destroy ENV (prod: turn lock_enabled off first)
	./scripts/tf.sh $(ENV) destroy

output: ## Show ENV's outputs
	./scripts/tf.sh $(ENV) output

users: ## List Linux users on every instance of ENV
	./scripts/whoami-on-instances.sh $(ENV)

fmt: ## Format all files
	$(TF) fmt -recursive

validate: ## Validate without touching any backend
	$(TF) init -backend=false -input=false > /dev/null
	$(TF) validate

lint: ## tflint across every module
	tflint --init
	tflint --recursive --config "$(CURDIR)/.tflint.hcl"

test-users: ## Unit tests for the users module
	cd modules/users && $(TF) init -input=false > /dev/null && $(TF) test

test-envs: ## Plan every environment against mocked providers
	$(TF) init -backend=false -input=false > /dev/null
	@for e in dev staging prod; do \
	  echo "== $$e"; \
	  $(TF) test -var-file=envs/common.tfvars -var-file=envs/$$e.tfvars || exit 1; \
	done

test: fmt validate test-users test-envs ## Everything that runs without Azure
