all: sink capest

sink: sink.c
	gcc sink.c -lpcap -o sink
capest: capest.c
	gcc capest.c -o capest -lm

clean:
	rm capest sink
