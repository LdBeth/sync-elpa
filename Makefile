all: out

out: elpa.ss sync-elpa.ss
	scheme build.ss

clean:
	rm *.so *.wpo out
