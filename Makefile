CXX = g++
CXXFLAGS = -std=c++17 -O2 -Wall

PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin
VUZADIR = $(HOME)/.vuza

all: vuza

vuza: src/vuza.cpp src/vuza.h
	$(CXX) $(CXXFLAGS) src/vuza.cpp -o vuza

install: vuza
	install -d $(BINDIR) $(VUZADIR)
	install -m 755 vuza $(BINDIR)/vuza
	install -m 644 src/prelude.scm $(VUZADIR)/prelude.scm
	
uninstall: vuza
	rm -f $(BINDIR)/vuza
	rm -rf $(VUZADIR)

clean:
	rm -f vuza

.PHONY: all clean 

