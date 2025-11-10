
[comment]: # (SPDX-License-Identifier:  Apache-2.0)

# 实现基本转发

## 简介

本练习的目标是编写一个 P4 程序来实现**基本转发**。  
为了保持简单，我们只实现 **IPv4 转发**。

在 IPv4 转发中，交换机必须对每个数据包执行以下操作：  
(i) 更新源和目的 MAC 地址；  
(ii) 在 IP 头中递减生存时间（TTL）；  
(iii) 将数据包转发到相应的端口。

你的交换机将只有一个表，由控制平面使用静态规则填充。  
每条规则将一个 IP 地址映射到下一跳的 MAC 地址和输出端口。  
我们已经定义了控制平面的规则，因此你只需要实现 P4 程序的数据平面逻辑。

本练习将使用以下拓扑。它是 fat-tree 拓扑的单个 pod，  
因此我们称之为 **pod-topo**：  
![pod-topo](./pod-topo/pod-topo.png)

我们的 P4 程序将基于 P4.org 的 bmv2 软件交换机上实现的 **V1Model** 架构编写。  
V1Model 的架构文件位于：  
`/usr/local/share/p4c/p4include/v1model.p4`。  
该文件描述了该架构中 P4 可编程元素的接口、支持的 extern，以及架构的标准元数据字段。  
我们鼓励你查看该文件。


> **剧透预警：** 在 `solution` 子目录下有一个参考答案。你可以随时将你的实现与参考答案进行对比。

