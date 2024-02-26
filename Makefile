MAKEFLAGS += --no-builtin-rules
SHELL := /bin/bash

# Can be used as a shorthand to add dependencies to all gfx files
# at once
GFX_ALL_REPL := gfx_all

.SUFFIXES:
.PHONY: all bundle_src bundle_tar bundle_zip clean install maintainer-clean \
        uninstall $(GFX_ALL_REPL)

include Makefile.config


### Filename definitions, can be overridden in Makefile.config
# REPO_NAME and BASE_FILENAME should almost always be overridden
REPO_NAME ?= $(notdir $(shell pwd))
BASE_FILENAME ?= $(REPO_NAME)

# Base paths
BUILD_DIR ?= build
SRC_DIR ?= src

# Docs
DOC_DIR ?= docs
DOC_FILENAMES ?= changelog.txt license.txt readme.txt
DOC_FILES := $(addprefix $(DOC_DIR)/, $(DOC_FILENAMES))

# Lang-related
DEFAULT_LANG ?= english.lng
CUSTOM_TAGS ?= $(BUILD_DIR)/custom_tags.txt
LANG_SRC_DIR ?= $(SRC_DIR)/lang
LANG_CONSTANT ?= $(LANG_SRC_DIR)/constant.txt
LANG_BUILD_DIR ?= $(BUILD_DIR)

DEFAULT_LANG_SRC := $(LANG_SRC_DIR)/$(DEFAULT_LANG)
DEFAULT_LANG_BUILD := $(LANG_BUILD_DIR)/$(DEFAULT_LANG)
OTHER_LANG_SRC := $(shell find $(LANG_SRC_DIR) -name "*.lng" \
                    -not -name $(DEFAULT_LANG))
OTHER_LANG_BUILD := $(OTHER_LANG_SRC:$(LANG_SRC_DIR)/%=$(LANG_BUILD_DIR)/%)
LANG_ALL := $(DEFAULT_LANG_BUILD) $(OTHER_LANG_BUILD)

# grf
PNML_FILE ?= $(SRC_DIR)/$(BASE_FILENAME).pnml
NML_FILE ?= $(BUILD_DIR)/$(BASE_FILENAME).nml
GRF_FILE ?= $(BASE_FILENAME).grf

# Keep track of all build dirs we need to create
BUILD_DIRS ?= $(BUILD_DIR) $(LANG_BUILD_DIR)

# Dependency files
NML_DEP := $(BUILD_DIR)/$(notdir $(NML_FILE)).dep
GRF_DEP := $(BUILD_DIR)/$(notdir $(GRF_FILE)).dep


# Replacement strings which are added to custom.tags and replaced in
# the .txt files output from .ptxt
# These need to be enclosed in double brakets in .ptxt files
REPLACE_GRF_FILENAME := GRF_FILENAME
REPLACE_GRF_VERSION := GRF_VERSION
REPLACE_GRF_TITLE := GRF_TITLE
REPLACE_REPO_VERSION := REPO_VERSION


# Set the variable CLEAN if targets are clean-only
# Also define INCLUDE_NOCLEAN function to conditionally include only if
# CLEAN is unset
ifdef MAKECMDGOALS
ifeq ($(filter-out %clean,$(MAKECMDGOALS)),)
CLEAN = true
endif
endif
ifndef CLEAN
INCLUDE_NOCLEAN = $(foreach a, $1, $(eval include $$(a)))
endif


### Program definitions
CC ?= cc
CC_FLAGS ?= -C -E -nostdinc -x c-header
HG ?= hg
ifdef NMLC_MONKEY
NML ?= ./nmlc_monkey
else
NML ?= nmlc
endif
NML_FLAGS ?= --custom-tags=$(CUSTOM_TAGS) --default-lang=$(DEFAULT_LANG) \
             --lang-dir=$(LANG_BUILD_DIR)


