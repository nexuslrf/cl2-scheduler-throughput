#!/bin/bash
function usage() {
    echo -e 'bash run.sh $kubeconfig [$scheduler_name] [$local/kubemark] [$pods_per_node] [$outdir_name] '
    exit 1
}

# Provider setting
PROVIDER='local'
hollow_prefix="hollow-node"

function get-available-nodes() {
    a=0
    while read line
    do
        if [[ `echo $line | grep "$hollow_prefix"` != "" ]]; then
            if [ `echo $line | awk '{print $2}'` == "Ready" ]; then
                name=`echo $line | awk '{print $1}'`
                kubectl describe nodes $name | grep NoSchedule >/dev/null
                if [ $? -ne 0 ]; then
                    ((a+=1))
                fi
            fi
        fi
    done <<< "$(kubectl get nodes)"
    echo $a
}

if [ $# -lt 1 ]; then
    usage
fi
if [ $# -gt 1 ]; then
    scheduler_name="schedulerName: $2"
else
    scheduler_name=""
fi

if [ $# -gt 2 ]; then
    PROVIDER=$3
fi

if [[ "$PROVIDER" == "local" ]]; then
    hollow_prefix=""
fi

if [ $# -gt 3 ]; then
    pods_per_node="{{\$PODS_PER_NODE := DefaultParam .PODS_PER_NODE $4}}"
else
    pods_per_node="{{\$PODS_PER_NODE := DefaultParam .PODS_PER_NODE 20}}"
fi

echo $scheduler_name
sed -i "27c \      $scheduler_name" deployment.yaml

echo $pods_per_node
sed -i "9c $pods_per_node" throughput-config-local.yaml

# kube config for kubernetes api
export KUBECONFIG=$1
KUBE_CONFIG=$1

num_nodes=`get-available-nodes`
echo "There are $num_nodes tested nodes."
sed -i "8c {{\$NODES_PER_NAMESPACE := DefaultParam .NODES_PER_NAMESPACE $num_nodes}}" throughput-config-local.yaml

# SSH config for metrics' collection
MASTER_SSH_IP=`kubectl get nodes -owide| grep master | awk '{print $6}'`
MASTER_SSH_USER_NAME=`kubectl get nodes | grep master | awk '{print $1}'`

# Clusterloader2 testing strategy config paths
# It supports setting up multiple test strategy. Each testing strategy is individual and serial.
TEST_CONFIG='throughput-config-local.yaml'

# Available nodes, if not assigned, test will use real nodes as well

# Log config
tmp=`date '+%Y-%m-%d/%H:%M:%S'`
REPORT_DIR="./reports/${tmp}-${PROVIDER}"
if [ $# -eq 5 ]; then
    REPORT_DIR="./reports/${tmp}-${PROVIDER}-$5"
fi

if [[ ! -d $REPORT_DIR ]]; then
    echo "make log directory... $REPORT_DIR"
    mkdir -p $REPORT_DIR
fi

if [[ "$PROVIDER" == "local" ]]; then
    sed -i "37c \ " deployment.yaml
    sed -i "38c \ " deployment.yaml
    go run cmd/clusterloader.go --kubeconfig=$KUBE_CONFIG \
    --provider=$PROVIDER \
    --masterip=$MASTER_SSH_IP \
    --mastername=${MASTER_SSH_USER_NAME} \
    --testconfig=$TEST_CONFIG \
    --report-dir=$REPORT_DIR \
    --alsologtostderr 2>&1 | tee "$REPORT_DIR/cl2_logs"
else
    # label hollow nodes
    HOLLOW_NODES=`kubectl get no | grep "hollow-node*" | awk '{print$1}'`
    kubectl label node $HOLLOW_NODES nodetype=fake --overwrite >/dev/null
    sed -i "37c \      nodeSelector:" deployment.yaml
    sed -i "38c \        nodetype: fake" deployment.yaml
    go run cmd/clusterloader.go --kubeconfig=$KUBE_CONFIG \
    --provider='local' \
    --masterip=$MASTER_SSH_IP \
    --mastername=${MASTER_SSH_USER_NAME} \
    --testconfig=$TEST_CONFIG \
    --report-dir=$REPORT_DIR \
    --alsologtostderr 2>&1 | tee "$REPORT_DIR/cl2_logs"
fi

python3 log_filter.py $REPORT_DIR/cl2_logs