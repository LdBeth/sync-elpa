all: out sync

out sync: elpa.ss sync-elpa.ss rsync.ss
	scheme build.ss

clean:
	rm *.so *.wpo out
