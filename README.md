# azure-scaleset-infra

Terraform for a small production-style platform on Azure: an autoscaling **VM Scale Set** behind a load balancer, **PostgreSQL** and **Redis** on private networking, **Azure Bastion** as the only way in, secrets in **Key Vault**, Linux **users managed as code**, and **budgets, locks and auto-shutdown** to keep costs under control.

One codebase, three environments (`dev`, `staging`, `prod`). Everything that differs between them lives in a tfvars file.

> The documentation is split into two sections. Click a heading to open or close it.

<details>
<summary><h2>🛠️ Terraform</h2></summary>

![How a change reaches Azure: edit and test locally, CI validates, tf.sh locks and reads state, refreshes, plans, applies and writes state](docs/workflow.svg)

CI validates every push without touching Azure. Changes are applied from your machine with `scripts/tf.sh`, which always pairs an environment's state file with its own tfvars.

### Layout

```
bootstrap/          one-time: storage account for Terraform state (local state)
envs/
  common.tfvars     shared settings + the user list
  <env>.tfvars      what makes each environment different
  <env>.backend.hcl which state file each environment uses
modules/
  network/          VNet, 4 subnets, NSGs (incl. Bastion's), NAT gateway, private DNS zones
  bastion/          Azure Bastion + public IP
  users/            validates users, renders cloud-init (no Azure resources)
  compute-vmss/     scale set, cloud-init, health extension, rolling upgrades, autoscale
  loadbalancer/     public IP, LB, /ready probe (inbound only)
  postgres/         Flexible Server, private access, write-only password
  redis/            Azure Managed Redis + private endpoint
  keyvault/         vault (RBAC + firewall) and secrets
  governance/       budget alerts, delete lock
  monitoring/       Log Analytics, action group, metric alerts
scripts/
  tf.sh                    runs Terraform for exactly one environment
  ssh.sh                   SSH or DB tunnel through Bastion
  whoami-on-instances.sh   lists Linux users on every instance (Run Command)
tests/              plans all environments against mocked providers
```

### Getting started

**You need:** Terraform ≥ 1.11, Azure CLI (`az login`), `jq`. Your account must be able to create role assignments: Owner, or Contributor plus User Access Administrator.

```bash
# 0. Offline checks (no Azure needed)
make test

# 1. One-time: create the state storage
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
cd bootstrap && terraform init && terraform apply && cd ..
SA=$(cd bootstrap && terraform output -raw storage_account_name)
sed -i "s/sttfstateCHANGEME/$SA/" envs/*.backend.hcl

# 2. Your real values, git-ignored
cat > envs/common.local.tfvars <<TF
alert_emails = ["you@example.com"]
admin_cidrs  = ["$(curl -s ifconfig.me)/32"]
app_image    = "ghcr.io/<you>/node-cicd-pipeline:<tag>"
TF

# 3. Put your real ed25519 public key in envs/common.tfvars

# 4. Build an environment
./scripts/tf.sh dev plan
./scripts/tf.sh dev apply
./scripts/tf.sh dev output app_url
```

Commit `.terraform.lock.hcl` after the first `init` so everyone gets the same provider versions.

**`tf.sh`** re-initialises against the chosen environment's state on every run and always loads the matching tfvars, so you can't plan prod with dev's state. Prod asks you to type `prod` before applying or destroying. The `Makefile` wraps it: `make plan ENV=staging`.

### Getting a shell (through Bastion)

```bash
./scripts/ssh.sh prod            # SSH to instance 0
./scripts/ssh.sh prod 1          # instance 1
./scripts/ssh.sh prod 0 --db     # tunnel Postgres to localhost:5432 via the server
```

On a server, sudo users can open the database directly with `sudo db`. It uses the app's own connection settings.

`ssh.sh` needs Bastion's **Standard** SKU, which enables connecting from your terminal. With the Basic SKU, connect from the portal: scale set → Instances → Connect → Bastion.

### Managing Linux users

Users are declared once in `envs/common.tfvars`:

