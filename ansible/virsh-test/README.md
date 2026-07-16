# Libvirt test machines

`create-vms.sh` creates one 15 GiB qcow2 VM per supported installer image: Arch, AlmaLinux 9, Void, and Ubuntu 24.04. It discovers storage through `virsh` without starting any pool. It first uses an active `pgza-test` pool (`images` and `isos` subdirectories), otherwise active `images` and `isos` pools directly. Only when neither layout exists does it use another active pool and create `pgza-test/images` and `pgza-test/isos` below its target. Set `TEST_STORAGE_POOL`, `IMAGE_STORAGE_POOL`, `ISO_STORAGE_POOL`, `STORAGE_POOL`, `ISO_DIR`, or `IMAGE_DIR` to override this. The guests attach to the isolated `pgza-test` NAT network. The host is reachable from guests at `192.168.251.1`; guests receive fixed addresses listed in `inventory.yml`.

Before making changes, the script checks that `virsh`, `virt-install`, `qemu-img`, and `curl` are installed, verifies it can connect to the selected libvirt URI, and checks that the chosen storage pool exists.

## Create VMs

```bash
cd ansible/virsh-test
sudo ./create-vms.sh
```

Use `sudo ./create-vms.sh arch` to create or download a single target. URLs, disk size, memory, vCPU count, storage paths, and libvirt URI can be overridden with environment variables, for example:

```bash
sudo DISK_SIZE_GIB=20 MEMORY_MIB=6144 ./create-vms.sh ubuntu
```

The script intentionally never deletes or replaces an existing ISO, disk, network, or VM. It launches each distribution's native installer. Connect with `virsh console pgza-arch` (or virt-manager) and complete the one-time installation before running Ansible. Create an `ansible` user with SSH public-key login and passwordless `sudo`, then configure networking with its address from `inventory.yml`. After installation, eject the ISO with:

```bash
sudo virsh change-media pgza-arch sda --eject --config
sudo virsh reboot pgza-arch
```

The installer media URLs are official distribution endpoints as of July 2026. Arch's `latest` link is intentionally rolling; set `ARCH_ISO_URL` to a dated image and verify its signature when repeatability is required.

## Run Ansible

```bash
ANSIBLE_PRIVATE_KEY="$HOME/.ssh/pgza_test_ed25519" ./run-ansible.sh
```

Pass normal playbook options after the script, for example `./run-ansible.sh --limit pgza-void`. The runner uses `inventory.yml` and runs `ansible/site.yml` only for the Linux test group.
