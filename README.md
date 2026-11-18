# Ansible homelab automation — sanitized reference

This directory is a publication candidate built from the operational Ansible project reviewed on **November 17, 2026**. It includes the current playbooks, roles, nested inventory structure, provisioning workflows, and inventory scripts. Inventory entries use fictional aliases and RFC 5737 documentation addresses; service URLs use reserved example domains. These are examples, not a live inventory.

## What the project demonstrates

| Entry point | Actual behavior |
| --- | --- |
| `playbooks/bootstrap.yml` | Base packages and PowerShell installation on `linux_hosts` |
| `playbooks/docker.yml` | Docker **and** Komodo Periphery on the `docker` group |
| `playbooks/install_periphery.yml` | Periphery installation separately from Docker |
| `playbooks/install_wazuh_agent.yml` | Wazuh agent installation, excluding the Wazuh manager |
| `playbooks/restart_wazuh_agents.yml` | Restart agents, excluding the manager |
| `playbooks/install_node_exporter.yml` | Install Node Exporter, then render Prometheus scrape configuration |
| `playbooks/recover_hermes.yml` | Check user services and HTTPS response; restart and retry when needed |
| `playbooks/komodo.yml` | Targets `komodo_core`; its role entry point is currently empty |
| `.github/workflows/create-new-vm.yml` | Clone a Proxmox template, configure networking, update inventory, wait for SSH, and bootstrap |
| `.github/workflows/create-new-group.yml` | Create an inventory group and update the provisioning menu |

`roles/docker` installs Docker; Periphery now has its own role. The playbook combines them explicitly. `roles/node_exporter` and `roles/wazuh_agent` reflect the newer monitoring and security automation.

## Prerequisites and configuration

Syntax checks were run with ansible-core 2.19.15. Operational use requires Python 3, Ansible, PowerShell 7 with `powershell-yaml` (tested with 0.4.12), SSH access, and appropriate sudo privileges. Network device tasks additionally require collections:

```sh
ansible-galaxy collection install -r collections/requirements.yml
```

The examples retain Ubuntu package repositories and architecture assumptions from the source. Review them for the OS and architecture you actually use. Provisioning requires an existing Proxmox template and the expected bridge; these workflows do not create either.

Set addresses and accounts in your own private inventory. Supply secrets through a separately managed, **untracked** encrypted vars file, passed with `--extra-vars @/path/to/private-vault.yml` and a runtime vault password source. Never place real configuration in this publication folder. Configuration variables include:

- `wazuh_manager_address`: manager endpoint.
- `hermes_dashboard_url`: dashboard URL; HTTP 200 and 302 are considered healthy.
- `komodo_core_address` and `komodo_onboarding_key`: Periphery registration endpoint and key.
- `vault_cisco_password`: switch authentication secret referenced by the example group variables.
- `komodo_database_password`: only relevant if you deliberately enable the dormant Core installer.

SSH host key checking is enabled in this copy. Establish trusted host keys before operational use.

## Workflow configuration

The infrastructure workflows are manual and **disabled by default** through a job condition. Do not attach a public repository's untrusted jobs to a privileged lab runner. For an intentionally configured private deployment, repository variables are:

| Variable | Purpose |
| --- | --- |
| `ENABLE_LAB_AUTOMATION` | Must equal `true` to opt into infrastructure jobs |
| `ANSIBLE_REPO_DIR` | Absolute path to a persistent clone containing this example at its root |
| `LAB_IPV4_PREFIX` | Your network's first two IPv4 octets; no operational value is included |

Secrets referenced by the examples are `ANSIBLE_VAULT_PASSWORD` and, in the runner checkout example, `ANSIBLE_REPO_PERMISSIONS_PAT`. A vault password alone does not provide encrypted variables: arrange the private vars source separately before adapting these workflows. The persistent checkout needs authenticated pull/push access and the required tools installed.

Provisioning derives the subnet's third octet from the VLAN, uses a `/24` mask, and restricts VLANs to 10–254 and host octets to 11–254. This is the source project's addressing convention, not the full supported VLAN range. The workflow menu is checked against the inventory. Scripts traverse nested groups, preserve existing host variables, reject malformed inputs, and synchronize new group options. YAML serialization can normalize formatting and comments.

## Important implementation limits

- **Komodo Core is unfinished/inactive:** `roles/komodo_core/tasks/main.yml` does not import the standalone installer; the Compose template is empty. Running `komodo.yml` does not deploy Core. These source limitations are preserved rather than presenting an implementation that does not exist.
- **Prometheus configuration is replaced in full.** The template uses the `linux_hosts` inventory to construct Node Exporter targets, includes a local Prometheus job, and leaves rule and Alertmanager targets empty. The task backs up the previous file and validates with `promtool` before replacing it. Review existing jobs and rules before use.
- Periphery and Core installer downloads follow upstream branches; they are not pinned to immutable revisions. Review upstream code before operational installation.
- The role-local `roles/periphery/tests/test.yml` is an installation example, not an isolated unit test. Do not execute it as part of publication checks.
- Validation here does not prove VM creation, package installation, live reachability, or recovery against infrastructure.

## Local validation

Keep real inventory, credentials, vaults, and runtime files out of this public reference. Review changes before publishing them.

Run from the repository root:

```sh
python tools/check_sanitized.py
ansible-inventory --list
ansible-playbook --syntax-check playbooks/*.yml
pwsh -NoProfile -File tests/inventory_scripts.ps1
```

The PowerShell tests mutate a temporary example checkout only. `tools/check_sanitized.py` checks publication patterns, allowed example IPv4 addresses, YAML, workflow opt-in, and Bash syntax. These are guardrails, not a guarantee that all sensitive content will be recognized. Review new text and artifacts manually.
