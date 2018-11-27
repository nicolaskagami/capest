#include <core.p4>
#include <v1model.p4>

const bit<8>  UDP_PROTOCOL = 0x11;
const bit<16> ETH_TYPE_IPV4 = 0x800;
const bit<16> ETH_TYPE_NSH = 0x900;
const bit<8> NSH_TYPE_IPV4 = 0x02;
const bit<5>  IPV4_OPTION_MRI = 31;

#define MAX_HOPS 9

//CAPEST Parameters
#define NUM_PACKETS 256  
#define MIN_BIN_SIZE 128
#define MAX_T_BIN 32
#define MAX_F_BIN 32

//Bin Size Heuristic Parameters
//256 packets
#define UPPER_VARIANCE_LIMIT 61440 
#define ZEROTH_BIN_LIMIT 8*256/10 
//1024 packets:
//#define UPPER_VARIANCE_LIMIT 9*1179648/10
//#define ZEROTH_BIN_LIMIT 8*1024/10 

//Utilization Estimation Parameters
#define PACKETS_PER_GROUP 128 
//#define PACKETS_PER_GROUP 1024
#define NUM_GROUPS 64 

//CAPEST Macros
#define REPEAT16(x) x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;
#define REPEAT32(x) x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x; 
#define REPEAT64(x) x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x; 
#define REPEAT_PACKETS(x) x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;
//#define REPEAT_PACKETS(x) x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x; 

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;
typedef bit<32> switchID_t;
typedef bit<32> ingress_timestamp_t;
typedef bit<32> egress_timestamp_t;

header nsh_t 
{
    bit<2> version;
    bit<1> oam;
    bit<1> zero;
    bit<6> ttl;
    bit<6> nsh_length;
    bit<4> unassigned;
    bit<4> metadata_type;
    bit<8> next_protocol;
    bit<24> service_path_id;
    bit<8> service_index;
}

header nsh_variable_context_t 
{
    bit<16> metadata_class;
    bit<8> metadata_type;
    bit<1> unassigned;
    bit<7> metadata_length;
}

