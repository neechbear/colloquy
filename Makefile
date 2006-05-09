-include config

default:
	rm -rf build/*
	cd src; $(MAKE)
	cp -r src/colloquy$(EXE) src/colua$(EXE) src/config.lua data build/
	rm -f build/data/bans build/data/*.lua

clean:
	rm -rf build/*
	cd src; $(MAKE) clean

dist-clean: clean
	rm -f config

config:
	./configure
