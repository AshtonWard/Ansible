# Sanitization review — November 17, 2026

Reviewed against source commit `d855d571d52a42c801bff8542c274c6964800829`. Implementation hashes in `SOURCE_REVIEW.json` allow later source changes to be detected without retaining source contents here.

## Drift corrected

The previous staged copy omitted the newer Node Exporter, separate Periphery, Wazuh agent, and renamed Komodo Core roles and associated playbooks. It retained obsolete combined role layouts and provisioning logic. This copy is rebuilt from the current source implementation; obsolete staged-only files are removed. The inventory retains the current nested group relationships with fictional hosts and documentation addresses.

## Deliberate differences from the operational source

| Area | Sanitized behavior |
| --- | --- |
| Inventory | Reconstructed examples; private host variables and credential values are not copied |
| Endpoints and paths | Reserved example domains, configurable service variables, configurable checkout directory and network prefix |
| Authentication | Variable references only; no copied plaintext credentials, encrypted vault payloads, or password files |
| SSH and output | Host key verification enabled; built-in stdout callback; no checked-in runtime log dependency |
| Base-role defaults | Invalid list-shaped defaults replaced with an empty mapping |
| Inventory scripts | Traverse nested groups; preserve host variables; validate IPv4 and names; reject ambiguous or parent group targets |
| Group creation | Adds new groups beneath `linux_hosts` by default and stages the provisioning-menu change alongside inventory |
| Workflow inputs | Passed through environment variables; inventory group checked dynamically instead of a stale hardcoded list |
| Infrastructure jobs | Explicit repository-variable opt-in; secret password file created with restrictive permissions and cleaned up |
| Secret-bearing tasks | Periphery key debug output removed; Core environment task uses `no_log` |
| Validation | Added isolated inventory-script tests, publication checks, and source-drift tracking |

The script and workflow fixes above are staged-only improvements; they have **not** been backported to the operational scripts or deployment workflows. Source behavior for inactive Komodo Core, Prometheus configuration replacement, package choices, and upstream downloads remains visible and is documented in the README.

## Review boundaries

Operational implementation files are unchanged by this review. A separate, hosted validation workflow is added to the private repository; it has read-only repository permissions, no lab secrets, and performs no infrastructure deployment. It checks the nested staging folder rather than the operational inventory.

Automated checks cannot prove the absence of every possible secret or validate live service behavior. Before manual publication, inspect the complete staged diff and any files added after this review. No content is automatically published to the public repository.
