CC = clang
CFLAGS = -Wall
OBJECTS = main.o
BUILD_DIR = out
BINARY = $(BUILD_DIR)/main

$(BINARY): main.o $(BUILD_DIR)
	echo 'starting release build at $(BINARY)'
	$(CC) -o $(BINARY) $(OBJECTS)

run: $(BINARY)
	echo 'running binary...'
	$(BINARY)

$(OBJECTS): main.c
	echo 'compile source files.'
	$(CC) -c main.c

# Ensure output dir exists
$(BUILD_DIR):
	echo 'ensure out dir exists.'
	mkdir -p $(BUILD_DIR)

clean:
	echo 'clean artifacts.'
	rm -rf $(BUILD_DIR) $(OBJECTS)
