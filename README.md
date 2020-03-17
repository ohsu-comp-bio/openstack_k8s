# openstack_k8s


## pre-requisites

* familiarity with basic open stack commands
* open stack privileges to create servers
* open stack "RC" file



## process

### setup a machine to configure and start your cluster

* create a openstack instance
* install openstack cli
```
# apt install python-dev python-pip
# pip install python-openstackclient
```
* install jq utility
```
# apt install jq
```

* download "RC" file

![image](https://user-images.githubusercontent.com/47808/70567718-57566b80-1b4b-11ea-9c1b-e6b2086e9cdb.png)


* source your "RC" file and validate access

```
$ . ../admin-openrc
Please enter your OpenStack Password:
$ openstack user show walsbr
+-----------+----------------------------------+
| Field     | Value                            |
+-----------+----------------------------------+
| domain_id | default                          |
| email     | walsbr@XXXX.YYY                  |
| enabled   | True                             |
| id        | XXXX7359205a4e4cb869a91b8e02ee18 |
| name      | walsbr                           |
+-----------+----------------------------------+

```


### configure the cluster

* setup

```
$ cat .env
# openstack flavor to use for master and workers
export FLAVOR_NAME=m1.medium

# name of image for master and workers
export IMAGE_NAME='ubuntu_18.04_k8'
# name of image base for image build
export IMAGE_BASE='ubuntu_18.04'

# note: resulting cluster will be CLUSTER_NAME-master + CLUSTER_NAME-WORKERx ...
# name of cluster
export CLUSTER_NAME=k8test
# must be a space separated list of workers
export WORKERS="worker1 worker2"
export NETWORK_NAME="ccc_network"
export OS_IDENTITY_API_VERSION=3


# openstack parameters for master and workers
export SECURITY_GROUP_NAME=default
export PROJECT_NAME=CCC
export KEYPAIR_NAME='k8test'
```

* setup validation

```
$ ./config_check.sh
Checking config env variables... CONFIG OK
Config for nodes in CLUSTER_NAME k8test:
  FLAVOR_NAME m1.medium
  IMAGE_NAME ubuntu_18.04_k8
Openstack parameters:
  SECURITY_GROUP_NAME default
  PROJECT_NAME CCC
  KEYPAIR_NAME k8test
  NETWORK_NAME ccc_network
Nodes names:
  k8test-master
  k8test-worker1
  k8test-worker2
```

### one step deploy
* validate config
* form the instances
* find the fixed IP addresses, write to server_map
* build kubernetes
```
build.sh
```

### troubleshooting / development
#### build the cluster

* deploy
  * `Note:` this step will error if the cluster already exists (see __clean__) `ERROR: SERVER_NAME_COUNT not 0 was  1 k8test-master  exists?`

```
$ ./openstack_build.sh

Checking config env variables... CONFIG OK
...
Checking config against openstack... OpenStack lookup OK
...
Contacting all hosts...
k8test-worker1 10.50.50.98
k8test-worker2 10.50.50.99
k8test-master 10.50.50.97
...
Checking workers...
Setting up kubeadm on k8test-worker1 ...OK
OK
Setting up kubeadm on k8test-worker2 ...OK
OK

```

* find the fixed IP addresses, write to server_map

```
./verify_connections.sh
```

* reference

  * `server_map`: list of node names and fixed ip addresses
  * `kubeadm.out`: master node setup, includes **secure join command**


* check

```
$ ./k8_status.sh
NAME             STATUS   ROLES    AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE           KERNEL-VERSION      CONTAINER-RUNTIME
k8test-master    Ready    master   8m20s   v1.16.3   10.50.50.97   <none>        Ubuntu 18.04 LTS   4.15.0-72-generic   docker://18.6.2
k8test-worker1   Ready    <none>   7m43s   v1.16.3   10.50.50.98   <none>        Ubuntu 18.04 LTS   4.15.0-72-generic   docker://18.6.2
k8test-worker2   Ready    <none>   7m24s   v1.16.3   10.50.50.99   <none>        Ubuntu 18.04 LTS   4.15.0-72-generic   docker://18.6.2
```


* clean

```
$ ./clean.sh
...
Deleting k8test-master
Deleting k8test-worker1
Deleting k8test-worker2
```