```hcl
users = {
  duncan = { ssh_keys = ["ssh-ed25519 AAAA..."], sudo = true,  environments = ["dev", "staging", "prod"] }
  dev1   = { ssh_keys = ["ssh-ed25519 AAAA..."], sudo = false, environments = ["dev", "staging"] }
}
```

- **Checked before anything is created:** valid Linux usernames, ed25519 keys only, no reserved names, known environments only.
- **Per environment:** a user only exists where they're listed. `dev1` never exists in prod.
- **Sudo users** can also run Docker and `sudo db`. Others can log in and read logs only.
- **No passwords exist:** accounts are key-only, root login is off, and SSH is reachable only from Bastion.

**Offboarding is a one-line delete.** Remove the user and apply. A max-surge rolling upgrade builds fresh instances from the new model, then removes the old ones, so the account is gone everywhere. Prove it with `./scripts/whoami-on-instances.sh dev`.

### Deploying a new app version

Change `app_image` and apply. The image is part of cloud-init, so the same rolling upgrade runs:
- New instances are created first (surge), so capacity never drops.
- An instance only counts once `/ready` passes.
- Any unhealthy new instance **halts the rollout** while the old ones keep serving.

### Secrets in Terraform

- **The Postgres password is ephemeral.** It's generated during apply and sent to Postgres and Key Vault as **write-only** attributes, so it never appears in state, plans or logs.
- **To rotate it,** bump `postgres_password_version` and apply. Postgres and Key Vault update together.
- **Key Vault's firewall** only admits `admin_cidrs` and `snet-app`, so Terraform must run from an IP in `admin_cidrs`.

### Testing

Everything below runs without an Azure account (`make test`), and CI runs it on every push:

| Check | What it proves |
|---|---|
| `terraform validate` | Every module is valid against the real azurerm v5 schema |
| `modules/users` tests (9) | Per-environment filtering, sudo handling, rejection of RSA keys and bad or reserved names |
| `tests/environments.tftest.hcl` × 3 | Each environment plans with mocked providers, prod keeps HA, its lock, purge protection and Bastion, and Bastion exists exactly when enabled |
| `tflint` + azurerm ruleset | Provider-specific mistakes `validate` can't see |

### Destroying an environment

```bash
./scripts/tf.sh dev destroy
```

Prod has a CanNotDelete lock, so destroying it takes two steps:
1. Set `lock_enabled = false` in `prod.tfvars` and apply.
2. Destroy.

### Design decisions

- **Separate state per environment**, chosen by `-backend-config`, rather than workspaces. A wrong `workspace select` can't apply dev changes to prod.
- **Bastion as the only door.** No public IPs on servers and no SSH NAT rules. Bastion itself is reachable only from `admin_cidrs`, and its subnet has no route to the databases.
- **Users in cloud-init.** Scale set instances come and go, so anything configured after boot drifts. Baking users in makes every instance identical and removal guaranteed.
- **Max-surge rolling upgrades** gated by the health extension: deploys and user changes never reduce capacity.
- **Egress through a NAT gateway**, with default outbound access off, because implicit outbound access is retired for new subnets. A NAT gateway gives one fixed IP to allow-list elsewhere and allocates SNAT ports on demand, so egress doesn't run out of ports as the scale set grows. It also keeps the load balancer purely inbound.
- **Azure Managed Redis**, not the retiring Azure Cache for Redis, with the `EnterpriseCluster` policy so ordinary clients work.
- **`prevent_destroy` only on state storage.** Terraform can't vary it per environment, so prod relies on the resource lock, soft delete and purge protection instead.

### Known limitations and next steps

- **HTTP only.** Add Application Gateway (TLS + WAF) or Front Door in front of the load balancer.
- **The NAT gateway is zonal** (Standard SKU), while prod's servers span three zones. If that zone fails, prod loses outbound internet until it recovers. Zone-redundant egress needs the newer StandardV2 NAT gateway or one NAT gateway per zone.
- **Users and app image share cloud-init**, so changing either replaces every instance. A larger setup would bake a golden image with Packer.
- **State still contains** the break-glass private key and the Redis key, because those resources expose them. Treat state access as admin access.
- **Region:** check Azure Managed Redis is available in your region before enabling it.
- **Image access:** the container image must be public, or you need to add registry credentials.

