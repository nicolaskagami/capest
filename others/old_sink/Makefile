all: sink capest capestd

sink: sink.c
	gcc sink.c -lpcap -o sink
capest: capest.c
	gcc capest.c -o capest -lm
capestd: capest_d_visualizer.c
	gcc capest_d_visualizer.c -o capestd -lm

clean:
	rm capest sink capestd
