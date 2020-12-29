#! /usr/bin/env bash

# Script to install NixOS from the Hetzner Cloud NixOS bootable ISO image.
# (tested with Hetzner's `NixOS 20.03 (amd64/minimal)` ISO image).
#
# This script wipes the disk of the server!
#
# Instructions:
#
# 1. Mount the above mentioned ISO image from the Hetzner Cloud GUI
#    and reboot the server into it; do not run the default system (e.g. Ubuntu).
# 2. To be able to SSH straight in (recommended), you must replace hardcoded pubkey
#    further down in the section labelled "Replace this by your SSH pubkey" by you own,
#    and host the modified script way under a URL of your choosing
#    (e.g. gist.github.com with git.io as URL shortener service).
# 3. Run on the server:
#
#       # Replace this URL by your own that has your pubkey in
#       curl -L https://raw.githubusercontent.com/nix-community/nixos-install-scripts/master/hosters/hetzner-cloud/nixos-install-hetzner-cloud.sh | sudo bash
# 4. Unmount the ISO image from the Hetzner Cloud GUI.
# 5. Reboot.
#
# To run it from the Hetzner Cloud web terminal without typing it down,
# you can either select it and then middle-click onto the web terminal, (that pastes
# to it), or use `xdotool` (you have e.g. 3 seconds to focus the window):
#
#     sleep 3 && xdotool type --delay 50 'curl YOUR_URL_HERE | sudo bash'
#
# (In the xdotool invocation you may have to replace chars so that
# the right chars appear on the US-English keyboard.)
#
# If you do not replace the pubkey, you'll be running with my pubkey, but you can
# change it afterwards by logging in via the Hetzner Cloud web terminal as `root`
# with empty password.

set -e

# Hetzner Cloud OS images grow the root partition to the size of the local
# disk on first boot. In case the NixOS live ISO is booted immediately on
# first powerup, that does not happen. Thus we need to grow the partition
# by deleting and re-creating it.
sgdisk -d 1 /dev/sda
sgdisk -N 1 /dev/sda
partprobe /dev/sda

mkfs.ext4 -F /dev/sda1 # wipes all data!

mount /dev/sda1 /mnt

nixos-generate-config --root /mnt

# Delete trailing `}` from `configuration.nix` so that we can append more to it.
sed -i -E 's:^\}\s*$::g' /mnt/etc/nixos/configuration.nix

# Extend/override default `configuration.nix`:
echo '
  boot.loader.grub.devices = [ "/dev/sda" ];

  # Initial empty root password for easy login:
  users.users.root.initialHashedPassword = "";
  services.openssh.permitRootLogin = "prohibit-password";

  services.openssh.enable = true;

  users.users.root.openssh.authorizedKeys.keys = [
    # Replace this by your SSH pubkey!
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDd9nhI7n8OLdP6oipqRD1WB2pN1N8Mv1PH0HWVG/DXCslV8xKZhT7QD8oB1KeSbYHNyC1BZuwCOH6IlLjAV89aulwRuLJ/SETtM2VI//KGZeW9lsX4/L313oQNKGC8giLuOa5kSoM9lcLIUBWz0+iXrMtSMpGwIt45sqOmSl+dzr0Aoto0GNukp3ssbktU8Nuls37nI/baFTIRCLdD+yMggtAJNtxkdXqqMCu3Gl10IgCjTf3VdEBX3+x5DDe+P7cOmni/Lf34kCOUjweVCitEnd3n8NxQguPC4jW7BjAqBgaHfKmq7mxJHHwHxRXkdESCmhtuz/Tzi4VSuixFVcJJ openpgp:0x88FB98EA"
  ];
}
' >> /mnt/etc/nixos/configuration.nix

nixos-install --no-root-passwd

reboot
