# stop on all errors
set -e
# validate config
./config_check.sh
# delete existing nodes
./openstack_clean.sh
