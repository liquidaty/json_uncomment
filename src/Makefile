# compile for debugging: make RELEASE=0
# compile for release:   make RELEASE=1

WIN=0
RELEASE=1

ifneq ($(findstring w64,$(CC)),) # mingw64
	WIN=64
endif

ifeq ($(RELEASE),1)
  CFLAGS= -O3
else
  CFLAGS= -g -O0
endif

ifeq ($(WIN),64)
  EXE=64.exe
  WINLIB=-lwsock32 -loleaut32
  WINDEFS= -D__USE_MINGW_ANSI_STDIO -D_ISOC99_SOURCE
  CFLAGS+= ${WINLIB} ${WINDEFS}
  DOT_O=.w64o
else
  DOT_O=.o
endif

INSTALL_PATH=/usr/local

help: 
	@echo "Makes json_uncomment and json_uncomment_untracked; installs json_uncomment"
	@echo "make [WIN=1] [help|all|install|uninstall|clean]"

all:	json_uncomment${EXE} json_uncomment_untracked${EXE}

json_uncomment${EXE}: json_uncomment.lex.c
	$(CC) ${CFLAGS} -o $@ json_uncomment.lex.c

json_uncomment_untracked${EXE}: json_uncomment.lex.c
	$(CC) ${CFLAGS} -DNO_TRACKING -o $@ json_uncomment.lex.c

json_uncomment.lex.c: json_uncomment.l
	@flex -o json_uncomment.lex.c json_uncomment.l

install: json_uncomment${EXE}
	cp -p json_uncomment${EXE} ${INSTALL_PATH}/bin

uninstall:
	rm -f ${INSTALL_PATH}/bin/json_uncomment${EXE}

clean:
	rm -f json.lex.[ch] json_uncomment${EXE}

.PHONY: help all install uninstall clean
