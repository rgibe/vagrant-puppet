#### Overview

This script creates a Vagrant environment to work with Puppet:
load/test/create/modify module.

You can easily adapt the ```vps.sh``` to handle your specific need.

Assumes you have vagrant installed already.

Prerequisites:
 * git (of course)

#### USAGE

Requires two arguments:
  - name of the directory to store Vagrant config
  - new module to test/develope (git clone URL)

Example:

./vps.sh ~/Desktop/test1 https://gitlab.cineca.it/rgibelli/puppet-modapp1.git

#### CREDITS

Adapted from: https://gist.github.com/mmarseglia/6d4cfe2f0c7e6f582323

#### LICENSE

GPL - http://www.gnu.org/licenses/gpl-3.0.html