</details>



<details>
<summary><h2>☁️ Azure architecture</h2></summary>

![Azure architecture: load balancer, VM Scale Set, PostgreSQL and Redis on private subnets, Azure Bastion, Key Vault, private DNS, monitoring and governance](docs/architecture.svg)

### Azure services used

| Service | What it does here |
|---|---|
| **Resource groups** | One per environment (`rg-plat-dev`, `rg-plat-staging`, `rg-plat-prod`), plus `rg-tfstate` for Terraform state |
| **Virtual Network** | One `/16` per environment, split into four subnets (below) |
| **Network Security Groups** | Firewall rules on every subnet |
| **Load Balancer** (Standard) + **Public IP** | Public entry point for app traffic (HTTP 80) with a health probe on `/ready`. Inbound only |
| **NAT Gateway** + **Public IP** | The servers' only way out to the internet: one fixed egress IP, SNAT ports allocated on demand, nothing can connect in |
| **Azure Bastion** (Standard) | The only way to SSH to the servers, from the portal or your terminal |
| **Virtual Machine Scale Sets** | Ubuntu 24.04 servers running the app in Docker |
| **Application Health extension** | Reports each instance's `/ready` status, which gates rolling upgrades |
| **Automatic instance repair** | Replaces instances that stay unhealthy |
| **Azure Monitor autoscale** | Scales on CPU, and to zero on nights and weekends in dev and staging |
| **Azure Database for PostgreSQL** (Flexible Server) | The main database: private access only, automatic backups, HA in prod |
| **Azure Managed Redis** | Cache, reachable only through a private endpoint |
| **Private Link** (private endpoint) | Gives Redis a private IP inside the VNet |
| **Private DNS zones** | Resolve Postgres and Redis names to private IPs |
| **Key Vault** | Database password, Redis key and break-glass SSH key |
| **Managed identities** | Let the servers read Key Vault without stored credentials |
| **Entra ID + Azure RBAC** | Who may manage resources, read secrets and write state |
| **Log Analytics** | Postgres logs and metrics (1 GB/day cap) |
| **Azure Monitor alerts + action groups** | Email alerts for unhealthy instances, CPU and database storage |
| **Cost Management budgets** | Email alerts at 50%, 80% and 100% of spend, plus forecast |
| **Resource locks** | Stop prod being deleted, even by Terraform |
| **Storage account** (Blob) | Terraform state: versioned, Entra-only, locked |
| **Run Command** | Inspect instances without SSH (used by `whoami-on-instances.sh`) |

**Not used:**
- **Application Gateway / WAF** and **Front Door**: traffic is plain HTTP through a Standard Load Balancer. Adding Application Gateway (TLS termination + WAF) is the main upgrade path.
- **Azure DNS public zones**: the app uses the public IP's Azure-provided name.
- **Container Registry**: the image comes from GitHub Container Registry.
- **AKS**: the app runs in Docker on scale set instances.

### Network and subnets

Each environment gets its own address space, so they never overlap and could be peered later: dev `10.10.0.0/16`, staging `10.20.0.0/16`, prod `10.30.0.0/16`. Subnets are carved out the same way in each; the dev addresses are shown here.

| Subnet | Range (dev) | Contains | Allowed in | Notes |
|---|---|---|---|---|
| `snet-app` | `10.10.1.0/24` | VM Scale Set instances | HTTP 80 from the internet (via the load balancer); SSH 22 **from the Bastion subnet only** | Key Vault service endpoint; default outbound access off, so all egress goes through the **NAT gateway** |
| `snet-db` | `10.10.2.0/24` | PostgreSQL Flexible Server | 5432 **from `snet-app` only** | Delegated to `Microsoft.DBforPostgreSQL/flexibleServers` |
| `snet-pe` | `10.10.3.0/24` | Redis private endpoint | 10000 **from `snet-app` only** | NSG rules enforced on private endpoints |
| `AzureBastionSubnet` | `10.10.4.0/26` | Azure Bastion | HTTPS 443 **from `admin_cidrs` only**, plus Azure's required platform rules | Name and `/26` minimum size are set by Azure |

