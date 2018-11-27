all: sink capest_visualizer

sink: sink.c
	gcc sink.c -lpcap -o sink
capest_visualizer: capest_visualizer.c
	gcc capest_visualizer.c -o capest_visualizer

clean:
	rm -f sink capest_visualizer
