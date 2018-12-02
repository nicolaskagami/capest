# Capest 
Capest is a tool for estimating capacity and available bandwidth from the data plane. 
It is written in P4 and makes use of a simple In-band Network Telemetry implementation on Network Service Headers. 

## Prerequisites
* [Mininet](http://mininet.org/) - Network emulator
* [p4c](https://github.com/p4lang/p4c) - P4 Compiler
* [p4c-bm](https://github.com/p4lang/p4c-bm) - P4 Behavioral Model
## Installing
--Work in Progress--

## Running Tests
The [build](https://github.com/nicolaskagami/capest/tree/master/build) directory includes a variety of files that constitute a testing environment.
The test scripts serve as high-level tools to run specific scenarios, the results of which are stored in dat files within build. 

## Components
This section briefly explains this repo's multiple interacting components.

### Capest P4 Module
The Capest P4 source code can be found in the p4src folder. 
There are several parameters that can be tuned to balance properties such as accuracy, timeliness, convergence, etc.

### Cplayer
Cplayer is a video client simulator written in C. 
The video client periodically loads chunks of videos segments from the video server until the buffer is full.
The Cplayer also consumes the chunks from the buffer whenever available, accounting for each stall event, length and startup time.

### Sink
The Sink sniffs out packets on an \<interface\>, sending Capest's INT packets into an entity on \<hostname\>:\<port\>, such as the Visualizer.
```
Usage: sink <interface> <hostname> <port>
```

### Visualizer
The Visualizer receives the INT packets from the Sink, deconstructs them and prints the information of Switch ID, estimated Capacity and estimated Available bandwidth.
```
Usage: capest_visualizer <port>
```

### Utils
The utils are scripts that automate the P4 and mininet behaviour, adapted from the [P4 Tutorials](https://github.com/p4lang/tutorials).
Some new scripts were added to specifically test the scenarios envisioned for Capest, which are called from the test scripts in [build](https://github.com/nicolaskagami/capest/tree/master/build)
directory.
A network setup script can be used to alter interface properties on-the-fly for more customized scenarios.
