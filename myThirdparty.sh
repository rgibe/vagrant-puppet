#!/usr/bin/env bash

# Thirdparty Modules to Install (my module depend on)
# I don't use r10k anymore (this way is simple and straightforward)

echo "server: Installing needed Puppet Modules ..."
puppet module install puppetlabs-apt &> /dev/null
puppet module install puppetlabs-apache &> /dev/null
puppet module install puppetlabs-tomcat &> /dev/null
echo  "$(puppet module list 2>/dev/null)"

