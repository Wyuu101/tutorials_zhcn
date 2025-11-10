
[comment]: # (SPDX-License-Identifier:  Apache-2.0)

 为了便于学习和理解p4练习题，干脆把每个习题的readme都翻译了一下。
 以下便是根据原文翻译后的内容：



# P4 教程

* [简介](#introduction)
* [课程展示](#presentation)
* [P4 文档](#p4-documentation)
* [获取所需软件](#obtaining-required-software)
     * [构建虚拟机](#to-build-the-virtual-machine)
     * [访问虚拟机](#accessing-the-vm)
     * [在已有系统上安装 P4 开发工具](#to-install-p4-development-tools-on-an-existing-system)
* [如何贡献](#how-to-contribute)
* [历史教程](#older-tutorials)

如果您不是在参加线下 P4 教学课程时阅读本教程，请查看[下方](#older-tutorials)以获取最近举办的线下课程的信息链接。


## 简介

欢迎阅读P4教程！我们为您准备了一系列模块化的练习，帮助您快速入门P4编程：

1. 基础介绍与语言基础
   - [基本转发](./exercises/basic)<br>
     <small>在本练习中，您将学习如何使用P4实现基本的IPv4数据包转发。通过扩展提供的 `basic.p4` 骨架代码，您将开发用于更新MAC地址、递减TTL、基于预定义规则转发数据包的逻辑。通过在Mininet的fat-tree拓扑中实际操作与测试，您将深入理解交换机数据面逻辑的设计与部署。</small>
   
   - [基础隧道封装](./exercises/basic_tunnel)<br>
     <small>在本练习中，您将在P4实现的IP路由器基础上添加基本的隧道功能，实现IP包的封装和定制化转发。通过引入新的隧道头类型，您将修改交换机逻辑来处理封装包，并根据目的ID定义转发规则。通过静态控制面配置，交换机能够转发封装包，展现了P4在定制数据包处理和网络功能方面的强大灵活性。</small>

2. P4Runtime 与控制面
   - [P4Runtime](./exercises/p4runtime)<br>
     <small>本练习涉及通过P4Runtime实现控制面，向交换机下发流表以完成主机间的流量隧道。学习者需要修改提供的P4程序和控制器脚本，以建立连接、下发P4程序、配置隧道入口规则、读取隧道计数器，从而深入理解P4Runtime和网络转发逻辑。</small>

   - [流表缓存](./exercises/flowcache)<br>
     <small>本练习实现了名为flowcache.p4的程序，处理PacketIn和PacketOut机制及流表空闲超时。数据面通过PacketIn将数据包发送至P4Runtime控制器，控制器收到后向流表中添加新项。当控制器计算并下发行规则时，利用PacketOut将数据包转发到目的地。当流表项被安装后若无数据包匹配，则启动空闲计时器。计时器过期时，发送IdleTimeoutNotification消息至控制器，由控制器负责重新安装到期的流表项。</small>

3. 监控与调试
   - [显示拥塞通知（ECN）](./exercises/ecn)<br>
     <small>在本教程中，您将为基础L3转发P4程序添加显式拥塞通知（ECN）功能，实现端到端拥塞告警而无需丢包。您需要修改 `ecn.p4` 文件，实现ECN相关逻辑（如基于队列长度阈值更新ECN标志），并配置静态规则以正确处理ECN，最终在Mininet中测试包转发与ECN标志操作效果。</small>

   - [多跳路径检测（MRI）](./exercises/mri)<br>
     <small>本教程旨在为基础L3转发增强一个简化版的带内网络遥测（INT）功能，称为多跳路径检测（MRI）。指导用户扩展 `mri.p4` 骨架程序，实现将交换机ID和队列长度追加进每个数据包的头部堆栈，从而跟踪数据包所经过的路径及队列长度。</small>

4. 高级行为
   - [源路由](./exercises/source_routing)<br>
     <small>本练习目标是实现源路由功能，即由源主机在数据包中指定输出端口栈作为转发路径。完成P4程序 `source_routing.p4` 配置后，数据包将按照端口栈中指定的路径实现端到端转发。</small>

   - [计算器](./exercises/calc)<br>
     <small>本教程指导您通过自定义协议头在P4中实现一个基础计算器。P4程序 `calc.p4` 可解析传入的计算包，执行指定算术运算并将结果返回给发送方，实现基本的网络内算术计算。</small>

   - [负载均衡](./exercises/load_balance)<br>
     <small>本练习引导您在名为 `load_balance.p4` 的P4程序中通过等价多路径转发（ECMP）实现负载均衡。程序利用哈希函数，基于五元组分配数据包到两台目的主机，实现高效的网络流量分发。</small>

   - [服务质量（QoS）](./exercises/qos)<br>
     <small>本教程聚焦在P4程序 `qos.p4` 中使用区分服务（Diffserv）实现质量服务（QoS）。在基础L3转发上进行拓展，根据流量类别和优先级设置Diffserv标志，实现现代IP网络的QoS。</small>

   - [组播](./exercises/multicast)<br> 
     <small>本练习要求您编写P4程序，实现交换机根据目标MAC地址将数据包组播至多个输出口。需要实现组播逻辑，包括定义转发操作和配置控制面下发规则。通过在Mininet环境中的实际操作，参与者将学习如何通过组播提升网络流量管理与效率。</small>

5. 有状态数据包处理
   - [防火墙](./exercises/firewall)<br>
     <small>本练习目标是利用P4程序 `firewall.p4` 实现基本的有状态防火墙。防火墙基于预设规则允许内外主机通信，并利用布隆过滤器（Bloom Filter）进行有状态的数据包检测与过滤。</small>

   - [链路监控](./exercises/link_monitor)<br>
     <small>本练习围绕在网络中使用P4实现链路利用率监控。通过扩展基础的IPv4转发程序，能够解析源路由的探测包并对其头部字段进行操作，通过寄存器数组记录数据，实现链路利用率的精准监控，非常有助于网络管理与优化。</small>

## 课程展示

课程幻灯片可通过[在线链接](https://bit.ly/p4d2-2018-spring)或教程目录中的 [P4_tutorial.pdf](./P4_tutorial.pdf) 获取。

P4备忘单也可通过以下[在线链接](https://drive.google.com/file/d/1Z8woKyElFAOP6bMd8tRa_Q4SA1cd_Uva/view?usp=sharing)查阅，其中包含了各种参考示例。

## P4文档

P4_16 和 P4Runtime 官方文档可在[此处](https://p4.org/specs/)查阅。

本仓库所有练习均使用 v1model 架构，相关文档如下：
1. 有关v1model架构的说明可参考 BMv2 Simple Switch 目标文档，详见[这里](https://github.com/p4lang/behavioral-model/blob/master/docs/simple_switch.md)。
2. `v1model.p4` 头文件有详细注释，可在[这里](https://github.com/p4lang/p4c/blob/master/p4include/v1model.p4)查看。

## 获取所需软件

如果你是在监考的培训活动中开始本教程，我们已经为你准备好了包含所有必需软件的虚拟机镜像。请向讲师索取含有虚拟机镜像的U盘。

否则，为了完成[练习](https://github.com/p4lang/tutorials/tree/master/exercises)，你需要选择下列方式之一：

+ 下载并运行预装了P4开发工具的虚拟机；
+ 自行构建虚拟机，在其内编译并安装P4开发工具；
+ 在已安装受支持版本Ubuntu Linux的现有系统上安装P4开发工具。

### 下载已预装P4开发工具的虚拟机

你需要拥有一台安装有[VirtualBox](https://virtualbox.org)的64位Intel/AMD处理器架构系统。你可以在[这里](https://github.com/jafingerhut/p4-guide/blob/master/bin/README-install-troubleshooting.md)查看可下载的虚拟机镜像列表，然后使用VirtualBox的“文件->导入设备”菜单项将虚拟机添加到系统中。

虚拟机只有一个用户账户：
+ 用户名：p4 | 密码：p4

### 构建包含P4开发工具的虚拟机

请参阅[这里](vm-ubuntu-24.04/README.md)的说明。

### 在现有系统上安装P4开发工具

另一个Github仓库中提供了从全新安装的Ubuntu 20.04、22.04或24.04 Linux系统（且具备足够内存和剩余磁盘空间）开始安装全部必要P4开发工具的说明和脚本。相关安装说明和脚本见[这里](https://github.com/jafingerhut/p4-guide/blob/master/bin/README-install-troubleshooting.md)（注意，需克隆整个仓库才能运行安装脚本）。

# 如何参与贡献

我们欢迎各类新贡献。开始前，请查阅我们的[贡献指南](CONTRIBUTING.md)。

# 历届教程汇总

本仓库示例代码已多次被用于现场实践课程。例如，每年4月或5月会在斯坦福大学P4研讨会上举办一次，也曾多次在如ACM SIGCOMM等网络相关会议上开展。

如果你发现本教程相关的公开课堂视频或者预制虚拟机镜像下载地址，但在本仓库尚未收录，请[提交issue](https://github.com/p4lang/tutorials/issues)。

## ACM SIGCOMM 2019年8月 数据平面编程教程

关于ACM SIGCOMM 2019年8月数据平面编程教程的详细信息请参见[这里](https://p4.org/events/2019-08-23-p4-tutorial/)

该页面包含了用于本次培训的预制虚拟机下载链接，以及从本仓库特定分支自行构建该虚拟机的相关说明。

## 2019年4月 P4开发者日

关于2019年4月P4开发者日活动的更多信息请见[这里](https://p4.org/p4-developer-day-2019/)

该活动设置了初级和高级两个班次。上述页面包含了下载和安装用于授课的预制Linux虚拟机的相关说明。

## 2017年11月 P4开发者日

这个[链接](https://www.youtube.com/watch?v=3DJeqS_dl_o&list=PLf7HGRMAlJBzGC58GcYpimyIs7D0nuSoo)可播放本次活动6个教程视频系列中的第一期欢迎视频。

有关该活动的更多信息请见[这里](https://p4.org/p4-developer-day-fall-2017/)。
