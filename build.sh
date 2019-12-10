# stop on all errors
set -e
# validate config
./config_check.sh
# form the instances
./openstack_build.sh
# find the fixed IP addresses, write to server_map
./verify_connections.sh
# build kubernetes
./k8_setup.sh
