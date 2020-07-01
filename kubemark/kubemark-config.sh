#!/bin/bash
function usage() {
    echo -e 'bash kubemark.sh $kubeconfig [renew]'
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

newconfig=$1

if [ $# -gt 1 ]; then
    kubectl delete configmap node-configmap -n kubemark
    kubectl delete secret -n kubemark kubeconfig
fi
kubectl create configmap node-configmap -n kubemark --from-literal=content.type="test-cluster"
kubectl create secret generic kubeconfig --type=Opaque --namespace=kubemark --from-file=kubelet.kubeconfig=$newconfig --from-file=kubeproxy.kubeconfig=$newconfig
