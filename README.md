# Ansible Infrastructure Automation

Infrastructure automation for my personal homelab, built around Ansible, Proxmox VE, GitHub Actions, and PowerShell.

This repository contains reusable automation examples, configuration templates, and proof-of-concept implementations based on projects I've developed while building and maintaining my homelab.

The goal is to document practical approaches to infrastructure automation, demonstrate how different systems can work together, and provide examples that others can adapt to their own environments.

## What I'm Building

My homelab serves as a hands-on environment for experimenting with networking, virtualization, infrastructure automation, and security.

As the environment has grown, I've worked toward replacing repetitive administrative tasks with consistent, repeatable automation.

This includes provisioning virtual machines, configuring operating systems, deploying services, managing inventory, and integrating infrastructure management with GitHub Actions.

The projects in this repository demonstrate the design and implementation of those workflows using generalized configurations rather than my production homelab settings.

## Technologies

| Technology     | Application                                                    |
| -------------- | -------------------------------------------------------------- |
| Ansible        | Configuration management, provisioning, and service deployment |
| Proxmox VE     | Virtual machine provisioning and infrastructure management     |
| GitHub Actions | Workflow orchestration and automation execution                |
| PowerShell     | Inventory management and supporting automation scripts         |
| Linux          | Operating system configuration and administration              |
| Docker         | Container runtime and service deployment                       |
| Wazuh          | Endpoint security monitoring and agent deployment              |
| Komodo         | Container infrastructure management                            |

## Repository Structure

The repository is organized around reusable automation components and practical examples.

```text
Ansible/
├── .github/
│   └── workflows/
├── inventory/
│   ├── hosts.example.yml
│   └── group_vars/
├── playbooks/
├── roles/
├── scripts/
├── docs/
└── README.md
```

**Workflows:** GitHub Actions workflows for initiating and coordinating infrastructure automation.

**Inventory:** Example host and group configurations demonstrating Ansible inventory organization.

**Playbooks:** Automation entry points for provisioning, configuring, and maintaining infrastructure.

**Roles:** Reusable components for operating system configuration, service deployment, and other administrative tasks.

**Scripts:** Supporting PowerShell and shell scripts used throughout the automation workflows.

**Documentation:** Technical walkthroughs, architecture explanations, implementation notes, and lessons learned.

## Automation Projects

### Virtual Machine Provisioning

Automating the creation and initial configuration of virtual machines using Proxmox VE, Cloud-Init, PowerShell, and Ansible.

The workflow demonstrates how individual infrastructure tasks can be combined into a repeatable provisioning process.

### Configuration Management

Using Ansible roles, inventories, and variables to apply consistent configurations across multiple Linux hosts.

The examples explore reusable role design, configuration management, privilege escalation, and host-specific customization.

### Container Infrastructure

Automating Docker installation and host preparation, including the deployment and configuration of supporting container management services.

### Security Automation

Using Ansible to deploy and configure security monitoring components, manage sensitive configuration variables, and validate service installation.

### GitHub Actions Integration

Using manually triggered GitHub Actions workflows to initiate infrastructure automation and coordinate execution across multiple tools.

The examples demonstrate workflow inputs, validation, automation execution, and integration with self-hosted infrastructure.

## Getting Started

The examples in this repository are intended to be adapted rather than deployed unchanged.

Each project may have its own prerequisites, configuration variables, dependencies, and deployment instructions.

Start by reviewing the relevant playbook, role, or workflow documentation before configuring it for your environment.

Example inventory files and configuration templates are provided where applicable.

## Security and Configuration

This repository contains generalized examples intended for public reference.

Environment-specific information, including actual infrastructure addresses, credentials, internal DNS records, and operational inventory configurations, is intentionally excluded.

Examples that require authentication use configurable variables or references to external secret-management mechanisms.

Users should review and configure all deployment parameters, credentials, network settings, and permissions before executing infrastructure automation in their own environments.

## Related Projects

**[Homelab](https://github.com/AshtonWard/Homelab)**

My public homelab documentation and technical portfolio, covering infrastructure design, networking, virtualization, security, and self-hosted services.

**[Project Planning](https://github.com/AshtonWard/.github)**

Centralized issue tracking, research, planned improvements, and development activities across my repositories.

## About This Repository

This is an ongoing personal project focused on developing practical infrastructure engineering skills through hands-on experimentation.

The examples reflect approaches I've explored while building and maintaining my homelab. They may evolve as I learn new technologies, improve existing workflows, and discover better ways to approach infrastructure automation.
