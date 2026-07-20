enum Environment { devPC, devMobile, prod }

class AppConfig {
  // Choisis l'environnement actif
  static const Environment env = Environment.prod;

  // Base URL selon l'environnement
  static String get apiBaseUrl {
    switch (env) {
      case Environment.devPC:
        return "http://localhost:8099/Sale_manager_API"; // serveur PHP local (php -S)
      case Environment.devMobile:
        return "http://10.0.2.2:8099/Sale_manager_API"; // 10.0.2.2 = hôte, vu depuis l'émulateur Android
      case Environment.prod:
        return "https://riphin-salemanager.com/Sale_manager_API"; // futur serveur en ligne
    }
  }
}
