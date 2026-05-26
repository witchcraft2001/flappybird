PYTHON ?= python3
SJASM ?= sjasmplus
PROGRAM ?= FBIRD

SRC_DIR := src
ASSETS_DIR := assets
BUILD_DIR := build
DIST_DIR := $(BUILD_DIR)/$(PROGRAM)
IMAGE_TEMPLATE := $(SRC_DIR)/image/dss_image.img
IMAGE := $(BUILD_DIR)/$(PROGRAM).img

.PHONY: all cut resources exe image clean

all: image

cut:
	cd $(ASSETS_DIR) && $(PYTHON) ../tools/imagecutter.py cut.txt

resources: cut
	mkdir -p $(ASSETS_DIR)/resources
	cd $(ASSETS_DIR)/resources && $(PYTHON) ../../tools/resources.py ../res.txt
	cat $(ASSETS_DIR)/resources/bird0.bin $(ASSETS_DIR)/resources/bird1.bin $(ASSETS_DIR)/resources/bird2.bin > $(ASSETS_DIR)/resources/birds.bin
	cat $(ASSETS_DIR)/resources/tube0dn.bin $(ASSETS_DIR)/resources/tube0up.bin $(ASSETS_DIR)/resources/tube0md.bin $(ASSETS_DIR)/resources/tube1dn.bin $(ASSETS_DIR)/resources/tube1up.bin $(ASSETS_DIR)/resources/tube1md.bin > $(ASSETS_DIR)/resources/tubes.bin
	mkdir -p $(SRC_DIR)/assets
	cp $(ASSETS_DIR)/resources/res_pal.asm $(SRC_DIR)/res_pal.asm
	cp $(ASSETS_DIR)/resources/city.bin $(ASSETS_DIR)/resources/way.bin $(ASSETS_DIR)/resources/birds.bin $(ASSETS_DIR)/resources/tubes.bin $(SRC_DIR)/assets/

exe: resources
	cd $(SRC_DIR) && $(SJASM) fbird.asm --lst=fbird.lst

image: exe
	mkdir -p $(BUILD_DIR)
	cp $(IMAGE_TEMPLATE) $(IMAGE)
	mmd -i $(IMAGE) ::/$(PROGRAM)
	mmd -i $(IMAGE) ::/$(PROGRAM)/ASSETS
	mcopy -o -i $(IMAGE) $(SRC_DIR)/$(PROGRAM).EXE ::/$(PROGRAM)/
	mcopy -o -i $(IMAGE) $(SRC_DIR)/assets/*.b* ::/$(PROGRAM)/ASSETS/
	mkdir -p $(DIST_DIR)/ASSETS
	cp $(SRC_DIR)/$(PROGRAM).EXE $(DIST_DIR)/
	cp $(SRC_DIR)/assets/*.b* $(DIST_DIR)/ASSETS/

clean:
	rm -rf $(BUILD_DIR) $(ASSETS_DIR)/cutted $(ASSETS_DIR)/resources $(SRC_DIR)/assets $(SRC_DIR)/res_pal.asm $(SRC_DIR)/FBIRD.EXE $(SRC_DIR)/fbird.lst
