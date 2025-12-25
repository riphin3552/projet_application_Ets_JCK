enum Environment { devPC, devMobile, prod }

class AppConfig {
  // Choisis l'environnement actif
  static const Environment env = Environment.prod;

  // Base URL selon l'environnement
  static String get apiBaseUrl {
    switch (env) {
      case Environment.devPC:
        return "http://localhost/Sale_manager_API"; // sur émulateur ou PC
      case Environment.devMobile:
        return "http://192.168.1.4/Sale_manager_API"; // sur téléphone réel
      case Environment.prod:
        return "https://riphin-salemanager.com/Sale_manager_API"; // futur serveur en ligne
    }
  }
}
