OK="CONFIG OK"
echo -n "Checking config env variables... "
[ -z "$OS_IDENTITY_API_VERSION" ] && { echo "ERROR: OS_IDENTITY_API_VERSION Empty" ; unset OK; }
[ -z "$WORKER_FLAVOR_NAME" ] && { echo "ERROR: WORKER_FLAVOR_NAME Empty" ; unset OK; }
[ -z "$MASTER_FLAVOR_NAME" ] && { echo "ERROR: MASTER_FLAVOR_NAME Empty" ; unset OK; }
[ -z "$IMAGE_NAME" ] && { echo "ERROR: IMAGE_NAME Empty" ; unset OK; }
[ -z "$SECURITY_GROUP_NAME" ] && { echo "ERROR: SECURITY_GROUP_NAME Empty" ; unset OK; }
[ -z "$KEYPAIR_NAME" ] && { echo "ERROR: KEYPAIR_NAME Empty" ; unset OK; }
[ -z "$PROJECT_NAME" ] && { echo "ERROR: PROJECT_NAME Empty" ; unset OK; }
[ -z "$NETWORK_NAME" ] && { echo "ERROR: NETWORK_NAME Empty" ; unset OK; }
[ -z "$CLUSTER_NAME" ] && { echo "ERROR: CLUSTER_NAME Empty" ; unset OK; }
[ -z "$WORKERS" ] && { echo "ERROR: WORKERS Empty" ; unset OK; }
[ ! -f ~/.ssh/$KEYPAIR_NAME ] && { echo "ERROR: ~/.ssh/$KEYPAIR_NAME does not exist" ; unset OK; }
[ -z "$OK" ] && { echo "FATAL: Config problem" ; exit 1; }
echo $OK
unset OK

cat << EOF
Config for nodes in CLUSTER_NAME $CLUSTER_NAME:
  WORKER_FLAVOR_NAME $WORKER_FLAVOR_NAME
  MASTER_FLAVOR_NAME $MASTER_FLAVOR_NAME
  IMAGE_NAME $IMAGE_NAME
Openstack parameters:
  SECURITY_GROUP_NAME $SECURITY_GROUP_NAME
  PROJECT_NAME $PROJECT_NAME
  KEYPAIR_NAME $KEYPAIR_NAME
  NETWORK_NAME $NETWORK_NAME
Nodes names:
EOF

## declare an array variable
read -ra suffixes <<< "master $WORKERS"

## now loop through the above array
for suffix in "${suffixes[@]}"
do
  SERVER_NAME="$CLUSTER_NAME"-"$suffix"
  echo "  $SERVER_NAME"
done