## 前置条件
为了更顺利地完成本教程，请务必查看并遵循 [获取所需软件指南](https://github.com/p4lang/tutorials#obtaining-required-software) 来安装所需的开发工具。

## 步骤 1：运行（不完整的）起始代码

本 README 所在目录包含一个骨架 P4 程序 `basic.p4`，它的初始状态是丢弃所有数据包。你的任务是扩展这个骨架程序，使其能正确地转发 IPv4 数据包。

在此之前，让我们先编译这个不完整的 `basic.p4`，并在 Mininet 中启动交换机以测试其行为。

1. 在你的 shell 中运行以下命令：
   ```bash
   make run
   ```
   这将会：
   * 编译 `basic.p4`，
   * 在 Mininet 中启动 pod-topo，并为所有交换机配置合适的 P4 程序及表项，
   * 并为所有主机执行 [pod-topo/topology.json](./pod-topo/topology.json) 中列出的配置命令。

2. 现在你应该可以看到 Mininet 命令行提示。尝试在拓扑内不同主机之间 ping 通：
   ```bash
   mininet> h1 ping h2
   mininet> pingall
   ```
3. 在每个 xterm 和 Mininet 命令行中输入 `exit` 以退出。然后，停止 mininet 的命令为：
   ```bash
   make stop
   ```
   如果你想删除所有 pcap、构建文件和日志，可以执行：
   ```bash
   make clean
   ```

ping 会失败，因为每台交换机是按照 `basic.p4` 进行编程的——它会丢弃所有到达的数据包。
你的任务是扩展这个文件，让它能够正常转发数据包。

### 关于控制平面的说明

P4 程序定义了数据包处理流程，但各表中的规则由控制平面插入。当某条规则匹配数据包时，会按照控制平面提供的参数调用该规则所绑定的动作。

在本练习中，我们已为你实现好了控制平面逻辑。当你启动 Mininet 时，`make run` 命令会在每台交换机的表中安装数据包处理规则，这些规则定义在 `sX-runtime.json` 文件中（X 为交换机编号）。

**重要提示：** 我们使用 P4Runtime 安装这些控制平面规则。`sX-runtime.json` 文件中的内容依赖于 P4Info 文件（可在执行 `make run` 后于 `build/basic.p4.p4info.txtpb` 查看）中定义的表、键、动作的具体名称。如果你在 P4 程序中添加或重命名了表、键、动作，需要同步修改这些 `sX-runtime.json` 文件，否则规则无法装载。

## 步骤 2：实现三层（L3）转发

`basic.p4` 文件包含了一个带有 `TODO` 注释的骨架 P4 程序，你需要按照文件结构补全这些 `TODO`，完成缺失的逻辑。

一个完整的 `basic.p4` 文件应包含如下组件：

1. 以太网（`ethernet_t`）和 IPv4 （`ipv4_t`）头部类型定义
2. **TODO：** 用于提取并填充 `ethernet_t` 和 `ipv4_t` 字段的以太网和 IPv4 解析器
3. 使用 `mark_to_drop()` 丢弃数据包的动作
4. **TODO：** 一个名为 `ipv4_forward` 的动作：
   1. 设置下一跳的出口端口；
   2. 更新以太网目的地址为下一跳地址；
   3. 更新以太网源地址为当前交换机地址；
   4. 对 TTL 进行减一（TTL--）。
5. **TODO：** 一个控制器流程：
   1. 定义一个根据 IPv4 目的地址查找并调用 `drop` 或 `ipv4_forward` 的表；
   2. 一个 `apply` 块，应用该表。
6. **TODO：** 一个对数据包进行重组，决定各字段写入顺序的 deparser。
7. 使用解析器、控制器和 deparser 进行 `package` 实例化。
   > 一般情况下，package 还需要校验和验证和重新计算控件实例。在本教程中，这些都可以用空控件实例替代，无需实现校验和处理。

## 步骤 3：运行你的解决方案

按照步骤 1 的说明操作。这一次，你应该能够在拓扑中的任意两台主机之间成功 ping 通。

### 思考与延伸

你的解决方案的“测试集”——即在拓扑中发送 ping 包——其实并不健壮。你还应该测试哪些内容，以更有信心地确认你的实现是正确的？

> 虽然 Python 的 `scapy` 库超出了本教程的范围，但它可以用来生成测试数据包。`send.py` 文件展示了如何使用它。

你还可以思考下列问题：
 - 如何增强你的程序以响应 ARP 请求？
 - 如何增强你的程序以支持 traceroute？
 - 如何增强你的程序以支持下一跳（next hops）？
 - 这个程序能完全取代路由器吗？还缺什么？

### 故障排查

在你开发程序的过程中，可能会遇到一些问题：

1. `basic.p4` 可能无法编译。在这种情况下，`make run` 会报告编译器输出的错误并停止运行。

2. `basic.p4` 可能编译通过，但无法支持控制平面需要的规则（如 `s1-runtime.json` 到 `s3-runtime.json` 中的规则），`make run` 会在用 P4Runtime 下发规则时报告错误。根据这些错误信息修正你的 `basic.p4` 实现。

3. `basic.p4` 可能编译并成功安装控制平面规则，但交换机处理数据包的方式却不如预期。你可以查看 `logs/sX.log` 文件。这些日志详细记录了每台交换机如何处理每个数据包，内容详尽，有助于你定位程序中的逻辑失误。

#### 清理 Mininet

在上述后两种情况下，`make run` 可能会遗留一个正在运行的 Mininet 实例。你可以用如下命令清理这些实例：

```bash
make stop
```

## `topology.json` 中 gateway（gw）和 ARP 命令的作用

- gateway（gw）命令：`route add default gw` 用于为主机设置默认网关。当目标 IP 不在本地子网时，主机会将数据发往此处。为主机设置默认网关，对于通信其它网络的设备来说非常重要。
- ARP 命令：`arp -i eth0 -s` 用于在主机的 ARP 缓存中添加静态 ARP 项。当你添加静态 ARP 项时，实际上是在告诉主机：“嘿，这个 IP 地址（比如 10.0.0.1）我已经知道它的 MAC 地址了，不用每次都广播询问了。”在本练习（以及大多数其它练习）中，这很重要，因为交换机本身不会响应 ARP 请求。在真实的网络中，生产环境下的交换机通常会响应 ARP 请求，但在这些实验环境中，只有通过设置静态 ARP 项，主机才能找到网关。
  - `-i eth0`：指定进行 ARP 操作的网卡接口（如 eth0）。
  - `-s`：表示设置一个静态 ARP 项。

*注意*：如果你去掉了 gateway 与 ARP 相关的命令，你网络中的主机可能会丧失彼此通信和与外网通信的能力。在这种情况下，执行 `pingall` 命令时会出现 100% 丢包，因为主机缺少到达目标所需的路由信息和 ARP 项。

## 下一步

恭喜你，已经成功实现了本实验！请继续学习下一课题：[基本隧道转发（Basic Tunneling）](../basic_tunnel)

## 相关文档

P4_16 语言与 P4Runtime 的官方文档可在[这里](https://p4.org/specs/)找到。

本仓库的所有练习都基于 v1model 架构，其相关文档如下：
1. BMv2 Simple Switch 目标的 v1model 架构说明请参考[这里](https://github.com/p4lang/behavioral-model/blob/master/docs/simple_switch.md)。
2. `v1model.p4` 文件内含大量注释，可在[这里](https://github.com/p4lang/p4c/blob/master/p4include/v1model.p4)查阅。
