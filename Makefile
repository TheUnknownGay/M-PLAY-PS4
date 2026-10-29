
# ============================================================
# M-PLAY PS4 — OpenOrbis Makefile
# ============================================================

TITLE       := M-PLAY PS4
VERSION     := 01.00
TITLE_ID    := MPLY00001
CONTENT_ID  := IV0000-MPLY00001_00-MPLAYPS400000000

TOOLCHAIN   := /lib/OpenOrbisSDK
PKG         := $(TOOLCHAIN)/bin/linux

SRCDIR      := src
INTDIR      := build
PROJ        := mplay

OUT_ELF     := $(INTDIR)/$(PROJ).elf
OUT_OELF    := $(INTDIR)/$(PROJ).oelf
OUT_EBOOT   := eboot.bin
OUT_PKG     := $(CONTENT_ID).pkg

CC          := clang
CXX         := clang++
LD          := ld.lld

CREATE_FSELF := tools/create-fself

CORE_LIBS := -lc -lkernel -lc++ -lSceLibcInternal

ALL_STUBS := $(sort \
	$(patsubst $(TOOLCHAIN)/lib/lib%.so,-l%,$(wildcard $(TOOLCHAIN)/lib/lib*.so)) \
	$(patsubst $(TOOLCHAIN)/lib/lib%.a,-l%,$(wildcard $(TOOLCHAIN)/lib/lib*.a)) \
)

EXTRA_LIBS := $(filter-out $(CORE_LIBS),$(ALL_STUBS))

CFLAGS := \
	--target=x86_64-pc-freebsd12-elf \
	-fPIC \
	-funwind-tables \
	-c \
	-isysroot $(TOOLCHAIN) \
	-isystem $(TOOLCHAIN)/include

CXXFLAGS := $(CFLAGS) \
	-isystem $(TOOLCHAIN)/include/c++/v1

LDFLAGS := \
	-m elf_x86_64 \
	-pie \
	--script $(TOOLCHAIN)/link.x \
	--eh-frame-hdr \
	-L$(TOOLCHAIN)/lib \
	$(CORE_LIBS) \
	--as-needed \
	$(EXTRA_LIBS) \
	--no-as-needed

CPPFILES := $(wildcard $(SRCDIR)/*.cpp)
CFILES   := $(wildcard $(SRCDIR)/*.c)

OBJS := \
	$(patsubst $(SRCDIR)/%.cpp,$(INTDIR)/%.o,$(CPPFILES)) \
	$(patsubst $(SRCDIR)/%.c,$(INTDIR)/%.o,$(CFILES))

LIBMODULES := $(wildcard sce_module/*)
ASSETS := $(shell find assets -type f 2>/dev/null | LC_ALL=C sort)

.PHONY: all clean check-toolchain verify-package-metadata

all: $(OUT_PKG)

$(INTDIR):
	mkdir -p $(INTDIR)

check-toolchain:
	@set -eu; \
	command -v "$(CC)" >/dev/null; \
	command -v "$(CXX)" >/dev/null; \
	command -v "$(LD)" >/dev/null; \
	test -x "$(CREATE_FSELF)" || { echo "ERROR: create-fself absent"; exit 1; }; \
	test -x "$(PKG)/PkgTool.Core" || { echo "ERROR: PkgTool.Core absent"; exit 1; }; \
	test -f "$(TOOLCHAIN)/link.x" || { echo "ERROR: link.x absent"; exit 1; }; \
	test -f "$(TOOLCHAIN)/lib/crt1.o" || { echo "ERROR: crt1.o absent"; exit 1; }; \
	echo "OpenOrbis toolchain checks passed."

$(INTDIR)/%.o: $(SRCDIR)/%.cpp | $(INTDIR)
	$(CXX) $(CXXFLAGS) -o $@ $<

$(INTDIR)/%.o: $(SRCDIR)/%.c | $(INTDIR)
	$(CC) $(CFLAGS) -o $@ $<

# Link ELF, then generate FSELF and eboot.bin
$(OUT_EBOOT): $(OBJS) | check-toolchain
	$(LD) \
		$(TOOLCHAIN)/lib/crt1.o \
		$(OBJS) \
		-o $(OUT_ELF) \
		$(LDFLAGS)
	@echo "=== ELF information ==="
	file $(OUT_ELF)
	$(CREATE_FSELF) \
		-in=$(OUT_ELF) \
		-out=$(OUT_OELF) \
		--eboot "$(OUT_EBOOT)" \
		--paid 0x3100000000000001 \
		-library-path="$(TOOLCHAIN)/lib"
	@test -s "$(OUT_EBOOT)" || { echo "ERROR: eboot.bin absent ou vide"; exit 1; }

# Generate param.sfo with the official PkgTool argument order
sce_sys/param.sfo: Makefile | check-toolchain
	mkdir -p sce_sys
	rm -f "$@"
	$(PKG)/PkgTool.Core sfo_new $@
	$(PKG)/PkgTool.Core sfo_setentry $@ APP_TYPE --type Integer --maxsize 4 --value 1
	$(PKG)/PkgTool.Core sfo_setentry $@ APP_VER --type Utf8 --maxsize 8 --value "$(VERSION)"
	$(PKG)/PkgTool.Core sfo_setentry $@ ATTRIBUTE --type Integer --maxsize 4 --value 0
	$(PKG)/PkgTool.Core sfo_setentry $@ CATEGORY --type Utf8 --maxsize 4 --value "gd"
	$(PKG)/PkgTool.Core sfo_setentry $@ CONTENT_ID --type Utf8 --maxsize 48 --value "$(CONTENT_ID)"
	$(PKG)/PkgTool.Core sfo_setentry $@ DOWNLOAD_DATA_SIZE --type Integer --maxsize 4 --value 0
	$(PKG)/PkgTool.Core sfo_setentry $@ SYSTEM_VER --type Integer --maxsize 4 --value 0
	$(PKG)/PkgTool.Core sfo_setentry $@ TITLE --type Utf8 --maxsize 128 --value "$(TITLE)"
	$(PKG)/PkgTool.Core sfo_setentry $@ TITLE_ID --type Utf8 --maxsize 12 --value "$(TITLE_ID)"
	$(PKG)/PkgTool.Core sfo_setentry $@ VERSION --type Utf8 --maxsize 8 --value "$(VERSION)"
	@echo "=== Vérification des entrées SFO ==="
	$(PKG)/PkgTool.Core sfo_listentries $@

# Generate GP4 package description
pkg.gp4: $(OUT_EBOOT) sce_sys/param.sfo sce_sys/icon0.png $(LIBMODULES) $(ASSETS)
	python3 tools/make_gp4.py \
		--out $@ \
		--content-id "$(CONTENT_ID)" \
		$(OUT_EBOOT) \
		sce_sys/param.sfo \
		sce_sys/icon0.png \
		$(LIBMODULES) \
		$(ASSETS)

# Build final PKG
$(OUT_PKG): pkg.gp4 | check-toolchain
	rm -f "$@"
	$(PKG)/PkgTool.Core pkg_build $< .
	@test -s "$@" || { echo "ERROR: PKG absent ou vide"; exit 1; }
	@echo "PKG généré : $@"
	@ls -lh "$@"

clean:
	rm -rf $(INTDIR) $(OUT_EBOOT) pkg.gp4 sce_sys/param.sfo *.pkg
