include ../config

default: colloquy colua
clean:
	rm -f *.o colloquy colua bin2c colloquy.c colloquy.luac connections.luac data.lua


colloquy: colloquy.c stub.c wrap.o ltime.o md5lib.o md5.o luasocket.o lposix.o drop.o
	$(CC) $(CFLAGS) -DLUABYTECODE=\"colloquy.c\" -o colloquy stub.c wrap.o ltime.o md5lib.o md5.o luasocket.o lposix.o drop.o $(LUAINC) $(LUALIB) $(EXTRALIBS) $(ZLIB)
	$(STRIPBIN) colloquy

colua: colua.o wrap.o ltime.o md5lib.o md5.o luasocket.o lposix.o drop.o
	$(CC) $(CFLAGS) -o colua colua.o wrap.o ltime.o md5lib.o md5.o luasocket.o lposix.o drop.o $(LUAINC) $(LUALIB) $(EXTRALIBS)
	$(STRIPBIN) colua

colua.o: colua.c
	$(CC) $(CFLAGS) -c -o colua.o colua.c $(LUAINC)

colloquy.c: colloquy.luac bin2c
	./bin2c colloquy.luac > colloquy.c

bin2c:
	$(CC) $(CFLAGS) -o bin2c bin2c.c $(ZLIB)

colloquy.luac: tags.lua smtp.lua db.lua i18n.lua stringstack.lua sockets.lua colouring.lua connections.luac users.lua swearing.lua lists.lua commands.lua main.lua parser.lua colloquy.lua resolver.lua
	$(LUA) -e 'print("__DATE__=[[" .. date("%a %b %d %H:%M:%S %Z %Y") .. "]]")' > data.lua
	echo 'UNAME_SYSTEM = "$(UNAME_SYSTEM)"' >> data.lua
	echo 'UNAME_MACHINE = "$(UNAME_MACHINE)"' >> data.lua
	$(LUAC) $(DEBUGLUA) -o colloquy.luac resolver.lua smtp.lua tags.lua db.lua data.lua i18n.lua stringstack.lua sockets.lua colouring.lua connections.luac users.lua swearing.lua lists.lua commands.lua main.lua parser.lua colloquy.lua

connections.luac: connections.lua eqgen.lua tags.lua colua
	./colua eqgen.lua < connections.lua | $(LUAC) -o connections.luac -

drop.o: drop.c
	$(CC) $(CFLAGS) -c drop.c $(LUAINC)

wrap.o: wrap.c
	$(CC) $(CFLAGS) -c wrap.c $(LUAINC)

ltime.o: ltime.c ltime.h
	$(CC) $(CFLAGS) -c ltime.c $(LUAINC)

luasocket.o: luasocket.c
	$(CC) $(CFLAGS) -c luasocket.c $(LUAINC)

md5lib.o: md5lib.c
	$(CC) $(CFLAGS) -c md5lib.c $(LUAINC)

md5.o: md5.c
	$(CC) $(CFLAGS) -c md5.c $(LUAINC)

lposix.o: lposix.c
	$(CC) $(CFLAGS) -c lposix.c $(LUAINC)
