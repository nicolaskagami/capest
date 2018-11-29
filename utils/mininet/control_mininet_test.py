#!/usr/bin/env python2

# Copyright 2013-present Barefoot Networks, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

import signal
import os
import sys
import subprocess
import argparse
import json
import importlib
import re
from time import sleep

from mininet.net import Mininet
from mininet.topo import Topo
from mininet.link import TCLink
from mininet.log import setLogLevel, info
from mininet.cli import CLI

from p4_mininet import P4Switch, P4Host
import apptopo
import appcontroller

from subprocess import call

parser = argparse.ArgumentParser(description='Mininet demo')
parser.add_argument('--behavioral-exe', help='Path to behavioral executable',
                    type=str, action="store", required=True)
parser.add_argument('--thrift-port', help='Thrift server port for table updates',
                    type=int, action="store", default=9090)
parser.add_argument('--bmv2-log', help='verbose messages in log file', action="store_true")
parser.add_argument('--cli', help="start the mininet cli", action="store_true")
parser.add_argument('--auto-control-plane', help='enable automatic control plane population', action="store_true")
parser.add_argument('--json', help='Path to JSON config file',
                    type=str, action="store", required=True)
parser.add_argument('--pcap-dump', help='Dump packets on interfaces to pcap files',
                    action="store_true")
parser.add_argument('--manifest', '-m', help='Path to manifest file',
                    type=str, action="store", required=True)
parser.add_argument('--target', '-t', help='Target in manifest file to run',
                    type=str, action="store", required=True)
parser.add_argument('--log-dir', '-l', help='Location to save output to',
                    type=str, action="store", required=True)

args = parser.parse_args()


next_thrift_port = args.thrift_port

def run_command(command):
    return os.WEXITSTATUS(os.system(command))

def configureP4Switch(**switch_args):
    class ConfiguredP4Switch(P4Switch):
        def __init__(self, *opts, **kwargs):
            global next_thrift_port
            kwargs.update(switch_args)
            kwargs['thrift_port'] = next_thrift_port
            next_thrift_port += 1
            P4Switch.__init__(self, *opts, **kwargs)
    return ConfiguredP4Switch


