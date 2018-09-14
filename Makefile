# Makefile

GOPATH = $(shell pwd)/build/_workspace
GOBIN  = $(GOPATH)/bin
DIR    = $(GOPATH)/src/github.com/metadium/metadium-demo
BINDIR = $(DIR)/build/bin

all: cmet

cmet: build-env
	cd $(DIR) &&							   \
	GOPATH=$(GOPATH) go build -o build/bin/$@			   \
		github.com/metadium/metadium-demo/cmet &&		   \
	cp vendor/github.com/metadium/go-metadium/metadium/scripts/solc.sh \
		build/bin/;

test: build-env
	cd $(DIR); go test

clean:
	cd $(DIR); go clean
	@[ ! -d build/bin ] || /bin/rm -r build/bin

build-env: check_submodule
	@if [ ! -d build ]; then					    \
		echo "Setting up build directory...";			    \
		mkdir -p build/bin					    \
			build/_workspace/src/github.com/metadium;	    \
		ln -sf ../../../../..					    \
		    build/_workspace/src/github.com/metadium/metadium-demo; \
	fi;

check_submodule: vendor/github.com/metadium/go-metadium/.git

vendor/github.com/metadium/go-metadium/.git:
	@if [ ! -d vendor/github.com/ethereum/go-ethereum ]; then	\
		mkdir -p vendor/github.com/ethereum;			\
		ln -sf ../metadium/go-metadium				\
			vendor/github.com/ethereum/go-ethereum;		\
	fi;								\
	if [ ! -d vendor/github.com/metadium/go-metadium/.git ] ; then	\
		git submodule init;					\
		git submodule update;					\
	fi

vendor-sync: build-env
	git submodule init;					\
	git submodule update;

.PHONY: clean build-env vendor-sync

# EOF
