
[comment]: # (SPDX-License-Identifier:  Apache-2.0)

# 实现基础隧道

## 介绍

在本练习中，我们将在你在上一个作业中完成的 IP 路由器上添加对基础隧道协议的支持。基础交换机根据目标 IP 地址进行转发。你的任务是定义一种新的头部类型，用于封装 IP 数据包，并修改交换机代码，使其能够通过新的隧道头部字段来决定目的端口。

新的头部类型将包含一个协议 ID（用于指示被封装的数据包类型）以及一个目标 ID（用于路由）。

> **剧透提醒：** 在 `solution` 子目录中有一个参考实现。你可以随意将你的实现与参考实现进行比较。

本次作业的起始代码在名为 `basic_tunnel.p4` 的文件中，它实际就是上一个练习中 IP 路由器的解决方案。


### 关于控制平面的说明

P4 程序定义了一个数据包处理管道，但每个表中的规则是由控制平面插入的。当某条规则匹配到数据包时，它会调用相应的动作，并由控制面以规则参数方式传递给动作。

在本练习中，我们已经添加了必要的静态控制面规则。每次启动 Mininet 实例时，执行 `make run` 命令会将在各交换机表项中安装这些数据包处理规则。这些规则定义在 `sX-runtime.json` 文件中，其中 `X` 代表交换机编号。

由于控制面会尝试访问 `myTunnel_exact` 表，而该表目前还未在代码中实现，所以使用起始代码时，`make run` 命令将无法正常运行。

**重要提示：** 我们使用 P4Runtime 来安装控制面规则。`sX-runtime.json` 文件中的内容需要对应 P4 编译器生成的 P4Info 文件中定义的表名、键、动作（可以在执行 `make run` 后查看 `build/basic.p4info` 文件）。如果你在 P4 程序中新增或重命名了表、键、动作等，必须要同步更新这些 `sX-runtime.json` 文件的内容。

## 第一步：实现基础隧道功能

`basic_tunnel.p4` 文件实现了一个基础的 IP 路由器。该文件中带有 `TODO` 标记的注释指出了你需要完成的功能。完整实现的 `basic_tunnel.p4` 交换机会根据自定义封装头部的内容进行转发；如果数据包中没有该封装头部，则会像普通路由一样使用 IP 转发。

你的任务如下：

1. **注意：** 增加了一种新的头部类型 `myTunnel_t`，它包含两个 16 位字段：`proto_id` 和 `dst_id`。
2. **注意：** `myTunnel_t` 头部已被加入到 `headers` 结构体中。
3. **TODO：** 请更新 parser，根据以太网头部中的 `etherType` 字段，解析出 `myTunnel` 头部或 `ipv4` 头部。`myTunnel` 协议对应的 EtherType 为 `0x1212`。如果解析出了 `myTunnel` 头部，且其 `proto_id` 字段为 `TYPE_IPV4`（即 0x0800），则还需要进一步解析 `ipv4` 头部。
4. **TODO：** 定义一个名为 `myTunnel_forward` 的新动作，其逻辑很简单：将标准元数据总线 `egress_spec` 字段设置为控制面传入的端口号。
5. **TODO：** 定义一个名为 `myTunnel_exact` 的新表，该表对 `myTunnel` 头部的 `dst_id` 字段进行精确匹配。如果有匹配，调用 `myTunnel_forward` 动作，否则调用 `drop` 动作。
6. **TODO：** 更新 `MyIngress` 控制块中的 `apply` 语句：如果 `myTunnel` 头部有效，则应用你的 `myTunnel_exact` 表；否则如果 `ipv4` 头部有效，则应用 `ipv4_lpm` 表。
7. **TODO：** 更新 deparser，使其依次发射（emit）`ethernet`、`myTunnel`、`ipv4` 头部。注意 deparser 只有在头部有效的情况下才会发射该头部。头部的 implicit valid 位在 parser 解析时已自动设置，因此无需单独检查。
8. **TODO：** 为你定义的新表添加静态转发表项，使交换机能够针对每种 `dst_id` 正确转发。下方拓扑图展示了端口配置及 host 的 ID 分配方式。完成本步骤时，你需要在各个 `sX-runtime.json` 文件内添加相应的规则。

![topology](./topo.png)

## 第二步：运行你的解决方案

1. 在 shell 里运行：
   ```bash
   make run
   ```
   这将会：
   * 编译 `basic_tunnel.p4`；
   * 启动一个包含三个交换机（`s1`、`s2`、`s3`）的 Mininet 实例，三者以三角形互连，每台交换机各连接一台主机（`h1`、`h2`、`h3`）；
   * 主机的 IP 地址分别分配为 `10.0.1.1`、`10.0.2.2` 和 `10.0.3.3`。

