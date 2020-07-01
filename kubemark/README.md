# Kubemark 的配置

本过程主要参考 xialei 的[可能是最实用的kubemark攻略](https://juejin.im/post/5df9de72518825126d5a30e0) 来完成，更多细节可参考这篇文档。

## 配置流程

* 推荐有两个k8s集群，一个作为worker，一个作为master。master中会被添加hollow-nodes，而worker中会存在与hollow-nodes相关联的pods。负载不大时，一个k8s既做master又做worker也是可以的（本测试也是在单k8s上完成的）

* 准备kubemark的镜像 ，如果你已存在kubemark的镜像可以直接跳过这一步骤（我们直接使用xialei大佬做好的镜像😂)。

  ```bash
  # 进入k8s的目录
  make WHAT='cmd/kubemark'
  cp _output/bin/kubemark cluster/images/kubemark/
  cd cluster/images/kubemark/
  sudo make build
  # 再打个tag上传就好
  ```

* 创建kubemark所必要的k8s资源，在k8s work集群上(kubeconfig 指向worker)运行，

  ```bash
  ./kubemark-config.sh master.kubeconfig
  ```

  `master.kubeconfig` 是 master的kubeconfig，如果master与work是同一集群，`master.kubeconfig` 即为worker的kubeconfig。

  如需要更改`master.kubeconfig`， 执行

  ```
  ./kubemark-config.sh new_master.kubeconfig renew
  ```

* 启动hollow-nodes，仍然在k8s work集群上(kubeconfig 指向worker)，添加hollow-nodes的pods

  ```bash
  kubectl apply -f hollow-node-sts.yaml
  ```

  `hollow-node-sts.yaml`定义了启动hollow-node所需的配置，通过更改replicas，来控制hollow-nodes的数量：

  ```yaml
  spec:
    podManagementPolicy: Parallel
    replicas: 30
  ```

  此外，`hollow-node-sts.yaml`中`container.image` 需要替换为你使用的image

  之后在master k8s 集群上执行`kubect get node`即可看到kubemark 生成的hollow-nodes

  ```
  NAME                    STATUS   ROLES         AGE     VERSION
  hollow-node-0           Ready    <none>        2m18s   v0.0.0-master+$Format:%h$
  hollow-node-1           Ready    <none>        2m16s   v0.0.0-master+$Format:%h$
  hollow-node-2           Ready    <none>        2m17s   v0.0.0-master+$Format:%h$
  hollow-node-3           Ready    <none>        2m18s   v0.0.0-master+$Format:%h$
  hollow-node-4           Ready    <none>        2m17s   v0.0.0-master+$Format:%h$
  hollow-node-5           Ready    <none>        2m16s   v0.0.0-master+$Format:%h$
  hollow-node-6           Ready    <none>        2m18s   v0.0.0-master+$Format:%h$
  hollow-node-7           Ready    <none>        2m18s   v0.0.0-master+$Format:%h$
  ```

----

这之后hollow-nodes即可像其他真实节点一样进行调度分配，只不过hollow-nodes并不会真实运行相应pods。

## 其他

* 删除hollow-nodes
  * 先`kubectl delete -f hollow-node-sts.yaml`
  * 再`./clean-hollow-nodes.sh`

