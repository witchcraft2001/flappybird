PYTHON ?= python3
SJASM ?= sjasmplus
PROGRAM ?= FBIRD

SRC_DIR := src
ASSETS_DIR := assets
BUILD_DIR := build
DIST_DIR := $(BUILD_DIR)/$(PROGRAM)
IMAGE_TEMPLATE := $(SRC_DIR)/image/dss_image.img
IMAGE := $(BUILD_DIR)/$(PROGRAM).img
GAME_ASSETS := city.bin way.bin birds.bin tubes.bin ui.bin gopanel.bin font.bin title.bin title.b00 title.b01 title.b02 title.b03 title.b04 music.bin hit.raw die.raw point.raw

.PHONY: all cut resources exe image clean

all: image

cut:
	cd $(ASSETS_DIR) && $(PYTHON) ../tools/imagecutter.py cut.txt

resources: cut
	mkdir -p $(ASSETS_DIR)/resources
	cd $(ASSETS_DIR)/resources && $(PYTHON) ../../tools/resources.py ../res.txt
	cd $(ASSETS_DIR)/resources && $(PYTHON) ../../tools/resources.py ../title_res.txt
	cat $(ASSETS_DIR)/resources/bird0.bin $(ASSETS_DIR)/resources/bird1.bin $(ASSETS_DIR)/resources/bird2.bin $(ASSETS_DIR)/resources/bird3.bin > $(ASSETS_DIR)/resources/birds.bin
	cat $(ASSETS_DIR)/resources/tube0dn.bin $(ASSETS_DIR)/resources/tube0up.bin $(ASSETS_DIR)/resources/tube0md.bin $(ASSETS_DIR)/resources/tube1dn.bin $(ASSETS_DIR)/resources/tube1up.bin $(ASSETS_DIR)/resources/tube1md.bin > $(ASSETS_DIR)/resources/tubes.bin
	cat $(ASSETS_DIR)/resources/big_digit*.bin $(ASSETS_DIR)/resources/small_digit*.bin $(ASSETS_DIR)/resources/coin*.bin $(ASSETS_DIR)/resources/ui_hand.bin $(ASSETS_DIR)/resources/title_get_ready.bin $(ASSETS_DIR)/resources/title_game_over.bin $(ASSETS_DIR)/resources/title_flappybird.bin > $(ASSETS_DIR)/resources/ui.bin
	$(PYTHON) tools/wav2sfx.py --out-dir $(ASSETS_DIR)/resources --asm $(ASSETS_DIR)/resources/sfx_len.asm $(ASSETS_DIR)/sfx/wav/hit.wav $(ASSETS_DIR)/sfx/wav/die.wav $(ASSETS_DIR)/sfx/wav/point.wav
	mkdir -p $(SRC_DIR)/assets
	cp $(ASSETS_DIR)/resources/res_pal.asm $(SRC_DIR)/res_pal.asm
	cp $(ASSETS_DIR)/resources/title_res_pal.asm $(SRC_DIR)/title_pal.asm
	cp $(ASSETS_DIR)/resources/sfx_len.asm $(SRC_DIR)/sfx_len.asm
	cp $(ASSETS_DIR)/resources/city.bin $(ASSETS_DIR)/resources/way.bin $(ASSETS_DIR)/resources/birds.bin $(ASSETS_DIR)/resources/tubes.bin $(ASSETS_DIR)/resources/ui.bin $(ASSETS_DIR)/resources/gopanel.bin $(ASSETS_DIR)/resources/font.bin $(ASSETS_DIR)/resources/title.bin $(ASSETS_DIR)/resources/title.b00 $(ASSETS_DIR)/resources/title.b01 $(ASSETS_DIR)/resources/title.b02 $(ASSETS_DIR)/resources/title.b03 $(ASSETS_DIR)/resources/title.b04 $(ASSETS_DIR)/resources/hit.raw $(ASSETS_DIR)/resources/die.raw $(ASSETS_DIR)/resources/point.raw $(SRC_DIR)/assets/

exe: resources
	cd $(SRC_DIR) && $(SJASM) fbird.asm --lst=fbird.lst

image: exe
	mkdir -p $(BUILD_DIR)
	cp $(IMAGE_TEMPLATE) $(IMAGE)
	mmd -i $(IMAGE) ::/$(PROGRAM)
	mmd -i $(IMAGE) ::/$(PROGRAM)/ASSETS
	mcopy -o -i $(IMAGE) $(SRC_DIR)/$(PROGRAM).EXE ::/$(PROGRAM)/
	$(foreach asset,$(GAME_ASSETS),mcopy -o -i $(IMAGE) $(SRC_DIR)/assets/$(asset) ::/$(PROGRAM)/ASSETS/$(asset);)
	mkdir -p $(DIST_DIR)/ASSETS
	cp $(SRC_DIR)/$(PROGRAM).EXE $(DIST_DIR)/
	$(foreach asset,$(GAME_ASSETS),cp $(SRC_DIR)/assets/$(asset) $(DIST_DIR)/ASSETS/$(asset);)

clean:
	rm -rf $(BUILD_DIR) $(ASSETS_DIR)/cutted $(ASSETS_DIR)/resources $(SRC_DIR)/assets $(SRC_DIR)/res_pal.asm $(SRC_DIR)/title_pal.asm $(SRC_DIR)/sfx_len.asm $(SRC_DIR)/FBIRD.EXE $(SRC_DIR)/fbird.lst