Every data subnet ends with **deny all other VNet traffic**. Even the Bastion subnet, which is inside the VNet, can't reach Postgres or Redis.

### DNS

| Name | Type | Resolves to |
|---|---|---|
| `plat-<env>-<suffix>.<region>.cloudapp.azure.com` | Azure-provided, public | Load balancer public IP: **the app URL** |
| `<server>.postgres.database.azure.com` | Private zone `plat-<env>.private.postgres.database.azure.com`, linked to the VNet | Postgres private IP in `snet-db` |
| `<redis>.<region>.redis.azure.net` | Private zone `privatelink.redis.azure.net`, linked to the VNet | Redis private endpoint IP in `snet-pe` |
| `kv-plat-<env>-<suffix>.vault.azure.net` | Public | Key Vault (firewalled: admin IPs and `snet-app` only) |

Inside the VNet, Azure's resolver checks the linked private zones first, so the servers get private IPs for Postgres and Redis. Outside the VNet, those names resolve to nothing usable: there is no public endpoint to reach.

### Who can reach what

| From | Can reach | How |
|---|---|---|
| **Users** | The app | `http://<app-url>` → load balancer → healthy instances |
| **Admins** | App servers | **Azure Bastion only**, from an IP in `admin_cidrs`: browser (portal) or `./scripts/ssh.sh <env>` |
| **Admins** | Postgres | Through a server: Bastion → server → `sudo db`, or `./scripts/ssh.sh <env> 0 --db` to tunnel it to `localhost:5432` |
| **App servers** | Postgres, Redis, Key Vault | Private network + managed identity |
| **App servers** | The internet (outbound only) | NAT gateway, always from one fixed IP: `terraform output egress_ip` |
| **Bastion** | App servers on port 22 | **Nothing else.** No route to the databases |
| **Anyone else** | Nothing | No public IPs on servers or databases; SSH is closed except from Bastion |

**Bastion is on in prod and off by default in dev and staging.** It bills hourly while it exists, so switch it on when you need a shell:
1. Set `bastion.enabled = true` in `envs/<env>.tfvars` and apply.
2. Do the work.
3. Set it back to `false` and apply.

With Bastion off there is no SSH path at all; `whoami-on-instances.sh` still works through Run Command.

### Environments

| | dev | staging | prod |
|---|---|---|---|
| VM size / instances | B2s, 1–2 | B2s, 1–3 | D2as_v5, 2–6 across 3 zones |
| Off-hours scale to zero | Yes | Yes | Never |
| Postgres | Burstable B1ms, 7-day backups | Burstable B1ms | General Purpose, zone-redundant HA, 35-day geo-redundant backups |
| Redis | Off (bills 24/7) | Balanced_B0 | Balanced_B1, HA |
| Bastion | On demand | On demand | Always on |
| Budget | 30 | 60 | 400 |
| Delete lock | No | No | Yes |
| Key Vault purge protection | No | No | Yes |

### Secrets and identity

- **Servers read secrets with their managed identity** through the Key Vault firewall. Nothing secret is stored on disk images or in the scale set definition.
- **The Postgres password is never written to Terraform state.** See the Terraform section.
- **Break-glass access:** the scale set's built-in admin account (`platformadmin`) has a key that exists only in Key Vault. It's for emergencies only.

### Cost controls

- **Budgets** per environment, with alerts on actual and forecast spend.
- **Scale to zero** in dev and staging: 20:00 to 07:00 on weekdays (EAT), and all weekend.
- **Dev Postgres** is stopped and started on the same schedule by a GitHub workflow.
- **Redis off in dev**, and **Bastion on demand** in dev and staging: neither can be paused.
- **NAT gateway** bills hourly plus per GB processed. It stays on in every environment, because servers need it to boot.
- **Log Analytics** capped at 1 GB/day.

</details>
