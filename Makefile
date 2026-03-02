BINARY  := setup
BIN_DIR := bin
CMD     := ./cmd/setup

.PHONY: build install clean run status

build:
	go build -o $(BIN_DIR)/$(BINARY) $(CMD)

install: build
	cp $(BIN_DIR)/$(BINARY) $(HOME)/.local/bin/$(BINARY)

clean:
	rm -rf $(BIN_DIR)

run: build
	$(BIN_DIR)/$(BINARY)

status: build
	$(BIN_DIR)/$(BINARY) status

tidy:
	go mod tidy

init-submodules:
	git submodule update --init --recursive

update-submodules:
	git submodule update --remote --merge
