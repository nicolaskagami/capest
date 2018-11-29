#Compile:
#p4c-bm2-ss --p4v 16 "capest.p4" -o "capest.json"

#Run Multiswitch
python2 "../utils/mininet/ms_mininet_test.py" --log-dir "./logs" --manifest "./capest_p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "capest.json" 
