VERSION_KNOTS := "23.0"
VERSION_S9 := "23.0.0"
MANAGER_SRC := $(shell find ./manager -name '*.rs') manager/Cargo.toml manager/Cargo.lock

.DELETE_ON_ERROR:

all: verify

clean:
	rm bitcoin-knots.s9pk
	rm image.tar

bitcoin-knots.s9pk: manifest.yaml assets/compat/* image.tar instructions.md
	embassy-sdk pack

verify: bitcoin-knots.s9pk
	embassy-sdk verify s9pk bitcoin-knots.s9pk

install: bitcoin-knots.s9pk
	embassy-cli package install bitcoin-knots.s9pk

image.tar: Dockerfile docker_entrypoint.sh manager/target/aarch64-unknown-linux-musl/release/bitcoind-manager manifest.yaml check-rpc.sh check-synced.sh
        DOCKER_CLI_EXPERIMENTAL=enabled docker buildx build --tag start9/bitcoind/main:$(VERSION_S9) --build-arg BITCOIN_VERSION=$(VERSION_CORE) --build-arg N_PROC=$(shell expr $(shell nproc) - 1) --platform=linux/arm64 -o type=docker,dest=image.tar .

manager/target/aarch64-unknown-linux-musl/release/bitcoind-manager: $(MANAGER_SRC)
	docker run --rm -it -v ~/.cargo/registry:/root/.cargo/registry -v "$(shell pwd)"/manager:/home/rust/src start9/rust-musl-cross:aarch64-musl cargo build --release

