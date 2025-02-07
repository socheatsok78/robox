#!/bin/bash -ux

# Create the vagrant user account.
/usr/sbin/useradd vagrant

# Enable exit/failure on error.
set -eux

# Gentoo builds don't include polkit but they may in the future.
if [ -d /etc/polkit-1/rules.d/ ]; then
cat <<-EOF > /etc/polkit-1/rules.d/49-vagrant.rules
polkit.addRule(function(action, subject) {
    if (subject.isInGroup("vagrant")) {
        return polkit.Result.YES;
    }
});
EOF
chmod 0440 /etc/polkit-1/rules.d/49-vagrant.rules
fi

# Allow us to continue using the default password by tweaking the security rules.
if [ -f /etc/security/passwdqc.conf ]; then
#  sed -i 's/match=.*/match=0/g' /etc/security/passwdqc.conf
#  sed -i 's/min=.*/min=1,1,1,1,1/g' /etc/security/passwdqc.conf
  sed -i 's/enforce=.*/enforce=users/g' /etc/security/passwdqc.conf
#  sed -i 's/similar=.*/similar=permit/g' /etc/security/passwdqc.conf
fi

printf "vagrant\nvagrant\n" | passwd vagrant
cat <<-EOF > /etc/sudoers.d/vagrant
Defaults:vagrant !fqdn
Defaults:vagrant !requiretty
vagrant ALL=(ALL) NOPASSWD: ALL
EOF
chmod 0440 /etc/sudoers.d/vagrant

# Create the vagrant user ssh directory.
mkdir -pm 700 /home/vagrant/.ssh

# Create an authorized keys file and insert the insecure public vagrant key.
cat <<-EOF > /home/vagrant/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key
EOF

# Ensure the permissions are set correct to avoid OpenSSH complaints.
chmod 0600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh

# Mark the vagrant box build time.
date --utc > /etc/vagrant_box_build_time