### Info from findversion
VERSION_INFO := "$(shell ./findversion.sh)"
# The version reported to OpenTTD. Usually days since 2000 + branch offset
GRF_VERSION := $(shell echo $(VERSION_INFO) | cut -f2)
# Whether there are local changes
REPO_MODIFIED := $(shell echo $(VERSION_INFO) | cut -f3)
# Any tag which is not 'tip'
REPO_TAGS := $(shell echo $(VERSION_INFO) | cut -f4 | sed 's/ /\\ /g')
# The shown version is either a tag, or in the absence of a tag the revision.
REPO_VERSION := $(shell echo $(VERSION_INFO) | cut -f5)
USED_VCS := $(shell echo $(VERSION_INFO) | cut -f8)
# The title consists of name and version
ifeq ($(REPO_TAGS),)
FILE_VERSION_STRING := $(GRF_VERSION)$(REPO_MODIFIED)
else
FILE_VERSION_STRING := $(REPO_TAGS)$(REPO_MODIFIED)
endif
TAR_STEM := $(BASE_FILENAME)
TAR_FILE := $(TAR_STEM)-$(FILE_VERSION_STRING).tar
TAR_SRC_FILE := $(TAR_STEM)-$(FILE_VERSION_STRING)-source.tar
ZIP_FILE := $(TAR_STEM)-$(FILE_VERSION_STRING).zip


### Targets called from command line
all: $(GRF_FILE)

ifndef CLEAN
$(shell mkdir -p $(BUILD_DIRS))
endif
$(call INCLUDE_NOCLEAN, $(NML_DEP))
-include Makefile.in

bundle_src:
ifeq ($(USED_VCS), hg)
	HGPLAIN= hg archive -X .devzone -t tar $(TAR_SRC_FILE)
else ifeq ($(USED_VCS), git)
	git archive -o $(TAR_SRC_FILE) HEAD
else
	@echo "Unknown version control system, can't build source package."
	@false
endif
bundle_tar: $(TAR_FILE)
bundle_zip: $(ZIP_FILE)
clean::
	rm -rf $(BUILD_DIR) $(BASE_FILENAME)*.{grf,tar,zip}
maintainer-clean:: clean
	rm -rf .nmlcache

ifeq ($(shell uname -s), Linux)
ifndef DESTDIR
DESTDIR := $(HOME)/.openttd/newgrf
endif
install: $(TAR_FILE) uninstall
	cp $(TAR_FILE) $(DESTDIR)
uninstall:
	rm -f $(DESTDIR)/$(TAR_STEM)*.tar
else
install uninstall:
	@echo "Error: Only Linux install supported."
	@false
endif


### Other targets called by other rules and includes

## grf
# Two passes are needed - once to rebuild any pnml files, and another to
# build the nml file, and in turn, the grf dependencies
# include the grf dependency file in the nml file to induce a second pass
$(NML_DEP): $(PNML_FILE)
	$(CC) $(CC_FLAGS) -M $(PNML_FILE) -MF $@ -MG -MT $(NML_FILE)
	echo '$$(call INCLUDE_NOCLEAN, $$(GRF_DEP))' >> $@
$(NML_FILE): $(PNML_FILE)
	$(CC) -D GRF_VERSION=$(GRF_VERSION) $(CC_FLAGS) -o $@ $(PNML_FILE)
$(GRF_DEP): $(NML_FILE) $(CUSTOM_TAGS) $(DEFAULT_LANG_BUILD)
	$(NML) $(NML_FLAGS) -M --MF=$@ --MT=$(GRF_FILE) $(NML_FILE)
	gfx_files=() ; while read -r line ; do \
            gfx_files+=("$${line#*: }") ; \
        done < $@ ; \
        echo "$(GFX_ALL_REPL) := $${gfx_files[@]}" >> $@
$(GRF_FILE): $(NML_FILE) $(CUSTOM_TAGS) $(LANG_ALL)
	$(NML) $(NML_FLAGS) -c --grf=$@ $(NML_FILE)

## lang
$(CUSTOM_TAGS):
	> $@
	echo "$(REPLACE_GRF_FILENAME) :$(GRF_FILE)" >> $@
	echo "$(REPLACE_GRF_TITLE) :$(REPO_NAME)" >> $@
	echo "$(REPLACE_GRF_VERSION) :$(GRF_VERSION)" >> $@
	echo "$(REPLACE_REPO_VERSION) :$(REPO_VERSION)" >> $@
$(DEFAULT_LANG_BUILD): $(DEFAULT_LANG_SRC) $(LANG_CONSTANT)
	cat $^ > $@
$(LANG_BUILD_DIR)/%.lng: $(LANG_SRC_DIR)/%.lng
	cp $< $@

## packaging
$(TAR_FILE): $(GRF_FILE) $(DOC_FILES)
	tar -cf $@ --transform 's,^,$(BASE_FILENAME)/,' $(GRF_FILE) -C $(DOC_DIR) $(DOC_FILENAMES)
$(ZIP_FILE): $(TAR_FILE)
	zip -9 $(ZIP_FILE) $(TAR_FILE)
