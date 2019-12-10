## declare an array variable
read -ra suffixes <<< "master $WORKERS"
## now loop through the above array
for suffix in "${suffixes[@]}"
do
  SERVER_NAME="$CLUSTER_NAME"-"$suffix"
  SERVER_NAME_COUNT=`openstack server list  --name  $SERVER_NAME --format json | jq '. | length '`
  if [ $SERVER_NAME_COUNT -ne 0 ]; then
    echo "Deleting $SERVER_NAME"
    openstack server delete $SERVER_NAME
  else
    echo "$SERVER_NAME does not exist, proceeding."
  fi
done
