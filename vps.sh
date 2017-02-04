#!/usr/bin/env bash
#
# Creates basic Vagrant/Puppet Setup (vps.sh)
# Assumes you have vagrant installed already
#
# Adapted from https://gist.github.com/mmarseglia/6d4cfe2f0c7e6f582323
#
# Requires two arguments: 
#   - name of the directory to store Vagrant config
#   - new module to test/develope (git clone URL)

if [ -z "$1" ]; then
  echo "Usage: $0 project_dir_name git_clone_url"
  exit 1
fi

if [ -z "$2" ]; then
  echo "Usage: $0 project_dir_name git_clone_url"
  exit 1
fi

# Variables
PROJECT=$1
#echo $PROJECT

REPO_GIT=$2
#echo $REPO_GIT
MODULE=$(echo $REPO_GIT | rev | cut -d '/' -f1 | rev | cut -d '.' -f1 | cut -d '-' -f2)
echo $MODULE

# Can't continue without git
which git &>/dev/null || (echo "can't find git"; exit 1)

# Make directory structure
##########################

mkdir -p $PROJECT/{manifests,puppet/modules,puppet/hiera}

# default.pp used by Puppet to 
# assign roles/modules to server
################################

touch $PROJECT/manifests/default.pp
cat > $PROJECT/manifests/default.pp << EOF
hiera_include('classes')
EOF

# hiera may be empty but we want to keep it around

touch $PROJECT/puppet/hiera/common.yaml
cat > $PROJECT/puppet/hiera/common.yaml << EOF
---
classes:
  - $MODULE
EOF

# Add your OWN Module
git clone $REPO_GIT $PROJECT/puppet/modules/$MODULE

# or just copy it under the proper PATH 
# cp -r ../puppet-modapp1 $PROJECT/puppet/modules/modapp1

# Just in case you need it 
cp ./puppet.conf $PROJECT/
cp ./myThirdparty.sh $PROJECT/

# create default hiera.yaml
cat > $PROJECT/hiera.yaml << EOF
:backends:
  - yaml
:hierarchy:
  - "node/%{::fqdn}"
  - 'common'
:yaml:
  :datadir: '/vagrant/puppet/hiera'
EOF

# Create vagrant file
#####################

cat > $PROJECT/Vagrantfile << 'EOF'
# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

# list all servers to build
servers = [ 'server' ]

# set domain name for servers
domain = 'domain.local'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

        # set box to use
        config.vm.box = "ubuntu/trusty64"

        config.vm.provider "virtualbox" do |v|
                v.customize ["modifyvm", :id, "--natdnsproxy1", "off"]
                v.customize ["modifyvm", :id, "--natdnshostresolver1", "off"]
                v.customize ["modifyvm", :id, "--memory", 1024]
                v.auto_nat_dns_proxy = false
        end

        servers.each do |server|
                config.vm.define server do |server_config|
                        # puppet agent install bootstrap executed by Vagrant with shell provisioner
                        server_config.vm.provision "shell", path: "./puppet-bootstrap/ubuntu.sh"
                        server_config.vm.provision "shell", path: "./myThirdparty.sh"
                       
                        # Just in case you need to work on the module on the VM  
                        $script = <<SCRIPT
                        
                        cd /vagrant
                        cp puppet.conf hiera.yaml /etc/puppet/
                        
SCRIPT
                        server_config.vm.provision "shell", inline: $script

                        # set host name
                        server_config.vm.host_name = server + '.' + domain

                        # service port forwarding 
                        server_config.vm.network :forwarded_port, guest: 80, host: 3080, host_ip: "127.0.0.1"
                        server_config.vm.post_up_message = "The application is available at http://127.0.0.1:3080"

                        # sync hiera config directory with guest
                        server_config.vm.synced_folder  "puppet/hiera", '/tmp/vagrant-hiera'

                        # provision each server with puppet
                        server_config.vm.provision "puppet" do |puppet|
                                puppet.hiera_config_path = 'hiera.yaml'
                                puppet.manifests_path = "manifests"
                                puppet.manifest_file  = "default.pp"
                                puppet.module_path = [ "puppet/modules" ]

                                # lots of output for debugging, noisy!
                                #puppet.options = "--verbose --debug"
                        end
                end
        end
end
EOF

# create a basic README
cat > $PROJECT/README << EOF
$PROJECT Vagrant
`date`
created by `whoami`
EOF

# set up new vagrant directory for git
cd $PROJECT
cat > .gitignore << EOF
.vagrant/
EOF
git init
git add .

# add puppet bootstrap as a submodule
git submodule add https://github.com/hashicorp/puppet-bootstrap


# perform an initial commit
git commit -m "initial commit for $PROJECT"
