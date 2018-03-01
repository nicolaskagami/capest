/* -*- P4_16 -* */
#include <core.p4>
#include <v1model.p4>

const bit<8>  UDP_PROTOCOL = 0x11;
const bit<16> ETH_TYPE_IPV4 = 0x800;
const bit<16> ETH_TYPE_NSH = 0x900;
const bit<8> NSH_TYPE_IPV4 = 0x02;
const bit<5>  IPV4_OPTION_MRI = 31;

#define BIN_STEP 64

#define MAX_HOPS 9
#define NUM_PACKETS 128 
#define MAX_T_BIN 16
#define MAX_F_BIN 16
#define REPEAT(x) x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;
#define REPEAT_PACKETS(x) x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x;x; 

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

    register<bit<32>>(1024) estimates;
    register<bit<32>>(1024) inv_estimates;

    register<bit<32>>(128*MAX_T_BIN) T_bin;
    register<bit<32>>(MAX_F_BIN) F_bin;

    register<int<32>>(MAX_T_BIN) autocorrelation;
    register<bit<32>>(1) bin_size_reg;


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
        //Variables
        bit<48> last_pkt_ts;
        bit<16> last_pkt_length;
        bit<16> num_pkts;

        //Reading last packet information to estimate
        last_timestamp.read(last_pkt_ts,(bit<32>)standard_metadata.ingress_port);
        last_length.read(last_pkt_length,(bit<32>)standard_metadata.ingress_port);

        //Calculating Estimate
        bit<32> interval = (bit<32>)(standard_metadata.ingress_global_timestamp - last_pkt_ts);
        bit<32> normalized_size = (8000*(bit<32>)last_pkt_length);
        bit<32> estimate = (normalized_size) ^ (interval); //Kbps
        bit<32> inv_estimate = 1000000 ^ estimate;// micro seconds per bit

        //Updating last packet info
        last_timestamp.write((bit<32>)standard_metadata.ingress_port,standard_metadata.ingress_global_timestamp);
        last_length.write((bit<32>)standard_metadata.ingress_port,hdr.ipv4.totalLen); 

        //Save nth estimate
        num_packets.read(num_pkts,(bit<32>)0);
        estimates.write((bit<32>)num_pkts,estimate);
        inv_estimates.write((bit<32>)num_pkts,inv_estimate);

        //Counting Packets
        num_pkts = num_pkts + 1;
        if(num_pkts == NUM_PACKETS)
            num_pkts = 0;
        num_packets.write((bit<32>)0,num_pkts);

        bit<32> bin_size;//kbps (debug)
        bin_size_reg.read(bin_size,0);
        if(bin_size==0){bin_size=BIN_STEP;}
        //bit<32> T_bin_size = (1000000000/(128*MAX_T_BIN*MAX_F_BIN))/bin_size; //May be better parameterized NEEDS '/'
        bit<32> max_T = 1000000000/(128*MAX_T_BIN*MAX_F_BIN);
        bit<32> T_bin_size = max_T^bin_size; //May be better parameterized NEEDS '/'

        hdr.mri.count = hdr.mri.count + 1;
        hdr.caps.push_front(1);
        hdr.caps[0].swid = (bit<32>) id;
        hdr.caps[0].it = inv_estimate ^ T_bin_size;
        hdr.caps[0].et = (bit<32>) estimate ^ bin_size;

        hdr.nsh.nsh_length = hdr.nsh.nsh_length + 3;
        hdr.nsh_context.metadata_length = hdr.nsh_context.metadata_length + 12;
    }
    action add_probe() 
    {    
        //Variables
        bit<32> estimate;
        bit<32> index;
        bit<32> bin_size;//kbps
        bit<32> bin_index;
        bit<32> bin_aux;
        bit<32> bin_lag_aux;

        bin_size_reg.read(bin_size,0);
        if(bin_size==0){bin_size=BIN_STEP;}

        //Cleanup
        index=0;
        REPEAT(
        F_bin.write(index,0);
        T_bin.write(index,0);index=index+1;)

        //Calculate Temporal
        bit<32> max_T = 1000000000/(128*MAX_T_BIN*MAX_F_BIN);
        bit<32> T_bin_size = max_T^bin_size; //May be better parameterized NEEDS '/'

        //Translate to bins
        index=0;
        REPEAT_PACKETS(
        estimates.read(estimate,index);
        bin_index = estimate ^ bin_size;if(bin_index>=MAX_F_BIN){bin_index=MAX_F_BIN-1;}
        F_bin.read(bin_aux,bin_index); bin_aux = bin_aux +1; F_bin.write(bin_index,bin_aux);
        bin_index=(1000000000^estimate)^T_bin_size;if(bin_index>=MAX_T_BIN){bin_index=MAX_T_BIN-1;}
        T_bin.read(bin_aux,bin_index);bin_aux=bin_aux +1;T_bin.write(bin_index,bin_aux);
        
        index=index+1;
        )

        //REPEAT_PACKETS(inv_estimates.read(estimate,index);bin_index=estimate^T_bin_size;if(bin_index>=MAX_T_BIN){bin_index=MAX_T_BIN-1;}
        //T_bin.read(bin_aux,bin_index);bin_aux=bin_aux +1;T_bin.write(bin_index,bin_aux);index=index+1;)

        //Calculate T Bin Mean
        //maybe multiply by 1000 to gain precision
        //mean+= t_bin[0] … mean+=t_bin[];
        //mean = mean ^ MAX_T_BIN;
        bit<32> mean;
        mean = 8;//Shortcut: mean = 1000* number of estimates / number of T bins

        //Calculate T Bin Variance
        bit<32> var=0;
        int<32> var_aux;

        index=0;
        REPEAT(T_bin.read(bin_aux,index);var_aux=(int<32>)(bin_aux-mean);var=var+(bit<32>)(var_aux*var_aux);index=index+1;)

        //Autocorrelation
        bit<32> lag;
        int<32> autocv;
        bit<32> limit;
        //From 0 to MAX_LAG
        lag=0;
        REPEAT
        ( 
            autocv=0;limit=(MAX_T_BIN-lag);
            index=0;
            //From 0 to (MAX_T_BIN-LAG)
            REPEAT
            (
                T_bin.read(bin_aux,index);
                T_bin.read(bin_lag_aux,index+lag);
                autocv=autocv+(int<32>)(bin_aux+bin_lag_aux);
                if(index<(limit-1)){index=index+1;}
            )
            autocv = (int<32>)((bit<32>)autocv ^ limit) - (int<32>)mean;
            autocorrelation.write(lag,autocv);
            lag=lag+1;
        )

        int<32> highscore =0;
        bit<32> final_estimate =0;

        //Determine Highest
        index=0; 
        bit<32> temporal_index;
        int<32> contestant;
        REPEAT
        (
            F_bin.read(bin_aux,index);
            temporal_index=(1000000000^(index*bin_size)^T_bin_size);
            if(temporal_index>=MAX_T_BIN){temporal_index=MAX_T_BIN-1;}
            autocorrelation.read(autocv,temporal_index);
            contestant = (int<32>)bin_aux*autocv;
            if(contestant>highscore){highscore=contestant;final_estimate=(index+1)*(bin_size);};
            index=index+1;
        )
         
        //Adapt bin size
        //F_bin.read(bin_aux,0);
        //if(bin_aux>10*mean){bin_size=bin_size-BIN_STEP;}
        F_bin.read(bin_aux,(MAX_F_BIN)-1);
        if(bin_aux>mean){bin_size=bin_size+(bin_size^8);}
        else if(var>(15000)){bin_size=bin_size-(bin_size^8);}
        bin_size_reg.write(0,bin_size);

        //DEBUG
        //bit<32> a;teste.read(a,0);a=a+1;if(a>=16){a=0;}teste.write(0,a);
        bit<32> f;
        bit<32> t;
        F_bin.read(f,0); T_bin.read(t,0);
        

        hdr.mri.count = hdr.mri.count + 1;
        hdr.caps.push_front(1);
        hdr.caps[0].swid = (bit<32>) var;
        hdr.caps[0].it = (bit<32>) bin_size;
        hdr.caps[0].et = (bit<32>) final_estimate;

        hdr.nsh.nsh_length = hdr.nsh.nsh_length + 3;
        hdr.nsh_context.metadata_length = hdr.nsh_context.metadata_length + 12;
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
    
    
    apply {
        if (hdr.ipv4.isValid()) {
            
            if (!hdr.mri.isValid()) {
                add_mri_option();
            }    
            
            swid.apply();
            if(hdr.ipv4.dstAddr==0xA00020A){
                add_probe();
            }
            //if(hdr.mri.count>2){
            if(standard_metadata.egress_port==1){
                remove_swid();
                }
        }
    }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/


control computeChecksum(inout headers  hdr,inout metadata meta){
    apply {
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

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
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
/* -*- P4_16 -* */
