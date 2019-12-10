
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
KUBEADM_RESULTS=$(ssh -i ~/.ssh/$KEYPAIR_NAME ubuntu@${SERVER_MAP[$SERVER_NAME]} 'sudo kubectl --kubeconfig /etc/kubernetes/admin.conf get nodes -o wide')
echo "$KUBEADM_RESULTS"
# KUBEADM_RESULTS=$(ssh -i ~/.ssh/$KEYPAIR_NAME ubuntu@${SERVER_MAP[$SERVER_NAME]} 'sudo kubectl --kubeconfig /etc/kubernetes/admin.conf describe nodes')
# echo "$KUBEADM_RESULTS"
