#Compile:
#p4c-bm2-ss --p4v 16 "capest.p4" -o "capest.json"

#Run Multiswitch
#python2 "../utils/mininet/factor_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri.p4.json" 

#Big Factors
#python2 "../utils/mininet/factor_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_HEUR_01_02.p4.json" 

#Factor Bin (Heur 16_08)
#python2 "../utils/mininet/factor_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_BIN_08.p4.json" 
#python2 "../utils/mininet/factor_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_BIN_12.p4.json" 
#python2 "../utils/mininet/factor_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_BIN_16.p4.json" 
#python2 "../utils/mininet/factor_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_BIN_20.p4.json" 
#python2 "../utils/mininet/factor_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_BIN_24.p4.json" 
#python2 "../utils/mininet/factor_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_BIN_28.p4.json" 
#python2 "../utils/mininet/factor_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_BIN_32.p4.json" 

#Factor Bin (Heur 04_08)
#python2 "../utils/mininet/factor_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_HEUR_04_08_BIN_08.p4.json" 
#python2 "../utils/mininet/factor_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_HEUR_04_08_BIN_12.p4.json" 
#python2 "../utils/mininet/factor_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_HEUR_04_08_BIN_16.p4.json" 
#python2 "../utils/mininet/factor_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_HEUR_04_08_BIN_20.p4.json" 
#python2 "../utils/mininet/factor_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_HEUR_04_08_BIN_24.p4.json" 
#python2 "../utils/mininet/factor_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_HEUR_04_08_BIN_28.p4.json" 
#python2 "../utils/mininet/factor_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_HEUR_04_08_BIN_32.p4.json" 

#Factor Bin (Heur 08_16)
#python2 "../utils/mininet/factor_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_HEUR_08_16_BIN_08.p4.json" 
#python2 "../utils/mininet/factor_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_HEUR_08_16_BIN_12.p4.json" 
#python2 "../utils/mininet/factor_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_HEUR_08_16_BIN_16.p4.json" 
#python2 "../utils/mininet/factor_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_HEUR_08_16_BIN_20.p4.json" 
#python2 "../utils/mininet/factor_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_HEUR_08_16_BIN_24.p4.json" 
#python2 "../utils/mininet/factor_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_HEUR_08_16_BIN_28.p4.json" 
#python2 "../utils/mininet/factor_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_HEUR_04_08_BIN_32.p4.json" 



#python2 "../utils/mininet/factor_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_HEUR_01_24.p4.json" 
python2 "../utils/mininet/factor_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_HEUR_04_08.p4.json" 
python2 "../utils/mininet/factor_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_HEUR_08_16.p4.json" 
#python2 "../utils/mininet/factor_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_HEUR_16_08.p4.json" 
python2 "../utils/mininet/factor_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_HEUR_24_16.p4.json" 
#python2 "../utils/mininet/factor_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_HEUR_32_24.p4.json" 

#python2 "../utils/mininet/factor_xt_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_PACKETS_016.p4.json" 
#python2 "../utils/mininet/factor_xt_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_PACKETS_032.p4.json" 
#python2 "../utils/mininet/factor_xt_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_PACKETS_064.p4.json" 
#python2 "../utils/mininet/factor_xt_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_PACKETS_128.p4.json" 
#python2 "../utils/mininet/factor_xt_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_PACKETS_256.p4.json" 
#python2 "../utils/mininet/factor_xt_mininet_test.py" --log-dir "./logs" --manifest "./p4app.json" --target "multiswitch" --auto-control-plane --behavioral-exe "simple_switch" --json "mri_PACKETS_512.p4.json" 
