
OK="CONFIG OK"
# echo -n "Checking config env variables... "
[ ! -f server_map ] && { echo "ERROR: server_map does not exist" ; unset OK; }
[ -z "$CLUSTER_NAME" ] && { echo "ERROR: CLUSTER_NAME Empty" ; unset OK; }
[ -z "$WORKERS" ] && { echo "ERROR: WORKERS Empty" ; unset OK; }
[ -z "$OK" ] && { echo "FATAL: Config problem" ; exit 1; }

# echo $OK
unset OK


# read server_map file into SERVER_MAP hash
declare -A SERVER_MAP
while IFS= read -r line
do
   ## take some action on $line
  read -ra L <<< "$line" # str is read into an array as tokens separated
  SERVER_MAP[${L[0]}]=${L[1]}
done < "server_map"


SERVER_NAME="$CLUSTER_NAME"-master
KUBECTL="sudo kubectl --kubeconfig /etc/kubernetes/admin.conf "
DEPLOY_DASHBOARD="apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta6/aio/deploy/recommended.yaml"
SSH="ssh -i ~/.ssh/$KEYPAIR_NAME ubuntu@${SERVER_MAP[$SERVER_NAME]}"

PROXY_DASHBOARD="proxy --help"

# KUBEADM_RESULTS=$($SSH $KUBECTL $DEPLOY_DASHBOARD)
# echo "$KUBEADM_RESULTS"

KUBEADM_RESULTS=$($SSH $KUBECTL $PROXY_DASHBOARD)
echo "$KUBEADM_RESULTS"
