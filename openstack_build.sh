OK="CONFIG OK"
echo -n "Checking config env variables... "
[ -z "$OS_IDENTITY_API_VERSION" ] && { echo "ERROR: OS_IDENTITY_API_VERSION Empty" ; unset OK; }
[ -z "$FLAVOR_NAME" ] && { echo "ERROR: FLAVOR_NAME Empty" ; unset OK; }
[ -z "$IMAGE_NAME" ] && { echo "ERROR: IMAGE_NAME Empty" ; unset OK; }
[ -z "$SECURITY_GROUP_NAME" ] && { echo "ERROR: SECURITY_GROUP_NAME Empty" ; unset OK; }
[ -z "$KEYPAIR_NAME" ] && { echo "ERROR: KEYPAIR_NAME Empty" ; unset OK; }
[ -z "$PROJECT_NAME" ] && { echo "ERROR: PROJECT_NAME Empty" ; unset OK; }
[ -z "$NETWORK_NAME" ] && { echo "ERROR: NETWORK_NAME Empty" ; unset OK; }
[ -z "$CLUSTER_NAME" ] && { echo "ERROR: CLUSTER_NAME Empty" ; unset OK; }
[ -z "$WORKERS" ] && { echo "ERROR: WORKERS Empty" ; unset OK; }
[ -z "$OK" ] && { echo "FATAL: Config problem" ; exit 1; }
echo $OK
unset OK


FLAVOR_ID=`openstack flavor list --format json  | jq  -rc ".[] | select (.Name == \"$FLAVOR_NAME\") | .ID"`
echo FLAVOR $FLAVOR_NAME=$FLAVOR_ID

IMAGE_ID=`openstack image list --format json  |  jq  -rc ".[] | select (.Name == \"$IMAGE_NAME\") | .ID"`
echo IMAGE $IMAGE_NAME=$IMAGE_ID

SECURITY_GROUP_ID=`openstack security group list --project $PROJECT_NAME --format json  |  jq  -rc ".[] | select (.Name == \"$SECURITY_GROUP_NAME\") | .ID"`
echo SECURITY_GROUP $SECURITY_GROUP_NAME=$SECURITY_GROUP_ID

KEYPAIR_ID=`openstack keypair list --format json  |  jq  -rc ".[] | select (.Name == \"$KEYPAIR_NAME\") | .Fingerprint"`
echo KEYPAIR $KEYPAIR_NAME=$KEYPAIR_ID

NETWORK_ID=`openstack network list --format json  |  jq  -rc ".[] | select (.Name == \"$NETWORK_NAME\") | .ID"`
echo NETWORK $NETWORK_NAME=$NETWORK_ID

OK="OpenStack lookup OK"
echo -n "Checking openstack variables... "
[ -z "$FLAVOR_ID" ] && { echo "ERROR: FLAVOR_ID Empty" ; unset OK; }
[ -z "$IMAGE_ID" ] && { echo "ERROR: IMAGE_ID Empty" ; unset OK; }
[ -z "$SECURITY_GROUP_ID" ] && { echo "ERROR: SECURITY_GROUP_ID Empty" ; unset OK; }
[ -z "$KEYPAIR_ID" ] && { echo "ERROR: KEYPAIR_ID Empty" ; unset OK; }
[ -z "$NETWORK_ID" ] && { echo "ERROR: NETWORK_ID Empty" ; unset OK; }

[ -z "$OK" ] && { echo "FATAL: OpenStack lookup problem" ; exit 1; }
echo $OK
unset OK

## declare an array variable
read -ra suffixes <<< "master $WORKERS"

## now loop through the above array
for suffix in "${suffixes[@]}"
do
  SERVER_NAME="$CLUSTER_NAME"-"$suffix"
  OK="Forming $SERVER_NAME"

  SERVER_NAME_COUNT=`openstack server list  --name  $SERVER_NAME --format json | jq '. | length '`
  [ $SERVER_NAME_COUNT -ne 0 ] && { echo "ERROR: SERVER_NAME_COUNT not 0 was " $SERVER_NAME_COUNT $SERVER_NAME " exists?" ; unset OK; }

  # FLOATING_IP_ID=`openstack floating ip list --project $PROJECT_NAME --format json  |  jq  -rc "[.[] | select (.Port == null) | .[\"Floating IP Address\"] ][0] "`
  # echo FLOATING_IP_ID=$FLOATING_IP_ID
  # [ -z "$FLOATING_IP_ID" ] && { echo "ERROR: FLOATING_IP_ID Empty" ; unset OK; }

  [ -z "$OK" ] && { echo "FATAL: OpenStack lookup problem" ; exit 1; }
  echo $OK

  openstack server create \
    --flavor $FLAVOR_ID \
    --image $IMAGE_ID \
    --security-group $SECURITY_GROUP_ID \
    --key-name $KEYPAIR_NAME \
    --network $NETWORK_ID \
    --wait \
    $SERVER_NAME || { echo 'FATAL: openstack server create failed ' $SERVER_NAME  ; exit 1; }

  # openstack server add floating ip $SERVER_NAME $FLOATING_IP_ID || { echo 'FATAL: openstack server add floating ip failed ' $SERVER_NAME ; exit 1; }

done
