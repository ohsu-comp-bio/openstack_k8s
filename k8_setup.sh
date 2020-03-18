
OK="CONFIG OK"
echo -n "Checking config env variables... "
[ ! -f server_map ] && { echo "ERROR: server_map does not exist" ; unset OK; }
[ -z "$OK" ] && { echo "FATAL: Config problem" ; exit 1; }
[ -z "$CLUSTER_NAME" ] && { echo "ERROR: CLUSTER_NAME Empty" ; unset OK; }
[ -z "$WORKERS" ] && { echo "ERROR: WORKERS Empty" ; unset OK; }
[ ! -f ~/.ssh/$KEYPAIR_NAME ] && { echo "ERROR: ~/.ssh/$KEYPAIR_NAME does not exist" ; unset OK; }
echo $OK
unset OK

# read server_map file into SERVER_MAP hash
declare -A SERVER_MAP
while IFS= read -r line
do
   ## take some action on $line
  read -ra L <<< "$line" # str is read into an array as tokens separated
  SERVER_MAP[${L[0]}]=${L[1]}
done < "server_map"

for SERVER_NAME in "${!SERVER_MAP[@]}"
do
    echo $SERVER_NAME ${SERVER_MAP[$SERVER_NAME]}
done

echo -n "Checking master..."
if [ ! -f kubeadm.out ]; then
  echo -n "Setting up kubeadm on master..."
  OK=OK
  SERVER_NAME="$CLUSTER_NAME"-master
  KUBEADM_RESULTS=$(ssh ${SSH_OPTS} -i ~/.ssh/$KEYPAIR_NAME ubuntu@${SERVER_MAP[$SERVER_NAME]} 'sudo kubeadm init --apiserver-advertise-address '${SERVER_MAP[$SERVER_NAME]})
  if [ $? -eq 0 ]; then
      echo "OK"
  else
      echo kubeadm $SERVER_NAME FAIL
      unset OK
  fi
  # the double-quoted version of the variable (echo "$RESULT") preserves internal spacing of the value exactly as it is represented in the variable — newlines, tabs, multiple blanks and all
  echo "$KUBEADM_RESULTS" > kubeadm.out
  [ -z "$OK" ] && { echo "FATAL: kubeadm failed see kubeadm.out" ; exit 1; }
  echo $OK
  unset OK

  echo  "Setting up kubernetes bridge"
  cat << EOF | KUBEBRIDGE_RESULTS=$(ssh ${SSH_OPTS} -i ~/.ssh/$KEYPAIR_NAME ubuntu@${SERVER_MAP[$SERVER_NAME]})
sudo sysctl net.bridge.bridge-nf-call-iptables=1 ;
export kubever=\$(sudo kubectl --kubeconfig /etc/kubernetes/admin.conf version | base64 | tr -d '\n') ;
sudo  kubectl  --kubeconfig /etc/kubernetes/admin.conf  apply -f "https://cloud.weave.works/k8s/net?k8s-version=\$kubever" ;
EOF
  if [ $? -eq 0 ]; then
      echo "OK"
  else
      echo bridge setup $SERVER_NAME FAIL
      echo $KUBEBRIDGE_RESULTS
      unset OK
  fi

  echo  "Setting up kubernetes proxy"
  OK=OK
  # KUBEPROXY_RESULTS=$(ssh ${SSH_OPTS} -t -i ~/.ssh/$KEYPAIR_NAME ubuntu@${SERVER_MAP[$SERVER_NAME]} 'sudo kubectl --kubeconfig /etc/kubernetes/admin.conf proxy --port=8080 &')
  cat << EOF | KUBEPROXY_RESULTS=$(ssh ${SSH_OPTS} -t -i ~/.ssh/$KEYPAIR_NAME ubuntu@${SERVER_MAP[$SERVER_NAME]})
sudo nohup kubectl --kubeconfig /etc/kubernetes/admin.conf proxy --port=8080 > proxy.out 2 >proxy.err < /dev/null &
sudo chown -R  ubuntu:ubuntu /home/ubuntu/.kube
sudo chown ubuntu:ubuntu /etc/kubernetes/admin.conf
kubectl get pods
EOF
  if [ $? -eq 0 ]; then
      echo "OK"
  else
      echo kubeadm $SERVER_NAME FAIL
      echo $KUBEPROXY_RESULTS
      unset OK
  fi
  # the double-quoted version of the variable (echo "$RESULT") preserves internal spacing of the value exactly as it is represented in the variable — newlines, tabs, multiple blanks and all
  echo "$KUBEPROXY_RESULTS" > kubectl-proxy.out



  [ -z "$OK" ] && { echo "FATAL: kubectl failed see kubectl-proxy.out" ; exit 1; }
  echo $OK
  unset OK

  

  echo "DONE"

else
  echo 'kubeadm.out exists; master already setup'
fi




echo "Checking workers..."
read -ra suffixes <<< "$WORKERS"
# get the file created from master setup above, it contains "kubeadm join"
# remove the line continuation and new line
JOIN=$(tail -2 kubeadm.out | sed s/\\\\// | tr -d \\n)
for suffix in "${suffixes[@]}"
do
  SERVER_NAME="$CLUSTER_NAME"-"$suffix"
  if [ ! -f kubeadm-$SERVER_NAME.out ]; then
    echo -n "Setting up kubeadm on $SERVER_NAME ..."
    OK=OK
    KUBEADM_RESULTS=$(ssh ${SSH_OPTS} -i ~/.ssh/$KEYPAIR_NAME ubuntu@${SERVER_MAP[$SERVER_NAME]} 'sudo '$JOIN)
    if [ $? -eq 0 ]; then
        echo "OK"
    else
        echo kubeadm $SERVER_NAME FAIL
        unset OK
    fi

    # the double-quoted version of the variable (echo "$RESULT") preserves internal spacing of the value exactly as it is represented in the variable — newlines, tabs, multiple blanks and all
    echo "$KUBEADM_RESULTS" > kubeadm-$SERVER_NAME.out
    [ -z "$OK" ] && { echo "FATAL: kubeadm failed see  kubeadm-$SERVER_NAME.out" ; exit 1; }
    echo $OK
    unset OK
  else
    echo "Kubeadm on $SERVER_NAME already exists."
  fi
done