2. 现在你应该会看到 Mininet 命令提示符。分别为 `h1` 和 `h2` 打开两个终端：
  ```bash
  mininet> xterm h1 h2
  ```
3. 每台主机上都有一个用 Python 实现的小型消息客户端和服务器。在 `h2` 的终端中，启动消息服务器：
  ```bash
  ./receive.py
  ```
4. 首先测试不使用隧道的情形。在 `h1` 终端中发送消息到 `h2`：
  ```bash
  ./send.py 10.0.2.2 "P4 is cool"
  ```
  此时数据包应被 `h2` 收到。如果你分析收到的数据包，可以看到它包含以太网头、IP头、TCP头和消息内容。如果你修改目标 IP 地址（例如发送到 `10.0.3.3`），消息将不会被 `h2` 收到，而会被 `h3` 收到。
  
5. 现在测试使用隧道的情况。在 `h1` 终端中向 `h2` 发送消息：
  ```bash
  ./send.py 10.0.2.2 "P4 is cool" --dst_id 2
  ```
  此时数据包应被 `h2` 收到。如果你分析收到的数据包，可以看到其结构为以太网头、隧道头、IP头、TCP头以及消息体。
  
6. 在 `h1` 终端中再发送一次消息：
  ```bash
  ./send.py 10.0.3.3 "P4 is cool" --dst_id 2
  ```
  即使目标 IP 地址是 `h3` 的地址，数据包依然会被 `h2` 收到。这是因为此时交换机根据 `MyTunnel` 头部的内容进行转发，而不再使用 IP 头部路由。
  
7. 输入 `exit` 或按 `Ctrl-D` 退出每个 xterm 终端及 Mininet 命令行。


> Python 的 Scapy 工具本身并不支持 `myTunnel` 头部，因此我们提供了 `myTunnel_header.py` 文件，为 Scapy 增加了对该自定义头部的支持。如果你感兴趣，欢迎参考该文件以了解如何实现。

### 思考题

为了让本次隧道练习更有趣（也更贴近实际应用），你如何修改 P4 代码，使交换机能在数据包进入网络时为 IP 包加上 `myTunnel` 头部，并在数据包离开网络、准备发往终端主机时去除 `myTunnel` 头部？

提示：

 - 入网侧（入口）交换机需要将目标 IP 地址映射为 `myTunnel` 头部对应的 `dst_id`。同时，记得设置 `myTunnel` 头部的 valid 位，这样 deparser 阶段才能发射（emit）该头部。
 - 出网侧（出口）交换机需要根据 `dst_id` 字段查找相应的输出端口，并在查找后将 `myTunnel` 头部从包中移除。

### 故障排查

在开发过程中，你可能会遇到如下几种问题：

1. `basic_tunnel.p4` 可能无法编译成功。这种情况下，`make run` 会报告编译器的错误并终止执行。

2. `basic_tunnel.p4` 可能能成功编译，但 `make run` 在用 P4Runtime 尝试下发 `sX-runtime.json` 文件中的控制面规则时失败。这种情况下会有报错信息，请根据这些错误提示修正你的 `basic_tunnel.p4` 实现或转发规则。

3. `basic_tunnel.p4` 能编译，通过规则下发，但交换机并未按预期正确处理数据包。可查阅 `logs/sX.log`，其中详细记录了每个交换机处理每个包的过程，可帮助你定位实现中的逻辑错误。

#### Mininet 的清理

在上述后两种情况下，`make` 可能会遗留一个正在后台运行的 Mininet 实例。可以用下面的命令来清理这些残留实例：

```bash
make stop
```

## 下一步

恭喜，你的实现已经通过！快进入下一个 [p4runtime](../p4runtime) 练习吧！

## 相关文档

关于 topology.json 文件中 Gateway（gw）和 ARP 命令的用法说明见[这里](https://github.com/p4lang/tutorials/tree/master/exercises/basic#the-use-of-gateway-gw-and-arp-commands-in-topologyjson)

P4_16 以及 P4Runtime 的官方文档见[这里](https://p4.org/specs/)

本仓库的所有练习均采用 v1model 架构，其文档见下方：
1. BMv2 Simple Switch 目标平台的文档主要介绍 v1model 架构，可查阅[这里](https://github.com/p4lang/behavioral-model/blob/master/docs/simple_switch.md)。
2. `v1model.p4` 头文件本身有详细注释，可查阅[这里](https://github.com/p4lang/p4c/blob/master/p4include/v1model.p4)。
