# users

Decides which Linux accounts exist in an environment and renders them as
cloud-init `users` entries. Creates no Azure resources, so it's fully
testable offline (`terraform test`).

**Input:** `environment`, and `users` keyed by username, each with `ssh_keys`, `sudo` and `environments`.

**Output:** `cloud_init_users` (append after `"default"`), `usernames`, and `summary` (username => sudo).

**Rejected at plan time:**
- usernames that aren't valid Linux names
- reserved names
- non-ed25519 keys
- users with no keys
- unknown environments
