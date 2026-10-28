
# ============================================================
# M-PLAY PS4 — OpenOrbis build
# ============================================================

TITLE       := M-PLAY PS4
VERSION     := 01.00
TITLE_ID    := MPLY00001
CONTENT_ID  := IV0000-MPLY00001_00-MPLAYPS400000000

# OpenOrbis SDK dans le conteneur officiel
TOOLCHAIN   := /lib/OpenOrbisSDK

SRCDIR      := src
INTDIR      := build
PROJ        := mplay

OUT_ELF     := $(INTDIR)/$(PROJ).elf
OUT_OELF    := $(INTDIR)/$(PROJ).oelf

CC          := clang
CXX         := clang++
LD          := ld.lld

PKG         := $(TOOLCHAIN)/bin/linux

CORE_LIBS   := -lc -lkernel -lc++ -lSceLibcInternal

ALL_STUBS   := $(sort \
                $(patsubst $(TOOLCHAIN)/lib/lib%.so,-l%,$(wildcard $(TOOLCHAIN)/lib/lib*.so)) \
                $(patsubst $(TOOLCHAIN)/lib/lib%.a,-l%,$(wildcard $(TOOLCHAIN)/lib/lib*.a)))

EXTRA_LIBS  := $(filter-out $(CORE_LIBS),$(ALL_STUBS))

CFLAGS      := --target=x86_64-pc-freebsd12-elf \
               -fPIC -funwind-tables -c \
               -isysroot $(TOOLCHAIN) \
               -isystem $(TOOLCHAIN)/include

CXXFLAGS    := $(CFLAGS) \
               -isystem $(TOOLCHAIN)/include/c++/v1

LDFLAGS     := -m elf_x86_64 \
               -pie \
               --script $(TOOLCHAIN)/link.x \
               --eh-frame-hdr \
               -L$(TOOLCHAIN)/lib \
               $(CORE_LIBS) \
               --as-needed $(EXTRA_LIBS) --no-as-needed \
               $(TOOLCHAIN)/lib/crt1.o

CPPFILES    := $(wildcard $(SRCDIR)/*.cpp)
CFILES      := $(wildcard $(SRCDIR)/*.c)

OBJS        := $(patsubst $(SRCDIR)/%.cpp,$(INTDIR)/%.o,$(CPPFILES)) \
               $(patsubst $(SRCDIR)/%.c,$(INTDIR)/%.o,$(CFILES))

LIBMODULES  := $(wildcard sce_module/*)
ASSETS      := $(shell find assets -type f 2>/dev/null | LC_ALL=C sort)

# ============================================================
# Targets
# ============================================================

.PHONY: all clean check-toolchain

all: $(CONTENT_ID).pkg

# Vérifier la présence des outils OpenOrbis
check-toolchain:
	test -x "$(PKG)/create-fself"
	test -x "$(PKG)/PkgTool.Core"
	test -x "$(LD)"

# Créer le dossier intermédiaire
$(INTDIR):
	mkdir -p $(INTDIR)

# Compiler les fichiers C++
$(INTDIR)/%.o: $(SRCDIR)/%.cpp | $(INTDIR)
	$(CXX) $(CXXFLAGS) -o $@ $<

# Compiler les fichiers C
$(INTDIR)/%.o: $(SRCDIR)/%.c | $(INTDIR)
	$(CC) $(CFLAGS) -o $@ $<

# Créer l'exécutable ELF et l'exécutable au format attendu par la PS4
eboot.bin: $(OBJS) | check-toolchain
	$(LD) $(OBJS) -o $(OUT_ELF) $(LDFLAGS)
	$(PKG)/create-fself \
		-in=$(OUT_ELF) \
		-out=$(OUT_OELF) \
		--eboot "eboot.bin" \
		--paid 0x3100000000000001
	cp $(OUT_OELF) eboot.bin

# Générer les métadonnées SFO
sce_sys/param.sfo: Makefile | check-toolchain
	mkdir -p sce_sys
	$(PKG)/PkgTool.Core sfo_new $@
	$(PKG)/PkgTool.Core sfo_setentry $@ APP_TYPE --type Integer --maxsize 4 --value 1
	$(PKG)/PkgTool.Core sfo_setentry $@ APP_VER --type Utf8 --maxsize 8 --value '$(VERSION)'
	$(PKG)/PkgTool.Core sfo_setentry $@ ATTRIBUTE --type Integer --maxsize 4 --value 0
	$(PKG)/PkgTool.Core sfo_setentry $@ CATEGORY --type Utf8 --maxsize 4 --value 'gd'
	$(PKG)/PkgTool.Core sfo_setentry $@ CONTENT_ID --type Utf8 --maxsize 48 --value '$(CONTENT_ID)'
	$(PKG)/PkgTool.Core sfo_setentry $@ DOWNLOAD_DATA_SIZE --type Integer --maxsize 4 --value 0
	$(PKG)/PkgTool.Core sfo_setentry $@ SYSTEM_VER --type Integer --maxsize 4 --value 0
	$(PKG)/PkgTool.Core sfo_setentry $@ TITLE --type Utf8 --maxsize 128 --value '$(TITLE)'
	$(PKG)/PkgTool.Core sfo_setentry $@ TITLE_ID --type Utf8 --maxsize 12 --value '$(TITLE_ID)'
	$(PKG)/PkgTool.Core sfo_setentry $@ VERSION --type Utf8 --maxsize 8 --value '$(VERSION)'

# Créer le fichier de description GP4
pkg.gp4: eboot.bin sce_sys/param.sfo sce_sys/icon0.png $(LIBMODULES) $(ASSETS)
	python3 tools/make_gp4.py \
		--out $@ \
		--content-id $(CONTENT_ID) \
		$^

# Construire le package PKG
$(CONTENT_ID).pkg: pkg.gp4 | check-toolchain
	$(PKG)/PkgTool.Core pkg_build $< .

# Nettoyer les fichiers générés
clean:
	rm -rf $(INTDIR) eboot.bin pkg.gp4 sce_sys/param.sfo *.pkg
