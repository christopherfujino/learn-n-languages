GO = go
BUILD_DIR = out
BINARY = $(BUILD_DIR)/main

$(BINARY): main.go
	$(GO) build -o $(BINARY) .

run: $(BINARY)
	$(BINARY)
