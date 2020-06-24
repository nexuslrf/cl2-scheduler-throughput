# 调度器吞吐量测试

This repo is directly copied from original [clusterloader2](https://github.com/kubernetes/perf-tests/tree/master/clusterloader2)

该测试基于clusterloader2进行，脚本整理在：

**配置文件：**

* throughput-config-local.yaml: clusterloader2的throughput 任务定义。
* deployment.yaml: 测试任务的yaml文件。

**测试输入：**

* kubeconfig
* scheduler_name:  默认 default-scheduler
* pods_per_node: 默认 20

**测试结果：** 在`reports`文件夹中

* junit.xml：测试总结文件

* PodStartupLatency_*.json: 测试任务的Pod Startup Latency

* SchedulingThroughput_*.json: Throughput信息 🎯

  ```json
  {
    "perc50": 0,
    "perc90": 80,
    "perc99": 80,
    "max": 80
  }
  ```

* cl2_logs*: cluster运行 log 文件，可以查看每秒的统计数据

**测试方法：**

```bash
./run.sh kubeconfig [scheduler_name] [pods_per_node]
```
