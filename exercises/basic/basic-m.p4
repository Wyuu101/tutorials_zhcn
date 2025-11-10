// SPDX-License-Identifier: Apache-2.0
/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_IPV4 = 0x800;

/*************************************************************************
*********************** H E A D E R S  ***********************************
* This program skeleton defines minimal Ethernet and IPv4 headers and    *
* a simple LPM (Longest-Prefix Match) IPv4 forwarding pipeline.          *
* The exercise intentionally leaves TODOs for learners to implement.     *
*************************************************************************/

typedef bit<9>  egressSpec_t;   // Standard BMv2 uses 9 bits for egress_spec
typedef bit<48> macAddr_t;      // Ethernet MAC address
typedef bit<32> ip4Addr_t;      // IPv4 address

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

struct metadata {
    /* empty */
}

struct headers {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
}

/*************************************************************************
*********************** P A R S E R  *************************************
* New to P4? A typical parser does this:
*   start -> parse_ethernet
*   parse_ethernet:
*       if etherType == TYPE_IPV4 -> parse_ipv4
*       else accept
*   parse_ipv4 -> accept
* This skeleton leaves the actual states as a TODO to implement later.   *
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {
                    
    /* TODO: add parser logic
        * Suggested outline:
        *   1) Extract Ethernet: packet.extract(hdr.ethernet);
        *   2) If hdr.ethernet.etherType == TYPE_IPV4 -> parse IPv4
        *   3) Otherwise -> transition accept
        */
    state start {
        transition parse_ethernet;  
    }
    state parse_ethernet{
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType){
            TYPE_IPV4 : parse_ipv4;
            default : accept;
        }
        
    }
    state parse_ipv4{
        packet.extract(hdr.ipv4);
        transition accept;
    }
}


/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {  }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
* High-level intent:
*   - Do an LPM lookup on IPv4 dstAddr
*   - On hit, call ipv4_forward(next-hop MAC, output port)
*   - Otherwise, drop or NoAction (as configured)                         *
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {

    action drop() {
        mark_to_drop(standard_metadata);
    }

    /*********************************************************************
     * 新手须知：
     * 'ipv4_forward(dstAddr, port)' 是由表 'ipv4_lpm' 调用的。
     *
     * 其中 'dstAddr' 和 'port' 的值是由控制平面在插入 'ipv4_lpm' 表项时提供的*动作参数*。
     *
     * 其含义如下：
     *   - dstAddr  => 下一跳的以太网目的 MAC 地址
     *   - port     => 输出端口（最终写入 standard_metadata.egress_spec 字段）
     *
     * 示例（BMv2 simple_switch_CLI）：
     *   table_add ipv4_lpm ipv4_forward 10.0.1.1/32 => 00:00:00:00:01:00 1
     * 上述命令会将 MAC=00:00:00:00:01:00 和 PORT=1 作为动作参数传递给 ipv4_forward(dstAddr, port)。
     *********************************************************************/
     
    /*
    理解：ipv4_forward的参数由控制平面传入，即在s1-runtime.json中有一段如下匹配规则，其"action_params"就指定了行为参数;
    而在p4语言中，只需要编写对这些传入参数的处理逻辑，而无需关心控制平面如何传入这些参数。
    {
      "table": "MyIngress.ipv4_lpm",
      "match": {
        "hdr.ipv4.dstAddr": ["10.0.2.2", 32]
      },
      "action_name": "MyIngress.ipv4_forward",
      "action_params": {
        "dstAddr": "08:00:00:00:02:22",
        "port": 2
      }
    },

    */


    action ipv4_forward(macAddr_t dstAddr, egressSpec_t port) {
        /*
            IPv4 转发动作函数。

            TODO：实现以下转发步骤，例如：
              - standard_metadata.egress_spec = port;    // 设置出口端口
              - hdr.ethernet.dstAddr = dstAddr;          // 更新以太网目的MAC
              - （可选）将hdr.ethernet.srcAddr设为本交换机该端口的MAC地址
              - 调整IPv4的TTL及校验和（如有需要）
        */

        // 告知交换机应该将数据包从哪个端口发出
        standard_metadata.egress_spec = port;
        // 更新数据包的源MAC地址
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        // 更新数据包的目的MAC地址
        hdr.ethernet.dstAddr = dstAddr;
        // 更新IPv4的TTL数
        hdr.ipv4.ttl  = hdr.ipv4.ttl -1;
    }

    /*********************************************************************
     * LPM table for IPv4:
     *   - Matches on hdr.ipv4.dstAddr using longest-prefix match (lpm)
     *   - On hit, calls ipv4_forward with *action data populated by the
     *     control plane when it installs the table entry.
     *********************************************************************/
    table ipv4_lpm {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            ipv4_forward;
            drop;
            NoAction;
        }
        size = 1024;
        default_action = NoAction();
    }

    apply {
        /* TODO: 修正 ingress 控制逻辑
         *  - 推荐做法：仅当 IPv4 头有效时才应用 ipv4_lpm 表，例如：
         *      if (hdr.ipv4.isValid()) { ipv4_lpm.apply(); }
         *    当前骨架代码为了练习目的，无条件应用该表。
         */
        if(hdr.ipv4.isValid()){
            ipv4_lpm.apply();
        }
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
* Often used for queue marks, mirroring, or post-routing edits.          *
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply {  }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
* This block shows how to compute IPv4 header checksum when needed.      *
*************************************************************************/

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
     apply {
        update_checksum(
            hdr.ipv4.isValid(),
            { hdr.ipv4.version,
              hdr.ipv4.ihl,
              hdr.ipv4.diffserv,
              hdr.ipv4.totalLen,
              hdr.ipv4.identification,
              hdr.ipv4.flags,
              hdr.ipv4.fragOffset,
              hdr.ipv4.ttl,
              hdr.ipv4.protocol,
              hdr.ipv4.srcAddr,
              hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16);
    }
}


/*************************************************************************
***********************  D E P A R S E R  *******************************
* The deparser serializes headers back onto the packet in order.         *
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        /*
        Typical implementation (left as a TODO for learners):
            packet.emit(hdr.ethernet);
            packet.emit(hdr.ipv4);   // per P4_16 spec, emit appends a header
                                     // only if it is valid; no 'if' needed.
        */
        apply {
            // 注意解解析中包头由底层向上层逐一添加
            packet.emit(hdr.ethernet);
            packet.emit(hdr.ipv4);
        }
    }
}

/*************************************************************************
***********************  S W I T C H  ***********************************
*************************************************************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
