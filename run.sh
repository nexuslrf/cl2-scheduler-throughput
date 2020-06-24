#!/bin/bash
function usage() {
    echo -e 'bash run.sh $kubeconfig [$scheduler_name] [$pods_per_node]'
    exit 1
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
    pods_per_node="{{\$PODS_PER_NODE := DefaultParam .PODS_PER_NODE $3}}"
else
    pods_per_node="{{\$PODS_PER_NODE := DefaultParam .PODS_PER_NODE 20}}"
fi

echo $scheduler_name
sed -i "27c \      $scheduler_name" deployment.yaml

echo $pods_per_node
sed -i "9c $pods_per_node" throughput-config-local.yaml


# kube config for kubernetes api
KUBE_CONFIG=$1

# Provider setting
PROVIDER='local'

# SSH config for metrics' collection
MASTER_SSH_IP=`kubectl get nodes -owide| grep master | awk '{print $6}'`
MASTER_SSH_USER_NAME=`kubectl get nodes | grep master | awk '{print $1}'`

# Clusterloader2 testing strategy config paths
# It supports setting up multiple test strategy. Each testing strategy is individual and serial.
TEST_CONFIG='throughput-config-local.yaml'

# Available nodes, if not assigned, test will use real nodes as well

# Log config
tmp=`date '+%Y-%m-%d/%H:%M:%S'`
case="local"
REPORT_DIR="./reports/${tmp}-${case}-${PROVIDER}"

if [[ ! -d $REPORT_DIR ]]; then
    echo "make log directory... $REPORT_DIR"
    mkdir $REPORT_DIR
fi

source config-local
go run cmd/clusterloader.go --kubeconfig=$KUBE_CONFIG \
--provider=$PROVIDER \
--masterip=$MASTER_SSH_IP \
--mastername=${MASTER_SSH_USER_NAME} \
--testconfig=$TEST_CONFIG \
--report-dir=$REPORT_DIR \
--alsologtostderr 2>&1 | tee "$REPORT_DIR/cl2_logs"

python3 log_filter.py $REPORT_DIR/cl2_logs.txt 