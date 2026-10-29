
# ============================================================
# M-PLAY PS4 — Makefile OpenOrbis
# ============================================================

TITLE       := M-PLAY PS4
VERSION     := 01.00
TITLE_ID    := MPLY00001
CONTENT_ID  := IV0000-MPLY00001_00-MPLAYPS400000000

# Chemins du SDK
TOOLCHAIN   := /lib/OpenOrbisSDK
SDK_LIB     := $(TOOLCHAIN)/lib
SDK_BIN     := $(TOOLCHAIN)/bin/linux

# Outils
CXX         := $(SDK_BIN)/clang++
LD          := ld.lld
PKGTOOL     := $(SDK_BIN)/PkgTool.Core
CREATE_FSELF := tools/create-fself
PYTHON      := python3

# Sources et sorties
SOURCE      := src/main.cpp
BUILD_DIR   := build
OBJECT      := $(BUILD_DIR)/main.o
OUT_ELF     := $(BUILD_DIR)/mplay.elf
OUT_OELF    := $(BUILD_DIR)/mplay.oelf
OUT_EBOOT   := eboot.bin
OUT_SFO     := sce_sys/param.sfo
OUT_GP4     := pkg.gp4
OUT_PKG     := $(CONTENT_ID).pkg

# Compilation PS4
CXXFLAGS := \
	--target=x86_64-pc-freebsd12-elf \
	-fPIC \
	-funwind-tables \
	-fuse-init-array \
	-c \
	-isysroot $(TOOLCHAIN) \
	-isystem $(TOOLCHAIN)/include \
	-isystem $(TOOLCHAIN)/include/c++/v1

# Liaison PS4
LDFLAGS := \
	-m elf_x86_64 \
	-pie \
	--script $(TOOLCHAIN)/link.x \
	--eh-frame-hdr \
	-L$(SDK_LIB)

LIBS := -lc -lkernel -lc++ -lSceLibcInternal

.PHONY: all clean check-tools check-files sfo gp4 pkg

all: pkg

# ------------------------------------------------------------
# Vérifier les outils et fichiers indispensables
# ------------------------------------------------------------

check-tools:
	@test -x "$(CXX)" || { echo "ERREUR : clang++ introuvable : $(CXX)"; exit 1; }
	@test -x "$(PKGTOOL)" || { echo "ERREUR : PkgTool.Core introuvable : $(PKGTOOL)"; exit 1; }
	@test -x "$(CREATE_FSELF)" || { echo "ERREUR : create-fself introuvable ou non exécutable"; exit 1; }
	@test -f "$(TOOLCHAIN)/lib/crt1.o" || { echo "ERREUR : crt1.o absent"; exit 1; }
	@test -f "$(TOOLCHAIN)/link.x" || { echo "ERREUR : link.x absent"; exit 1; }
	@test -f "$(SOURCE)" || { echo "ERREUR : source absent : $(SOURCE)"; exit 1; }
	@test -f "tools/make_gp4.py" || { echo "ERREUR : tools/make_gp4.py absent"; exit 1; }
	@test -f "sce_sys/icon0.png" || { echo "ERREUR : sce_sys/icon0.png absent"; exit 1; }

check-files:
	@test -s "$(OUT_EBOOT)" || { echo "ERREUR : eboot.bin absent ou vide"; exit 1; }
	@test -s "$(OUT_SFO)" || { echo "ERREUR : param.sfo absent ou vide"; exit 1; }
	@test -s "sce_sys/icon0.png" || { echo "ERREUR : icon0.png absent ou vide"; exit 1; }

# ------------------------------------------------------------
# Préparer les répertoires
# ------------------------------------------------------------

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

sce_sys:
	mkdir -p sce_sys

# ------------------------------------------------------------
# Compiler le code C++
# ------------------------------------------------------------

$(OBJECT): $(SOURCE) | $(BUILD_DIR) check-tools
	@echo "==> Compilation de $(SOURCE)"
	$(CXX) $(CXXFLAGS) -o $@ $<

# ------------------------------------------------------------
# Créer l'ELF
# ------------------------------------------------------------

$(OUT_ELF): $(OBJECT)
	@echo "==> Liaison de l'ELF"
	$(LD) $(LDFLAGS) -o $@ \
		$(TOOLCHAIN)/lib/crt1.o \
		$(OBJECT) \
		$(LIBS)
	@test -s "$@" || { echo "ERREUR : ELF absent ou vide"; exit 1; }

