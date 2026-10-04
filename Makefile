PYTHON ?= python3
SJASM ?= sjasmplus
# OUTPUT mode writes the resources in a row after the resident part; the ORG warnings are expected
SJASM_FLAGS ?= -Wno-fileorg
PROGRAM ?= FBIRD

SRC_DIR := src
ASSETS_DIR := assets
BUILD_DIR := build
DIST_DIR := $(BUILD_DIR)/$(PROGRAM)
IMAGE_TEMPLATE := $(SRC_DIR)/image/dss_image.img
IMAGE := $(BUILD_DIR)/$(PROGRAM).img

# MAME "sprinter" autotest (tools/run_mame.sh, tools/mame_fbird.lua); every path can be overridden
MAME_DIR ?= /Users/dmitry/dev/zx/sprinter/mame_images/mame_release_v306_25.05.2025
MAME ?= $(MAME_DIR)/mame
DSS_IMAGE ?= $(MAME_DIR)/IMG/sp_hdd_sys.chd
TEST_DIR := $(BUILD_DIR)/autotest
TEST_IMAGE := $(TEST_DIR)/$(PROGRAM).img
MAME_ENV := MAME="$(MAME)" MAME_DIR="$(MAME_DIR)" DSS_IMAGE="$(DSS_IMAGE)" PYTHON="$(PYTHON)"

.PHONY: all cut resources exe image clean test-exe test-image test-emulator run run-test

all: image

cut:
	cd $(ASSETS_DIR) && $(PYTHON) ../tools/imagecutter.py cut.txt

resources: cut
	mkdir -p $(ASSETS_DIR)/resources
	cd $(ASSETS_DIR)/resources && $(PYTHON) ../../tools/resources.py ../res.txt
	cd $(ASSETS_DIR)/resources && $(PYTHON) ../../tools/resources.py ../title_res.txt
	cat $(ASSETS_DIR)/resources/bird0.bin $(ASSETS_DIR)/resources/bird1.bin $(ASSETS_DIR)/resources/bird2.bin $(ASSETS_DIR)/resources/bird3.bin > $(ASSETS_DIR)/resources/birds.bin
	cat $(ASSETS_DIR)/resources/tube0dn.bin $(ASSETS_DIR)/resources/tube0up.bin $(ASSETS_DIR)/resources/tube0md.bin $(ASSETS_DIR)/resources/tube1dn.bin $(ASSETS_DIR)/resources/tube1up.bin $(ASSETS_DIR)/resources/tube1md.bin > $(ASSETS_DIR)/resources/tubes.bin
	cat $(ASSETS_DIR)/resources/big_digit*.bin $(ASSETS_DIR)/resources/small_digit*.bin $(ASSETS_DIR)/resources/coin*.bin $(ASSETS_DIR)/resources/medal_placeholder.bin $(ASSETS_DIR)/resources/ui_hand.bin $(ASSETS_DIR)/resources/title_get_ready.bin $(ASSETS_DIR)/resources/title_game_over.bin $(ASSETS_DIR)/resources/title_flappybird.bin > $(ASSETS_DIR)/resources/ui.bin
	$(PYTHON) tools/wav2sfx.py --out-dir $(ASSETS_DIR)/resources --asm $(ASSETS_DIR)/resources/sfx_len.asm --rate 7812 $(ASSETS_DIR)/sfx/wav/hit.wav $(ASSETS_DIR)/sfx/wav/die.wav $(ASSETS_DIR)/sfx/wav/point.wav
	mkdir -p $(SRC_DIR)/assets
	cp $(ASSETS_DIR)/resources/res_pal.asm $(SRC_DIR)/res_pal.asm
	cp $(ASSETS_DIR)/resources/title_res_pal.asm $(SRC_DIR)/title_pal.asm
	cp $(ASSETS_DIR)/resources/sfx_len.asm $(SRC_DIR)/sfx_len.asm
	cp $(ASSETS_DIR)/resources/city.bin $(ASSETS_DIR)/resources/cityn.bin $(ASSETS_DIR)/resources/way.bin $(ASSETS_DIR)/resources/birds.bin $(ASSETS_DIR)/resources/tubes.bin $(ASSETS_DIR)/resources/ui.bin $(ASSETS_DIR)/resources/gopanel.bin $(ASSETS_DIR)/resources/font.bin $(ASSETS_DIR)/resources/title.bin $(ASSETS_DIR)/resources/title.b00 $(ASSETS_DIR)/resources/title.b01 $(ASSETS_DIR)/resources/title.b02 $(ASSETS_DIR)/resources/title.b03 $(ASSETS_DIR)/resources/title.b04 $(ASSETS_DIR)/resources/hit.raw $(ASSETS_DIR)/resources/die.raw $(ASSETS_DIR)/resources/point.raw $(SRC_DIR)/assets/

# FBIRD.EXE is a monoblock: the resources from src/assets are included into it
exe: resources
	cd $(SRC_DIR) && $(SJASM) $(SJASM_FLAGS) fbird.asm --lst=fbird.lst

image: exe
	mkdir -p $(BUILD_DIR)
	cp $(IMAGE_TEMPLATE) $(IMAGE)
	mmd -i $(IMAGE) ::/$(PROGRAM)
	mcopy -o -i $(IMAGE) $(SRC_DIR)/$(PROGRAM).EXE ::/$(PROGRAM)/
	mkdir -p $(DIST_DIR)
	rm -rf $(DIST_DIR)/ASSETS
	cp $(SRC_DIR)/$(PROGRAM).EXE $(DIST_DIR)/

# AUTOTEST build: immortal bird + per-page state records for the emulator script (never shipped)
test-exe: exe
	mkdir -p $(TEST_DIR)
	cd $(SRC_DIR) && $(SJASM) $(SJASM_FLAGS) fbird.asm -DAUTOTEST=1 --sym=../$(TEST_DIR)/fbird.sym --lst=../$(TEST_DIR)/fbird.lst

test-image: test-exe
	cp $(IMAGE_TEMPLATE) $(TEST_IMAGE)
	mmd -i $(TEST_IMAGE) ::/$(PROGRAM)
	mcopy -o -i $(TEST_IMAGE) $(TEST_DIR)/$(PROGRAM).EXE ::/$(PROGRAM)/

# Plays the AUTOTEST build in MAME and checks every frame; report and screenshots in build/autotest/
test-emulator: test-image
	$(MAME_ENV) tools/run_mame.sh test $(TEST_IMAGE) $(TEST_DIR)/fbird.sym

run: image
	$(MAME_ENV) tools/run_mame.sh run $(IMAGE)

# The AUTOTEST build (immortal bird) in a MAME window, to watch it by eye
run-test: test-image
	$(MAME_ENV) tools/run_mame.sh run $(TEST_IMAGE)

clean:
	rm -rf $(BUILD_DIR) $(ASSETS_DIR)/cutted $(ASSETS_DIR)/resources $(SRC_DIR)/assets $(SRC_DIR)/res_pal.asm $(SRC_DIR)/title_pal.asm $(SRC_DIR)/sfx_len.asm $(SRC_DIR)/FBIRD.EXE $(SRC_DIR)/fbird.lst
