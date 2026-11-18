# Ansible homelab automation

I use Ansible, PowerShell, and GitHub Actions to provision and configure Linux hosts in my Proxmox homelab. This repository contains the public examples: VM provisioning workflows, reusable roles, inventory-management scripts, monitoring setup, and service recovery.

The goal is to make routine infrastructure changes repeatable and reviewable. The work also gives me a place to test the parts that are easy to miss in a manual setup, including input validation, inventory consistency, and failure handling.

I keep operational inventory and credentials outside this repository. The inventory here uses fictional host aliases, documentation IP addresses, and reserved example domains.

## Provisioning flow

The VM workflow connects Proxmox provisioning to Ansible configuration:

1. Validate the VM name, template ID, network inputs, and inventory group.
2. Clone an existing Proxmox template and configure the guest network.
3. Add the host to inventory and validate the resulting configuration.
4. Commit the inventory change, wait for SSH, and run the bootstrap playbook.

Ansible handles host configuration; the GitHub Actions workflow coordinates the provisioning stages. PowerShell scripts update the nested YAML inventory and host variables. They preserve existing host settings, reject invalid input, and keep the workflow's group menu synchronized with inventory changes.

The workflow does not yet roll back a partially created VM when a later stage fails. Safe rollback and explicit failure-state reporting are priorities for further development.

## Configuration and service management

| Entry point | Purpose |
| --- | --- |
| `playbooks/bootstrap.yml` | Install base packages and PowerShell on Linux hosts |
| `playbooks/docker.yml` | Install Docker and Komodo Periphery |
| `playbooks/install_periphery.yml` | Install Periphery independently of Docker |
| `playbooks/install_wazuh_agent.yml` | Install Wazuh agents, excluding the manager |
| `playbooks/restart_wazuh_agents.yml` | Restart agents without targeting the manager |
| `playbooks/install_node_exporter.yml` | Install Node Exporter and update Prometheus scrape configuration |
| `playbooks/recover_hermes.yml` | Check Hermes user services and dashboard responses, then restart and retry when needed |
| `playbooks/komodo.yml` | Reserved entry point for unfinished Komodo Core deployment |

Docker and Periphery have separate roles so they can run independently or together. Host and group variables hold configuration values rather than embedding them in each playbook. The Node Exporter playbook separates exporter installation from the Prometheus configuration update.

## Repository layout

```text
.github/workflows/    Manual provisioning and playbook workflows
inventory/            Fictional nested inventory, host vars, and group vars
playbooks/            Configuration and recovery entry points
roles/                Reusable host and service tasks
scripts/              PowerShell inventory-management scripts
tests/                Isolated inventory-script tests
tools/                Public-content validation checks
```

## Configuration requirements

The examples target Ubuntu-based hosts and assume an existing Proxmox template, a configured network bridge, trusted SSH host keys, and suitable administrative access. Package sources and architecture assumptions need review before use on another platform.

Tooling used for validation:

- ansible-core 2.19.15
- PowerShell 7 with `powershell-yaml` 0.4.12
- Python 3 with PyYAML for the content checker

Collection requirements are listed in `collections/requirements.yml`:

```sh
ansible-galaxy collection install -r collections/requirements.yml
```

Service configuration uses variables such as `wazuh_manager_address`, `hermes_dashboard_url`, and `komodo_core_address`. Credentials are variable references, not checked-in values. Encrypted variables belong in a separate, untracked file supplied at runtime with `--extra-vars @/path/to/private-vault.yml` and an appropriate vault password source. SSH host key checking is enabled.

### GitHub Actions

All infrastructure workflows require manual dispatch and remain disabled unless `ENABLE_LAB_AUTOMATION` is set to `true`. They assume a deliberately configured private execution environment; a privileged lab runner should not accept untrusted jobs from a public repository.

| Repository variable | Purpose |
| --- | --- |
| `ENABLE_LAB_AUTOMATION` | Explicitly enable infrastructure jobs |
| `ANSIBLE_REPO_DIR` | Persistent checkout used by the runner |
| `LAB_IPV4_PREFIX` | Configurable IPv4 prefix for the provisioning example |

The workflows reference `ANSIBLE_VAULT_PASSWORD`; the runner checkout example also references `ANSIBLE_REPO_PERMISSIONS_PAT`. Neither credential is included. A vault password does not supply the encrypted variables themselves, so those require separate configuration.

The provisioning example derives a subnet from the VLAN input and uses a `/24` mask. Its VLAN and host-octet restrictions are specific to that addressing model, not general networking limits.

## Validation

The public examples passed the content checker, inventory parsing, and syntax checks for all eight playbooks. All four PowerShell scripts passed parsing, and the isolated inventory tests covered nested groups, preservation of host variables, repeated execution, invalid inputs, group creation, and workflow-menu synchronization.

These checks validate structure and selected script behavior. They do not establish that this public configuration has provisioned a VM, installed services, or recovered a live system.

Run the checks from the repository root:

```sh
python tools/check_sanitized.py
ansible-inventory --list
ansible-playbook --syntax-check playbooks/*.yml
pwsh -NoProfile -File tests/inventory_scripts.ps1
```

The inventory tests modify a temporary example checkout. The content checker scans for credential patterns, non-example addresses, YAML errors, missing workflow opt-in, and invalid Bash syntax. It does not replace manual review. The role-local `roles/periphery/tests/test.yml` installs software and is not part of the isolated test suite.

## Known limitations and next work

- **Provisioning failure handling:** later-stage failures can leave a partially deployed VM. Rollback must distinguish a VM created by the current run from a pre-existing resource before attempting cleanup.
- **Shared checkout concurrency:** workflows using the same persistent checkout are not serialized. Concurrent runs can race inventory edits and Git operations.
- **Prometheus configuration ownership:** the role replaces the complete configuration, backs up the previous file, and validates the replacement with `promtool`. The example defines no alert rules or Alertmanager destinations. Existing jobs and rules need to be incorporated before using it against another configuration.
- **Playbook limits:** the Prometheus update is a separate play. A `--limit` that excludes the Prometheus host also skips that update.
- **Komodo Core:** the role entry point does not import the standalone installer, and its Compose template is empty. `komodo.yml` does not currently deploy Core.
- **Installer dependencies:** Periphery and Core installer downloads follow upstream branches rather than immutable revisions. The Periphery example also uses an HTTP Core endpoint; transport security needs explicit configuration before operational use.

The next work is deployment rollback, workflow concurrency controls, and completing the remaining service-deployment paths. I am keeping those gaps visible rather than presenting the repository as a finished provisioning platform.
