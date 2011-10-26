#
#   Makefile for Parameter
#
#   Copyright(c) 2004-2006, Samsung Electronics, Co., Ltd.
#

obj-m	:= param.o

EXTRA_CFLAGS += -I$(PRJROOT)/modules/fsr/Inc

all:
	@echo "$(MAKE) --no-print-directory -C $(KDIR) SUBDIRS=$(CURDIR) modules"
	@$(MAKE) --no-print-directory -C $(KDIR) \
		SUBDIRS=$(CURDIR) modules

clean:
	rm -f *.o *.ko *.mod.* *~ .*.cmd Module.symvers modules.order

install:
	@$(MAKE) --no-print-directory -C $(KDIR) \
		SUBDIRS=$(CURDIR) modules_install
