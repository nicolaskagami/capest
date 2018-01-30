for INTERFACE in s1-eth1 s1-eth2 s1-eth3 s2-eth1 s2-eth2 s2-eth3 s3-eth1 s3-eth2 s3-eth3;
do
    tc qdisc del dev $INTERFACE root
    ifconfig $INTERFACE mtu 9000 up
    tc qdisc add dev $INTERFACE root tbf rate 10Mbit latency 10ms burst 9000
done
