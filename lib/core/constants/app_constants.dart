class AppConstants {
  static const String appName = 'GREAT MINDS GROUP';
  static const String appShortName = 'GM GROUP';
  static const String whatsAppNumber = '243994673769';
  static const String emailContact = 'contact@greatmindsgroup.com';
  static const String address = 'Kinshasa, RD Congo';
  static const String slogan = 'Des solutions concrètes pour la formation, l’insertion professionnelle, l’accompagnement et la création d’opportunités durables.';

  /// Base URL de l'API FastAPI (sans slash final).
  /// En local : backend lancé sur le port 8000.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );

  // Identifiants Super Admin de démonstration (seed FastAPI)
  static const String defaultAdminEmail = 'admin@greatminds.com';
  static const String defaultAdminPassword = 'Admin@GM2026!';
}
