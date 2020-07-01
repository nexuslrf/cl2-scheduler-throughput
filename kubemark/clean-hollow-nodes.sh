#!/bin/bash
kubectl delete node $(kubectl get no | grep "hollow-node*" | awk '{print$1}')