
## declare an array variable
read -ra suffixes <<< "master $WORKERS"

## now loop through the above array, create hash to lookup addresses
echo -n "Looking up all fixed ip addresses..."
OK=OK
declare -A SERVER_MAP
for suffix in "${suffixes[@]}"
do
  SERVER_NAME="$CLUSTER_NAME"-"$suffix"
  SERVER_FIXED_IP=`openstack server show $SERVER_NAME --format=json | jq  -rc '.addresses |= split("=") | .addresses[1]'`
  SERVER_MAP[$SERVER_NAME]=$SERVER_FIXED_IP
done
[ -z "$OK" ] && { echo "FATAL: Could find fixed address for all hosts" ; exit 1; }
echo $OK
unset OK

# see https://blog.sourcerer.io/a-kubernetes-quick-start-for-people-who-know-just-enough-about-docker-to-get-by-71c5933b4633
echo "Contacting all hosts..."
OK=OK
rm server_map > /dev/null
for SERVER_NAME in "${!SERVER_MAP[@]}"
do
  # loop until we can contact them
  while :
  do
    ssh $SSH_OPTS -i ~/.ssh/$KEYPAIR_NAME ubuntu@${SERVER_MAP[$SERVER_NAME]} 'pwd' > /tmp/contact-check
    if [ $? -eq 0 ]; then
        echo $SERVER_NAME ${SERVER_MAP[$SERVER_NAME]} >> server_map
        break
    else
        echo Attempted contact to $SERVER_NAME. FAILED, sleeping 10 secs
        sleep 10
    fi
  done
done
[ -z "$OK" ] && { echo "FATAL: Could not contact all hosts" ; exit 1; }
echo $OK
unset OK
rm /tmp/contact-check
cat server_map
