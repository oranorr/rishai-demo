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
  paywall('paywall', '/paywall'),
  contactPage('contact', '/contact'),
  chat('chat', '/chat');

  const AppRoutes(this.name, this.path);
  final String name;
  final String path;
}