# ------------------------------------------------------------
# Créer l'OELF et eboot.bin
# ------------------------------------------------------------

$(OUT_EBOOT): $(OUT_ELF) check-tools
	@echo "==> Création de eboot.bin"
	$(CREATE_FSELF) \
		-in=$(OUT_ELF) \
		-out=$(OUT_OELF) \
		--eboot "$(OUT_EBOOT)" \
		--paid 0x3100000000000001 \
		--library-path="$(SDK_LIB)"
	@test -s "$(OUT_OELF)" || { echo "ERREUR : OELF absent ou vide"; exit 1; }
	@test -s "$(OUT_EBOOT)" || { echo "ERREUR : eboot.bin absent ou vide"; exit 1; }

# ------------------------------------------------------------
# Générer sce_sys/param.sfo
# ------------------------------------------------------------

sfo: $(OUT_SFO)

$(OUT_SFO): | sce_sys check-tools
	@echo "==> Génération de $(OUT_SFO)"
	rm -f "$@"
	$(PKGTOOL) sfo_new "$@"
	$(PKGTOOL) sfo_setentry "$@" APP_TYPE --type Integer --maxsize 4 --value 1
	$(PKGTOOL) sfo_setentry "$@" APP_VER --type Utf8 --maxsize 8 --value "$(VERSION)"
	$(PKGTOOL) sfo_setentry "$@" ATTRIBUTE --type Integer --maxsize 4 --value 0
	$(PKGTOOL) sfo_setentry "$@" CATEGORY --type Utf8 --maxsize 4 --value "gd"
	$(PKGTOOL) sfo_setentry "$@" CONTENT_ID --type Utf8 --maxsize 48 --value "$(CONTENT_ID)"
	$(PKGTOOL) sfo_setentry "$@" DOWNLOAD_DATA_SIZE --type Integer --maxsize 4 --value 0
	$(PKGTOOL) sfo_setentry "$@" SYSTEM_VER --type Integer --maxsize 4 --value 0
	$(PKGTOOL) sfo_setentry "$@" TITLE --type Utf8 --maxsize 128 --value "$(TITLE)"
	$(PKGTOOL) sfo_setentry "$@" TITLE_ID --type Utf8 --maxsize 12 --value "$(TITLE_ID)"
	$(PKGTOOL) sfo_setentry "$@" VERSION --type Utf8 --maxsize 8 --value "$(VERSION)"
	@test -s "$@" || { echo "ERREUR : param.sfo non généré"; exit 1; }
	@echo "==> Vérification des entrées SFO"
	$(PKGTOOL) sfo_listentries "$@"

# ------------------------------------------------------------
# Créer le projet GP4
# ------------------------------------------------------------

gp4: $(OUT_GP4)

$(OUT_GP4): $(OUT_EBOOT) $(OUT_SFO) sce_sys/icon0.png tools/make_gp4.py
	@echo "==> Création du projet GP4"
	$(PYTHON) tools/make_gp4.py \
		--out "$(OUT_GP4)" \
		--content-id "$(CONTENT_ID)" \
		"$(OUT_EBOOT)" \
		"$(OUT_SFO)" \
		"sce_sys/icon0.png"
	@test -s "$@" || { echo "ERREUR : pkg.gp4 absent ou vide"; exit 1; }

# ------------------------------------------------------------
# Construire le PKG
# ------------------------------------------------------------

pkg: $(OUT_PKG)

$(OUT_PKG): $(OUT_GP4)
	@echo "==> Vérification des fichiers avant empaquetage"
	$(MAKE) check-files
	@echo "==> Construction du PKG"
	$(PKGTOOL) pkg_build "$(OUT_GP4)" .
	@test -s "$@" || { echo "ERREUR : PKG non généré : $@"; exit 1; }
	@echo "==> PKG généré : $@"
	@ls -lh "$@"

# ------------------------------------------------------------
# Nettoyage
# ------------------------------------------------------------

clean:
	rm -rf $(BUILD_DIR)
	rm -f "$(OUT_EBOOT)" "$(OUT_OELF)" "$(OUT_GP4)" "$(OUT_PKG)"
	rm -f "$(OUT_SFO)"
	@echo "==> Nettoyage terminé"
