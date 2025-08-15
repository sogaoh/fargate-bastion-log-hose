# Makefile for build & deploy Lambda with lambroll
.PHONY: build package deploy clean

LAMBDA_DIR := ..
DIST_DIR := $(LAMBDA_DIR)/dist
ZIP_FILE := $(LAMBDA_DIR)/function.zip

build:
	cd $(LAMBDA_DIR) && python -m venv venv
	cd $(LAMBDA_DIR) && . venv/bin/activate && pip install -r requirements.txt
	mkdir -p $(DIST_DIR)
	cp $(LAMBDA_DIR)/lambda_function.py $(DIST_DIR)/

package: build
	cd $(DIST_DIR) && zip -r $(ZIP_FILE) .

deploy: package
	cd $(CURDIR) && lambroll deploy --src $(ZIP_FILE)

clean:
	rm -rf $(DIST_DIR)
	rm -f $(ZIP_FILE)
	rm -rf $(LAMBDA_DIR)/venv
