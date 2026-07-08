enum AppEnvironment { dev, staging, prod }

class AppConfig {
  static AppEnvironment environment = AppEnvironment.dev;

  static String get baseUrl {
    switch (environment) {
      case AppEnvironment.dev:
        return 'http://epos4.host/mobiguard/backend/public/api';
      case AppEnvironment.staging:
        return 'https://staging.mobiguard-sales.com/api';
      case AppEnvironment.prod:
        return 'https://api.mobiguard-sales.com/api';
    }
  }

  static void setEnvironment(AppEnvironment env) {
    environment = env;
  }
}
