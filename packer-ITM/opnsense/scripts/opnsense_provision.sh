#!/bin/sh

# Download the OPNsense bootstrap script
fetch -o opnsense-bootstrap.sh https://raw.githubusercontent.com/opnsense/update/master/src/bootstrap/opnsense-bootstrap.sh.in

# Remove reboot command from bootstrap script
sed -i '' -e '/reboot$/d' opnsense-bootstrap.sh

# Remove pkg unlock command from bootstrap script, which causes an error due to an upstream bug.
# https://github.com/freebsd/pkg/issues/2278
# This won't hurt even with the bug eventually fixed, because we don't have any locked packages.
sed -i '' -e '/pkg unlock/d' opnsense-bootstrap.sh

# Run the OPNsense bootstrap script
sh ./opnsense-bootstrap.sh -r 24.7 -y

# Remove IPv6 configuration from WAN
sed -i '' -e '/<ipaddrv6>dhcp6<\/ipaddrv6>/d' /usr/local/etc/config.xml

# Remove IPv6 configuration from LAN
sed -i '' -e '/<ipaddrv6>track6<\/ipaddrv6>/d' /usr/local/etc/config.xml
sed -i '' -e '/<subnetv6>64<\/subnetv6>/d' /usr/local/etc/config.xml
sed -i '' -e '/<track6-interface>wan<\/track6-interface>/d' /usr/local/etc/config.xml
sed -i '' -e '/<track6-prefix-id>0<\/track6-prefix-id>/d' /usr/local/etc/config.xml

# Enable SSH by default
sed -i '' -e '/<group>admins<\/group>/r /tmp/ssh.xml' /usr/local/etc/config.xml

# Allow SSH on all interfaces
sed -i '' -e '/<filter>/r /tmp/filter.xml' /usr/local/etc/config.xml

# Do not block private networks on WAN
sed -i '' -e '/<blockpriv>1<\/blockpriv>/d' /usr/local/etc/config.xml

# Display helpful message for the user
echo '##############################################################'
echo '#                                                            #'
echo '#  OPNsense provisioning finished - Consider shutting down.  #'
echo '#                                                            #'
echo '##############################################################'