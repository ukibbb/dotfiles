.PHONY: build install clean test run init

BINARY_NAME=uzzy
BUILD_DIR=build
INSTALL_DIR=$(HOME)/.local/bin

build:
	go build -o $(BUILD_DIR)/$(BINARY_NAME) ./cmd/uzzy

install: build
	mkdir -p $(INSTALL_DIR)
	cp $(BUILD_DIR)/$(BINARY_NAME) $(INSTALL_DIR)/
	@echo "Installed to $(INSTALL_DIR)/$(BINARY_NAME)"
	@echo "Make sure $(INSTALL_DIR) is in your PATH"

clean:
	rm -rf $(BUILD_DIR)

test:
	go test -v ./...

run: build
	./$(BUILD_DIR)/$(BINARY_NAME)

init: build
	./$(BUILD_DIR)/$(BINARY_NAME) --init
