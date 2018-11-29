#Compile:
#p4c-bm2-ss --p4v 16 "mri.p4" -o "mri.p4.json"

#Run Multiswitch
python2 "../utils/mininet/xtraffic_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri.p4.json" 
python2 "../utils/mininet/xtraffic_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_HEUR_01_24.p4.json" 
python2 "../utils/mininet/xtraffic_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_HEUR_04_08.p4.json" 
