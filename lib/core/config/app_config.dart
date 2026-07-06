enum AppEnvironment { dev, staging, prod }

class AppConfig {
  static AppEnvironment environment = AppEnvironment.dev;
  static bool useMockData = false; // Disable mock data to use real API

  static String get baseUrl {
    switch (environment) {
      case AppEnvironment.dev:
        return 'http://epos4.host/mobiguard/backend/public/api'; // remote dev server
      case AppEnvironment.staging:
        return 'https://staging.mobiguard-sales.com/api';
      case AppEnvironment.prod:
        return 'https://api.mobiguard-sales.com/api';
    }
  }

  static void setEnvironment(AppEnvironment env) {
    environment = env;
  }

  static void setMockMode(bool enabled) {
    useMockData = enabled;
  }
}
