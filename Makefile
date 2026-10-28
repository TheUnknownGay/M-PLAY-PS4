# ============================================================
# M-PLAY PS4 — OpenOrbis Makefile
# ============================================================

TITLE       := M-PLAY PS4
VERSION     := 01.00
TITLE_ID    := MPLY00001
CONTENT_ID  := IV0000-MPLY00001_00-MPLAYPS400000000

# OpenOrbis SDK
TOOLCHAIN   := /lib/OpenOrbisSDK
PKG         := $(TOOLCHAIN)/bin/linux

# Project directories
SRCDIR      := src
INTDIR      := build
PROJ        := mplay

# Output files
OUT_ELF     := $(INTDIR)/$(PROJ).elf
OUT_OELF    := $(INTDIR)/$(PROJ).oelf
OUT_EBOOT   := eboot.bin
OUT_PKG     := $(CONTENT_ID).pkg

# Compiler and linker
CC          := clang
CXX         := clang++
LD          := ld.lld

# FSELF generator built by GitHub Actions
CREATE_FSELF := tools/create-fself

# Core libraries
CORE_LIBS := -lc -lkernel -lc++ -lSceLibcInternal

# Discover SDK library stubs
ALL_STUBS := $(sort \
	$(patsubst $(TOOLCHAIN)/lib/lib%.so,-l%,$(wildcard $(TOOLCHAIN)/lib/lib*.so)) \
	$(patsubst $(TOOLCHAIN)/lib/lib%.a,-l%,$(wildcard $(TOOLCHAIN)/lib/lib*.a)) \
)

EXTRA_LIBS := $(filter-out $(CORE_LIBS),$(ALL_STUBS))

# Compilation flags
CFLAGS := \
	--target=x86_64-pc-freebsd12-elf \
	-fPIC \
	-funwind-tables \
	-c \
	-isysroot $(TOOLCHAIN) \
	-isystem $(TOOLCHAIN)/include

CXXFLAGS := $(CFLAGS) \
	-isystem $(TOOLCHAIN)/include/c++/v1

# Linker flags
# crt1.o is passed before the program objects in the link command.
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

# Source files
CPPFILES := $(wildcard $(SRCDIR)/*.cpp)
CFILES   := $(wildcard $(SRCDIR)/*.c)

OBJS := \
	$(patsubst $(SRCDIR)/%.cpp,$(INTDIR)/%.o,$(CPPFILES)) \
	$(patsubst $(SRCDIR)/%.c,$(INTDIR)/%.o,$(CFILES))

# Package assets and optional modules
LIBMODULES := $(wildcard sce_module/*)
ASSETS := $(shell find assets -type f 2>/dev/null | LC_ALL=C sort)

# ============================================================
# Targets
# ============================================================

.PHONY: all clean check-toolchain

all: $(OUT_PKG)

# Build directory
$(INTDIR):
	mkdir -p $(INTDIR)

# Validate required SDK files and tools
check-toolchain:
	@set -e; \
	command -v "$(CC)" >/dev/null; \
	command -v "$(CXX)" >/dev/null; \
	command -v "$(LD)" >/dev/null; \
	test -x "$(CREATE_FSELF)" || { echo "ERROR: $(CREATE_FSELF) missing or not executable"; exit 1; }; \
	test -x "$(PKG)/PkgTool.Core" || { echo "ERROR: PkgTool.Core missing"; exit 1; }; \
	test -f "$(TOOLCHAIN)/link.x" || { echo "ERROR: link.x missing"; exit 1; }; \
	test -f "$(TOOLCHAIN)/lib/crt1.o" || { echo "ERROR: crt1.o missing"; exit 1; }; \
	test -d "$(TOOLCHAIN)/lib" || { echo "ERROR: SDK lib directory missing"; exit 1; }; \
	echo "OpenOrbis toolchain checks passed."

# Compile C++ files
$(INTDIR)/%.o: $(SRCDIR)/%.cpp | $(INTDIR)
	$(CXX) $(CXXFLAGS) -o $@ $<

# Compile C files
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
	readelf -h $(OUT_ELF)
	readelf -Ws $(OUT_ELF) | grep -E '(_init|_fini)' || true
	$(CREATE_FSELF) \
		-in=$(OUT_ELF) \
		-out=$(OUT_OELF) \
		--eboot "$(OUT_EBOOT)" \
		--paid 0x3100000000000001 \
		-library-path="$(TOOLCHAIN)/lib"
	@test -f "$(OUT_EBOOT)" || { echo "ERROR: eboot.bin was not generated"; exit 1; }

# Generate param.sfo
sce_sys/param.sfo: Makefile
	mkdir -p sce_sys
	$(PKG)/PkgTool.Core sfo_new $@
	$(PKG)/PkgTool.Core sfo_setentry $@ --key APP_TYPE --value 1 --type integer
	$(PKG)/PkgTool.Core sfo_setentry $@ --key APP_VER --value "$(VERSION)" --type text
	$(PKG)/PkgTool.Core sfo_setentry $@ --key CATEGORY --value gd --type text
	$(PKG)/PkgTool.Core sfo_setentry $@ --key CONTENT_ID --value "$(CONTENT_ID)" --type text
	$(PKG)/PkgTool.Core sfo_setentry $@ --key TITLE --value "$(TITLE)" --type text
	$(PKG)/PkgTool.Core sfo_setentry $@ --key TITLE_ID --value "$(TITLE_ID)" --type text

# Generate GP4 package description
pkg.gp4: $(OUT_EBOOT) sce_sys/param.sfo sce_sys/icon0.png $(LIBMODULES) $(ASSETS)
	python3 tools/make_gp4.py \
		--out $@ \
		--content-id $(CONTENT_ID) \
		$(OUT_EBOOT) \
		sce_sys/param.sfo \
		sce_sys/icon0.png \
		$(LIBMODULES) \
		$(ASSETS)

# Build final PKG
$(OUT_PKG): pkg.gp4 | check-toolchain
	$(PKG)/PkgTool.Core pkg_build $< .

# Clean generated files
clean:
	rm -rf $(INTDIR) $(OUT_EBOOT) pkg.gp4 sce_sys/param.sfo *.pkg
