ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifneq (,$(findstring arm64,$(MEMO_TARGET)))

SUBPROJECTS    += golb
GOLB_COMMIT    := 7ffffff93cf753ba114da6e36bcf50a6cbcc96c4
GOLB_VERSION   := 1.0.1+git20210403.$(shell echo $(GOLB_COMMIT) | cut -c -7)
DEB_GOLB_V     ?= $(GOLB_VERSION)

golb-setup: setup
	-[ ! -e "$(BUILD_SOURCE)/golb-v$(GOLB_COMMIT).tar.gz" ] \
		&& wget -nc -O$(BUILD_SOURCE)/golb-v$(GOLB_COMMIT).tar.gz \
			https://github.com/0x7ff/golb/archive/$(GOLB_COMMIT).tar.gz
	$(call EXTRACT_TAR,golb-v$(GOLB_COMMIT).tar.gz,golb-$(GOLB_COMMIT),golb)
	mkdir -p $(BUILD_STAGE)/golb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifneq ($(wildcard $(BUILD_WORK)/golb/.build_complete),)
golb:
	@echo "Using previously built golb."
else
golb: golb-setup
	$(CC) $(CFLAGS) \
		-framework IOKit \
		-framework CoreFoundation \
		-lcompression \
		$(BUILD_WORK)/golb/golb.c \
		$(BUILD_WORK)/golb/aes_ap.c \
		-o $(BUILD_STAGE)/golb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/aes_ap
	$(CC) $(CFLAGS) \
		-framework IOKit \
		-framework CoreFoundation \
		-lcompression \
		$(BUILD_WORK)/golb/golb_ppl.c \
		$(BUILD_WORK)/golb/aes_ap.c \
		-o $(BUILD_STAGE)/golb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/aes_ap_ppl
	touch $(BUILD_WORK)/golb/.build_complete
endif

golb-package: golb-stage
	# golb.mk Package Structure
	rm -rf $(BUILD_DIST)/golb
	mkdir -p $(BUILD_DIST)/golb

	# golb.mk Prep golb
	cp -a $(BUILD_STAGE)/golb/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) $(BUILD_DIST)/golb

	# golb.mk Sign
	$(call SIGN,golb,tfp0.xml)

	# golb.mk Make .debs
	$(call PACK,golb,DEB_GOLB_V)

	# golb.mk Build cleanup
	rm -rf $(BUILD_DIST)/golb

.PHONY: golb golb-package

endif