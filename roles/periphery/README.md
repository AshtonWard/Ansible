# Komodo Periphery role

Checks for the Periphery service, downloads and runs the upstream Python installer when the service is missing, then enables and starts it. Supply `komodo_core_address` and a private `komodo_onboarding_key`. Installation arguments are protected by `no_log`.

The installer follows the upstream branch rather than an immutable revision. Review it before deployment. An existing service skips registration; the role does not reconcile changed registration settings automatically. `tests/test.yml` installs on localhost and is an operational example, not a safe unit test.
