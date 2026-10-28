#include <cstdio>

namespace mplay {
static const char* kAppName = "M-PLAY PS4";
static const char* kVersion = "0.1.0-dev";
static const char* kCreator = "Mourtadhoi DJAFFAR";
static const char* kBrand = "Mourtadhoi Art";
static const char* kEmail = "Mourtadhoi.djaffar@gmail.com";
static const char* kSocial = "@Mourtadhoi.art";

void printAbout() {
    std::printf("A propos\n");
    std::printf("Application concue par : %s\n", kCreator);
    std::printf("Graphic designer : %s\n", kBrand);
    std::printf("E-mail : %s\n", kEmail);
    std::printf("Reseaux sociaux : %s\n", kSocial);
}

void printFeatureStatus() {
    std::printf("\nModules prevus (non encore actifs dans ce prototype) :\n");
    std::printf("  [ ] IPTV M3U / M3U8 et flux HTTP(S)\n");
    std::printf("  [ ] Lecteurs MP4 et MP3\n");
    std::printf("  [ ] Gestionnaire de fichiers interne / USB\n");
    std::printf("  [ ] Navigation DualShock 4 et interface graphique\n");
    std::printf("  [ ] Sons d'interface, horloge et parametres persistants\n");
}
}

int main() {
    std::printf("\n");
    std::printf("============================================\n");
    std::printf("  %s  |  version %s\n", mplay::kAppName, mplay::kVersion);
    std::printf("  MEDIA CENTER HOMEBREW - PROTOTYPE\n");
    std::printf("============================================\n");
    std::printf("Ce binaire valide uniquement le point d'entree natif.\n");
    std::printf("L'interface graphique et les fonctions media restent a developper.\n\n");
    mplay::printAbout();
    mplay::printFeatureStatus();
    std::printf("\nM-PLAY : base de developpement initialisee.\n");
    return 0;
}
