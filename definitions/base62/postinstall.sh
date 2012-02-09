#http://chrisadams.me.uk/2010/05/10/setting-up-a-centos-base-box-for-development-and-testing-with-vagrant/

date > /etc/vagrant_box_build_time

yum -y erase wireless-tools gtk2 libX11 hicolor-icon-theme avahi freetype bitstream-vera-fonts
yum -y clean all

wget "http://dl.dropbox.com/u/28598905/centos6/ruby19-1.9.3p0-4.el6.x86_64.rpm"
wget "http://dl.dropbox.com/u/28598905/centos6/ruby19-devel-1.9.3p0-4.el6.x86_64.rpm"

rpm -i ruby19-1.9.3p0-4.el6.x86_64.rpm
rm ruby19-1.9.3p0-4.el6.x86_64.rpm

rpm -i ruby19-devel-1.9.3p0-4.el6.x86_64.rpm
rm ruby19-devel-1.9.3p0-4.el6.x86_64.rpm

echo 'gem: --no-ri --no-rdoc' > ~/.gemrc
gem install chef
gem install bundler

# Disable services
chkconfig auditd off
chkconfig ip6tables off
chkconfig iptables off
chkconfig postfix off
chkconfig psacct off

# Installing vagrant keys
mkdir /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
cd /home/vagrant/.ssh
wget --no-check-certificate 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub' -O authorized_keys
chown -R vagrant /home/vagrant/.ssh

# Installing the virtualbox guest additions
VBOX_VERSION=$(cat /home/vagrant/.vbox_version)
cd /tmp
wget http://download.virtualbox.org/virtualbox/$VBOX_VERSION/VBoxGuestAdditions_$VBOX_VERSION.iso
mount -o loop VBoxGuestAdditions_$VBOX_VERSION.iso /mnt
sh /mnt/VBoxLinuxAdditions.run
umount /mnt
rm VBoxGuestAdditions_$VBOX_VERSION.iso

sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

# Remove painful udev rules
ln -sf /dev/null /lib/udev/rules.d/75-persistent-net-generator.rules
rm -f /etc/udev/rules.d/70-persistent-net.rules

# On startup, remove HWADDR from the eth0 interface.
cp -f /etc/sysconfig/network-scripts/ifcfg-eth0 /tmp/eth0
sed "/^HWADDR/d" /tmp/eth0 > /etc/sysconfig/network-scripts/ifcfg-eth0
sed -e "s/dhcp/none/;s/eth0/eth1/" /etc/sysconfig/network-scripts/ifcfg-eth0 > /etc/sysconfig/network-scripts/ifcfg-eth1

# Prevent way too much CPU usage in VirtualBox by disabling APIC.
sed -e 's/\tkernel.*/& noapic/' /boot/grub/grub.conf > /tmp/new_grub.conf
mv /boot/grub/grub.conf /boot/grub/grub.conf.bak
mv /tmp/new_grub.conf /boot/grub/grub.conf

dd if=/dev/zero of=/tmp/clean || rm /tmp/clean

exit
