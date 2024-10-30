enum AppRoutes {
  splah('splash', '/splash'),
  login('login', '/login'),
  enterOtp('enterOtp', '/enterOtp'),
  homeScreen('home', '/home'),
  onboard('onboard', '/onboard'),
  whoopConnect('whoopConnect', '/whoopConnect'),
  redirect('redirect', '/redirect'),
  questionary('questionary', '/questionary'),
  profileSettings('profileSettings', '/profileSettings'),
  connectionSettings('connectionSettings', '/connectionSettings'),
  notificationsSettings('notificationsSettings', '/notificationsSettings'),
  otherSettings('otherSettings', '/otherSettings'),
  calibratingScreen('calibratingScreen', '/calibratingScreen'),
  // legalPage('legalPage', '/legalPage'),
  chat('chat', '/chat');

  final String name;
  final String path;

  const AppRoutes(this.name, this.path);
}
