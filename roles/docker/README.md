# Docker role

Installs Docker from the Ubuntu Docker repository after removing conflicting packages. `tasks/main.yml` imports `docker_install.yml`. Review platform and architecture assumptions before use.

The role does not install Periphery. `playbooks/docker.yml` combines the Docker and Periphery roles; use `playbooks/install_periphery.yml` for Periphery alone. That combined playbook requires `komodo_onboarding_key` from a private, untracked variable source.
