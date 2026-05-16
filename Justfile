default:
  just --list
run-test-vm:
  #!/usr/bin/env bash
  VM_PATH=$(nix build .\#nixosConfigurations.test.config.system.build.vm --impure --print-out-paths)
  $VM_PATH/bin/run-nixos-vm