header ethernet_t 
{
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t 
{
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

header ipv4_option_t 
{
    bit<1> copyFlag;
    bit<2> optClass;
    bit<5> option;
    bit<8> optionLength;
}

header mri_t 
{
    bit<32>  count;
}

header switch_t 
{
    switchID_t  swid;
}

header INT_capsule 
{
    switchID_t  swid;
    ingress_timestamp_t it;
    egress_timestamp_t et;
}

struct ingress_metadata_t 
{
    bit<32>  count;
}

struct parser_metadata_t 
{
    bit<32>  remaining;
}

struct metadata 
{
    ingress_metadata_t   ingress_metadata;
    parser_metadata_t   parser_metadata;
}

struct headers 
{
    ethernet_t   ethernet;
    nsh_t nsh;
    nsh_variable_context_t nsh_context;
    mri_t        mri;
    INT_capsule[MAX_HOPS] caps;
    ipv4_t       ipv4;
    ipv4_option_t  ipv4_option;
}

error { IPHeaderTooShort }
error { NSHeaderTooShort }

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/
parser ParserImpl(packet_in packet,out headers hdr,inout metadata meta,inout standard_metadata_t standard_metadata) 
{
    state start 
    {
        transition parse_ethernet;
    }

    state parse_ethernet 
    {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) 
        {
            ETH_TYPE_IPV4: parse_ipv4;
            ETH_TYPE_NSH: parse_nsh;
            default: accept;
        }
    }

    state parse_nsh 
    {
        packet.extract(hdr.nsh);
        verify(hdr.nsh.nsh_length >= 2, error.NSHeaderTooShort);
        transition select(hdr.nsh.nsh_length) 
        {
            2             : parse_nsh_next_protocol;
            default       : parse_nsh_context;
        }
    }

    state parse_nsh_next_protocol 
    {
        transition select(hdr.nsh.next_protocol) 
        {
            NSH_TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_nsh_context 
    {
        packet.extract(hdr.nsh_context);
        transition parse_mri;
    }

    state parse_ipv4 
    {
        packet.extract(hdr.ipv4);
        verify(hdr.ipv4.ihl >= 5, error.IPHeaderTooShort);
        transition select(hdr.ipv4.ihl) 
        {
            5             : accept;
            default       : parse_ipv4_option;
        }
    }

    state parse_ipv4_option 
    {
        packet.extract(hdr.ipv4_option);
        transition select(hdr.ipv4_option.option) 
        {
            IPV4_OPTION_MRI: parse_mri;
            default: accept;
        }
    }

    state parse_mri 
    {
        packet.extract(hdr.mri);
        meta.parser_metadata.remaining = hdr.mri.count;
        transition select(meta.parser_metadata.remaining) 
        {
            0 : parse_ipv4;
            default: parse_swid;
        }
    }

    state parse_swid 
    {
        packet.extract(hdr.caps.next);
        meta.parser_metadata.remaining = meta.parser_metadata.remaining  - 1;
        transition select(meta.parser_metadata.remaining) 
        {
            0 : parse_ipv4;
            default: parse_swid;
        }
    }    
}


/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control verifyChecksum(inout headers hdr, inout metadata meta) 
{   
    apply {  }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) 
{
    action drop() 
    {
        mark_to_drop();
    }
    action ipv4_forward(macAddr_t dstAddr, egressSpec_t port) 
    {
        standard_metadata.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }
    table ipv4_lpm 
    {
        key = { hdr.ipv4.dstAddr: lpm; }
        actions = { ipv4_forward;drop;NoAction; }
        size = 1024;
        default_action = NoAction();
    }
    apply 
    {
        if (hdr.ipv4.isValid()) { ipv4_lpm.apply(); }
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) 
{
    register<bit<48>>(512) last_timestamp;
    register<bit<16>>(512) last_length;
    register<bit<16>>(1) num_packets;

    register<bit<32>>(NUM_PACKETS) estimates;

    register<bit<32>>(2*MAX_T_BIN) T_bin;
    register<bit<32>>(MAX_F_BIN) F_bin;

    register<int<32>>(MAX_T_BIN) autocorrelation;
    register<bit<32>>(1) bin_size_reg;

    //Utilization Estimation
    register<bit<32>>(NUM_GROUPS) groups_size;
    register<bit<48>>(NUM_GROUPS) groups_timestamp;
    register<bit<32>>(1) intra_group_index;
    register<bit<32>>(1) inter_group_index;


    action add_mri_option()
    {     
        hdr.ipv4_option.setInvalid();
        hdr.ipv4.setValid();
        hdr.ethernet.etherType = ETH_TYPE_NSH;
        
        hdr.nsh.setValid();
        hdr.nsh.version = 0;
        hdr.nsh.oam = 0;
        hdr.nsh.zero = 0;
        hdr.nsh.ttl = (bit<6>) 0x10;
        hdr.nsh.nsh_length = (bit<6>) 0x4;
        hdr.nsh.unassigned = 0;
        hdr.nsh.metadata_type = (bit<4>) 0x2;
        hdr.nsh.next_protocol = NSH_TYPE_IPV4; 
        hdr.nsh.service_path_id = (bit<24>) 0x0;
        hdr.nsh.service_path_id = (bit<24>) 0x0;
        hdr.nsh.service_index = 0;

        hdr.nsh_context.setValid();
        hdr.nsh_context.metadata_class = 0xfff6;
        hdr.nsh_context.metadata_type = 0;
        hdr.nsh_context.unassigned = 0;
        hdr.nsh_context.metadata_length = 4;

        hdr.mri.setValid();
        hdr.mri.count = 0;
    }
    
    action add_swid(switchID_t id) 
    {    

    }
    action add_probe(switchID_t id) 
    {    
    }
    action remove_swid()
    {
        hdr.nsh.setInvalid(); 
        hdr.nsh_context.setInvalid(); 
        hdr.mri.setInvalid(); 
        hdr.ethernet.etherType = ETH_TYPE_IPV4;
        hdr.caps.pop_front(hdr.mri.count);
    }
    table swid 
    {
        actions        = { add_swid; NoAction; }
        default_action =  NoAction();      
    }
    table probe 
    {
        actions        = { add_probe; NoAction; }
        default_action =  NoAction();      
    }
    
    apply 
    {
    }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/


control computeChecksum(inout headers  hdr,inout metadata meta)
{
    apply 
    {
        update_checksum(hdr.ipv4.isValid(),
            {
                hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.diffserv,
                hdr.ipv4.totalLen,
                hdr.ipv4.identification,
                hdr.ipv4.flags,
                hdr.ipv4.fragOffset,
                hdr.ipv4.ttl,
                hdr.ipv4.protocol,
                hdr.ipv4.srcAddr,
                hdr.ipv4.dstAddr,
                hdr.ipv4_option
            }, hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16);
    }
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control DeparserImpl(packet_out packet, in headers hdr) 
{
    apply 
    {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.nsh);
        packet.emit(hdr.nsh_context);
        packet.emit(hdr.mri);
        packet.emit(hdr.caps);                 
        packet.emit(hdr.ipv4);
        packet.emit(hdr.ipv4_option);
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch(
ParserImpl(),
verifyChecksum(),
ingress(),
egress(),
computeChecksum(),
DeparserImpl()
) main;