def main():

    with open(args.manifest, 'r') as f:
        manifest = json.load(f)

    conf = manifest['targets'][args.target]
    params = conf['parameters'] if 'parameters' in conf else {}

    os.environ.update(dict(map(lambda (k,v): (k, str(v)), params.iteritems())))

    def formatParams(s):
        for param in params:
            s = re.sub('\$'+param+'(\W|$)', str(params[param]) + r'\1', s)
            s = s.replace('${'+param+'}', str(params[param]))
        return s

    AppTopo = apptopo.AppTopo
    AppController = appcontroller.AppController

    if 'topo_module' in conf:
        sys.path.insert(0, os.path.dirname(args.manifest))
        topo_module = importlib.import_module(conf['topo_module'])
        AppTopo = topo_module.CustomAppTopo

    if 'controller_module' in conf:
        sys.path.insert(0, os.path.dirname(args.manifest))
        controller_module = importlib.import_module(conf['controller_module'])
        AppController = controller_module.CustomAppController

    if not os.path.isdir(args.log_dir):
        if os.path.exists(args.log_dir): raise Exception('Log dir exists and is not a dir')
        os.mkdir(args.log_dir)
    os.environ['P4APP_LOGDIR'] = args.log_dir


    links = [l[:2] for l in conf['links']]
    latencies = dict([(''.join(sorted(l[:2])), l[2]) for l in conf['links'] if len(l)==3])

    for host_name in sorted(conf['hosts'].keys()):
        host = conf['hosts'][host_name]
        if 'latency' not in host: continue
        for a, b in links:
            if a != host_name and b != host_name: continue
            other = a if a != host_name else b
            latencies[host_name+other] = host['latency']

    for l in latencies:
        if isinstance(latencies[l], (str, unicode)):
            latencies[l] = formatParams(latencies[l])
        else:
            latencies[l] = str(latencies[l]) + "ms"

    bmv2_log = args.bmv2_log or ('bmv2_log' in conf and conf['bmv2_log'])
    pcap_dump = args.pcap_dump or ('pcap_dump' in conf and conf['pcap_dump'])

    topo = AppTopo(links, latencies, manifest=manifest, target=args.target,
                  log_dir=args.log_dir)
    switchClass = configureP4Switch(
            sw_path=args.behavioral_exe,
            json_path=args.json,
            log_console=bmv2_log,
            pcap_dump=pcap_dump)
    net = Mininet(topo = topo,
                  link = TCLink,
                  host = P4Host,
                  switch = switchClass,
                  controller = None)
    net.start()

    sleep(1)

    controller = None
    if args.auto_control_plane or 'controller_module' in conf:
        controller = AppController(manifest=manifest, target=args.target,topo=topo, net=net, links=links)
        controller.start()

    for host in net.hosts:
        if "h1" in host.name:
            h1 = host;
        if "h2" in host.name:
            h2 = host;
        if "h3" in host.name:
            h3 = host;
        if "h4" in host.name:
            h4 = host;

    h1.cmd('tc qdisc del dev %s-eth0 root' % host.name ,shell=True)
    h1.cmd('ifconfig %s-eth0 mtu 2000 up'% host.name ,shell=True)
    h1.cmd('tc qdisc add dev %s-eth0 root tbf rate 16Mbit latency 10ms burst 2000' % host.name,shell=True)

    h3.cmd('iperf -s &')
    h1.cmd('iperf -s &')
    h1.cmd('sudo python3 -m http.server 80 &')

    subprocess.Popen('sudo ../sink/sink s4-eth2 127.0.0.1 6666 &',shell=True)
    sleep(60)

    def setupLinks(capacity):
        for interface in ['s1-eth1', 's1-eth2', 's2-eth1', 's2-eth2', 's2-eth3', 's3-eth1', 's3-eth2', 's3-eth3','s4-eth1','s4-eth2']:
            call('tc qdisc del dev %s root' % interface ,shell=True)
            call('ifconfig %s mtu 2000 up'% interface ,shell=True)
            call('tc qdisc add dev %s root tbf rate %skbit latency 10ms burst 2000' % (interface, capacity),shell=True)

    def runTest(method,nom_cap,num_videos):
        setupLinks(nom_cap)
        call('sudo rm ./.cplayer*',shell=True)
        print "Running: " + str(method) + "," + str(nom_cap) + "," + str(num_videos)
        for x in range(0,num_videos):
            h3.cmd('./cplayer 10.0.1.10 video 32 %s > .cplayer%s &' % (x,x))
        sleep(120)
        print "  Testing"
        h1.cmd('ping 10.0.3.10 -i 0.1 -c 600 -q | tail -n 2 > .pingdata &')
        h2.cmd('ping 10.0.4.10 -i 1 -c 60 -q -s 0 > /dev/null &')
        sleep(480)
        sleep(120)
        call('./gatherData.sh %s %s %s' % (method,nom_cap,num_videos), shell=True)
        call('sudo rm -f .capestd',shell=True) 
        call('sudo touch .capestd',shell=True) 
        call('sudo killall capestd',shell=True)

    def runBatch(repetitions):
        for x in range(0,repetitions):
            runTest("Video_Control"+args.json,4000,1)
            runTest("Video_Control"+args.json,6000,1)
            runTest("Video_Control"+args.json,6000,2)
            runTest("Video_Control"+args.json,8000,1)
            runTest("Video_Control"+args.json,8000,3)
            runTest("Video_Control"+args.json,10000,2)
            runTest("Video_Control"+args.json,10000,4)
            runTest("Video_Control"+args.json,12000,1)
            runTest("Video_Control"+args.json,12000,5)
            runTest("Video_Control"+args.json,14000,1)
            runTest("Video_Control"+args.json,14000,5)
            runTest("Video_Control"+args.json,14000,6)
            runTest("Video_Control"+args.json,16000,1)
            runTest("Video_Control"+args.json,16000,6)
            runTest("Video_Control"+args.json,16000,7)

    #Run Test
    runBatch(4)

    #if args.cli or ('cli' in conf and conf['cli']):
    #    CLI(net)

    stdout_files = dict()
    return_codes = []
    host_procs = []


    def formatCmd(cmd):
        for h in net.hosts:
            cmd = cmd.replace(h.name, h.defaultIntf().updateIP())
        return cmd

    def _wait_for_exit(p, host):
        print p.communicate()
        if p.returncode is None:
            p.wait()
            print p.communicate()
        return_codes.append(p.returncode)
        if host_name in stdout_files:
            stdout_files[host_name].flush()
            stdout_files[host_name].close()

    print '\n'.join(map(lambda (k,v): "%s: %s"%(k,v), params.iteritems())) + '\n'

    for host_name in sorted(conf['hosts'].keys()):
        host = conf['hosts'][host_name]
        if 'cmd' not in host: continue

        h = net.get(host_name)
        stdout_filename = os.path.join(args.log_dir, h.name + '.stdout')
        stdout_files[h.name] = open(stdout_filename, 'w')
        cmd = formatCmd(host['cmd'])
        print h.name, cmd
        p = h.popen(cmd, stdout=stdout_files[h.name], shell=True, preexec_fn=os.setpgrp)
        if 'startup_sleep' in host: sleep(host['startup_sleep'])

        if 'wait' in host and host['wait']:
            _wait_for_exit(p, host_name)
        else:
            host_procs.append((p, host_name))

    for p, host_name in host_procs:
        if 'wait' in conf['hosts'][host_name] and conf['hosts'][host_name]['wait']:
            _wait_for_exit(p, host_name)

    for p, host_name in host_procs:
        if 'wait' in conf['hosts'][host_name] and conf['hosts'][host_name]['wait']:
            continue
        if p.returncode is None:
            run_command('pkill -INT -P %d' % p.pid)
            sleep(0.2)
            rc = run_command('pkill -0 -P %d' % p.pid) # check if it's still running
            if rc == 0: # the process group is still running, send TERM
                sleep(1) # give it a little more time to exit gracefully
                run_command('pkill -TERM -P %d' % p.pid)
        _wait_for_exit(p, host_name)

    if 'after' in conf and 'cmd' in conf['after']:
        cmds = conf['after']['cmd'] if type(conf['after']['cmd']) == list else [conf['after']['cmd']]
        for cmd in cmds:
            os.system(cmd)

    if controller: controller.stop()


    net.stop()

#    if bmv2_log:
#        os.system('bash -c "cp /tmp/p4s.s*.log \'%s\'"' % args.log_dir)
#    if pcap_dump:
#        os.system('bash -c "cp *.pcap \'%s\'"' % args.log_dir)

    bad_codes = [rc for rc in return_codes if rc != 0]
    if len(bad_codes): sys.exit(1)

if __name__ == '__main__':
    setLogLevel( 'info' )
    main()
