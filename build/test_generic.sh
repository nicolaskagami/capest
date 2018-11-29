#Compile:
#p4c-bm2-ss --p4v 16 "mri.p4" -o "mri.p4.json"

#Run Multiswitch
#python2 "../utils/mininet/control_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "simple.p4.json" 
#python2 "../utils/mininet/iperf_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "simple.p4.json" 
#python2 "../utils/mininet/ms_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri.p4.json" 
python2 "../utils/mininet/generic_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "./mri.p4.json" 
