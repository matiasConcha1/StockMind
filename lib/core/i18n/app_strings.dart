import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/core/i18n/locale_provider.dart';

class AppStrings {
  const AppStrings(this.languageCode);

  final String languageCode;

  bool get _isEnglish => languageCode == 'en';

  String get spanish => 'Español';
  String get english => 'English';
  String get language => _isEnglish ? 'Language' : 'Idioma';

  String get preparingInventoryWorkspace => _isEnglish
      ? 'Preparing your inventory workspace...'
      : 'Preparando tu espacio de inventario...';
  String get checkingSession =>
      _isEnglish ? 'Checking your session...' : 'Verificando tu sesión...';
  String get thisIsTakingLonger => _isEnglish
      ? 'This is taking longer than expected.'
      : 'Esto está tardando más de lo esperado.';
  String get retry => _isEnglish ? 'Retry' : 'Reintentar';
  String get goToLogin => _isEnglish ? 'Go to login' : 'Ir al login';
  String get connectingFirebase =>
      _isEnglish ? 'Connecting to Firebase...' : 'Conectando con Firebase...';
  String get preparingInventory =>
      _isEnglish ? 'Preparing your inventory...' : 'Preparando tu inventario...';
  String get redirecting => _isEnglish ? 'Redirecting...' : 'Redirigiendo...';
  String get preparingAccess =>
      _isEnglish ? 'Preparing access...' : 'Preparando acceso...';
  String get syncingSessionAndTheme => _isEnglish
      ? 'Syncing access, theme and session to open your dashboard.'
      : 'Sincronizando acceso, tema y sesión para abrir tu panel.';

  String get secureAccess => _isEnglish ? 'Secure access' : 'Acceso seguro';
  String get smartInventoryPlatform =>
      _isEnglish ? 'Smart inventory platform' : 'Plataforma inteligente de inventario';
  String get clearInventoryFastOpsRealDecisions => _isEnglish
      ? 'Clear inventory. Fast operations. Real decisions.'
      : 'Inventario claro. Operación veloz. Decisiones reales.';
  String get heroDescription => _isEnglish
      ? 'Control products, alerts and operational performance from a solid visual dashboard built for modern teams.'
      : 'Controla productos, alertas y rendimiento operativo desde un panel visualmente sólido, diseñado para equipos modernos.';
  String get realtime => _isEnglish ? 'Real-time' : 'Tiempo real';
  String get responsive => 'Responsive';
  String get productsMetric => _isEnglish ? 'Products' : 'Productos';
  String get alertsMetric => _isEnglish ? 'Alerts' : 'Alertas';
  String get inventoryMetric => _isEnglish ? 'Inventory' : 'Inventario';
  String get stock => 'Stock';
  String get stablePercent => _isEnglish ? '98% stable' : '98% estable';
  String get controlCenter => _isEnglish ? 'Control center' : 'Centro de control';
  String get weeklyInventoryPerformance =>
      _isEnglish ? 'Weekly inventory performance' : 'Rendimiento semanal del inventario';
  String get criticalAlerts =>
      _isEnglish ? 'Critical alerts' : 'Alertas críticas';

  String get loginTitle => _isEnglish ? 'Sign in' : 'Inicia sesión';
  String get loginSubtitle => _isEnglish
      ? 'Access your stock operation with a clear, secure experience built to grow.'
      : 'Accede a tu operación de stock con una experiencia clara, segura y preparada para crecer.';
  String get email => _isEnglish ? 'Email' : 'Correo electrónico';
  String get enterEmail => _isEnglish ? 'Enter your email' : 'Ingresa tu correo.';
  String get password => _isEnglish ? 'Password' : 'Contraseña';
  String get enterPassword =>
      _isEnglish ? 'Enter your password' : 'Ingresa tu contraseña';
  String get forgotPassword =>
      _isEnglish ? 'Forgot password' : 'Recuperar contraseña';
  String get signingIn => _isEnglish ? 'Signing in...' : 'Ingresando...';
  String get enterStockMind =>
      _isEnglish ? 'Enter StockMind' : 'Entrar a StockMind';
  String get connectingGoogle =>
      _isEnglish ? 'Connecting with Google...' : 'Conectando con Google...';
  String get continueWithGoogle =>
      _isEnglish ? 'Continue with Google' : 'Continuar con Google';
  String get demoTooltip => _isEnglish
      ? 'Create or open an isolated demo workspace and jump straight to the dashboard.'
      : 'Crea o abre un espacio demo aislado por usuario y entra directo al dashboard.';
  String get preparingDemo =>
      _isEnglish ? 'Preparing demo...' : 'Preparando demo...';
  String get enterDemo => _isEnglish ? 'Enter demo' : 'Entrar a demo';
  String get noAccount =>
      _isEnglish ? 'Don\'t have an account?' : '¿No tienes cuenta?';
  String get createAccount =>
      _isEnglish ? 'Create account' : 'Crear cuenta';
  String get rememberSession =>
      _isEnglish ? 'Remember session' : 'Recordar sesión';
  String get keepSessionActive => _isEnglish
      ? 'Keeps your session active on this device'
      : 'Mantiene tu sesión activa en este dispositivo';
  String get missingAccessDataTitle => _isEnglish
      ? 'Missing access data'
      : 'Faltan datos de acceso';
  String get missingAccessDataMessage => _isEnglish
      ? 'You must enter your email and a valid password before continuing.'
      : 'Debes ingresar tu correo y una contraseña válida antes de continuar.';
  String get loginFailedTitle =>
      _isEnglish ? 'Could not sign in' : 'No se pudo iniciar sesión';
  String get verifyCredentials => _isEnglish
      ? 'Check your email and password and try again.'
      : 'Verifica tu correo y contraseña e inténtalo nuevamente.';
  String get demoOpenFailedTitle =>
      _isEnglish ? 'Could not open demo' : 'No se pudo abrir la demo';
  String get demoAuthFailed => _isEnglish
      ? 'We could not authenticate you to prepare the demo workspace.'
      : 'No pudimos autenticarte para preparar el workspace demo.';
  String get activeSessionMissing => _isEnglish
      ? 'We could not find the active session to create the demo.'
      : 'No encontramos la sesión activa para crear la demo.';
  String get demoReadyMessage => _isEnglish
      ? 'Your isolated demo is ready. You can now explore analytics, invitations and multi-workspace flows.'
      : 'Tu demo aislada quedó lista. Ahora puedes recorrer analytics, invitaciones y multiespacio.';
  String get demoPrepareFailedTitle => _isEnglish
      ? 'Could not prepare demo'
      : 'No se pudo preparar la demo';

  String get chooseUsageTitle => _isEnglish
      ? 'How will you use StockMind?'
      : '¿Cómo usarás StockMind?';
  String get chooseUsageSubtitle => _isEnglish
      ? 'Choose your account type for a faster and clearer registration.'
      : 'Elige el tipo de cuenta para mostrar un registro más claro y rápido.';
  String get createYourWorkspace =>
      _isEnglish ? 'Create your workspace' : 'Crea tu espacio';
  String get businessRegisterSubtitle => _isEnglish
      ? 'Set up your user and leave your business base profile ready.'
      : 'Configura tu usuario y deja listo el perfil base de tu negocio.';
  String get personalRegisterSubtitle => _isEnglish
      ? 'Create your personal account and complete company details later if you need them.'
      : 'Crea tu cuenta personal y completa la empresa más adelante si la necesitas.';
  String get businessAccount => _isEnglish ? 'Business / Company' : 'Empresa / Negocio';
  String get personalAccount => _isEnglish ? 'Personal' : 'Persona';
  String get businessAccountDescription => _isEnglish
      ? 'For teams, warehouses or businesses with shared inventory.'
      : 'Para equipos, bodegas o negocios con inventario compartido.';
  String get personalAccountDescription => _isEnglish
      ? 'To manage your personal inventory or small projects.'
      : 'Para controlar tu inventario personal o proyectos pequeños.';
  String get alreadyHaveAccount =>
      _isEnglish ? 'Already have an account?' : '¿Ya tienes cuenta?';
  String get signIn => _isEnglish ? 'Sign in' : 'Ingresar';
  String get back => _isEnglish ? 'Back' : 'Volver';
  String get personalDetails =>
      _isEnglish ? 'Personal details' : 'Datos personales';
  String get name => _isEnglish ? 'Name' : 'Nombre';
  String get enterValidName =>
      _isEnglish ? 'Enter a valid name.' : 'Ingresa un nombre válido.';
  String get emailLabel => _isEnglish ? 'Email' : 'Correo';
  String get passwordLabel => _isEnglish ? 'Password' : 'Contraseña';
  String get passwordMinLength => _isEnglish
      ? 'Password must be at least 6 characters.'
      : 'La contraseña debe tener al menos 6 caracteres.';
  String get confirmPassword =>
      _isEnglish ? 'Confirm password' : 'Confirmar contraseña';
  String get confirmYourPassword => _isEnglish
      ? 'Confirm your password.'
      : 'Confirma tu contraseña.';
  String get passwordsDoNotMatch =>
      _isEnglish ? 'Passwords do not match.' : 'Las contraseñas no coinciden.';
  String get businessDetails =>
      _isEnglish ? 'Business details' : 'Datos de empresa';
  String get businessName =>
      _isEnglish ? 'Business / company name' : 'Nombre del negocio / empresa';
  String get enterBusinessName => _isEnglish
      ? 'Enter the business name.'
      : 'Ingresa el nombre del negocio.';
  String get industry => _isEnglish ? 'Industry' : 'Rubro';
  String get phone => _isEnglish ? 'Phone' : 'Teléfono';
  String get companyEmail =>
      _isEnglish ? 'Company email' : 'Correo empresa';
  String get optionalAddress =>
      _isEnglish ? 'Optional address' : 'Dirección opcional';
  String get optionalWebsite =>
      _isEnglish ? 'Optional website' : 'Sitio web opcional';
  String get optionalLogo =>
      _isEnglish ? 'Optional logo' : 'Logo opcional';
  String get logoSelected =>
      _isEnglish ? 'Logo selected' : 'Logo seleccionado';
  String get creatingAccount =>
      _isEnglish ? 'Creating account...' : 'Creando cuenta...';
  String get createAccountAction =>
      _isEnglish ? 'Create account' : 'Crear cuenta';
  String get signUpWithGoogle =>
      _isEnglish ? 'Sign up with Google' : 'Registrarme con Google';
  String get chooseAccountTypeTitle => _isEnglish
      ? 'Choose an account type'
      : 'Elige un tipo de cuenta';
  String get chooseAccountTypeMessage => _isEnglish
      ? 'Choose whether you will use StockMind as a person or a business.'
      : 'Selecciona si usarás StockMind como persona o como empresa.';
  String get incompleteRegisterTitle =>
      _isEnglish ? 'Incomplete registration' : 'Registro incompleto';
  String get incompleteRegisterMessage => _isEnglish
      ? 'You must enter your name, email and a valid password before creating the account.'
      : 'Debes ingresar nombre, correo y una contraseña válida antes de crear la cuenta.';
  String get accountCreateFailedTitle =>
      _isEnglish ? 'Could not create account' : 'No se pudo crear la cuenta';
  String get genericTryAgain => _isEnglish
      ? 'We could not complete the operation. Try again.'
      : 'No pudimos completar la operación. Inténtalo nuevamente.';
  String get accountCreatedTitle =>
      _isEnglish ? 'Account created' : 'Cuenta creada';
  String get accountCreatedMessage => _isEnglish
      ? 'Your account was created successfully.'
      : 'Tu cuenta fue creada correctamente.';
  String get businessProfileWarningTitle => _isEnglish
      ? 'Account created with notes'
      : 'Cuenta creada con observaciones';
  String businessProfileWarningMessage(String error) => _isEnglish
      ? 'The account was created, but we could not save the business profile: $error'
      : 'La cuenta se creó correctamente, pero no pudimos guardar el perfil de empresa: $error';
  String get chooseAccountTypeBeforeGoogleTitle => _isEnglish
      ? 'Choose your account type'
      : 'Selecciona tu tipo de cuenta';
  String get chooseAccountTypeBeforeGoogleMessage => _isEnglish
      ? 'Before continuing with Google, choose whether you will use StockMind as a person or as a business.'
      : 'Antes de continuar con Google, elige si usarás StockMind como persona o como empresa.';

  String get inventoryCenter =>
      _isEnglish ? 'Inventory center' : 'Centro de inventario';
  String get home => _isEnglish ? 'Home' : 'Inicio';
  String get products => _isEnglish ? 'Products' : 'Productos';
  String get alerts => _isEnglish ? 'Alerts' : 'Alertas';
  String get locations => _isEnglish ? 'Locations' : 'Ubicaciones';
  String get shortLocations => _isEnglish ? 'Locations' : 'Ubic.';
  String get settings => _isEnglish ? 'Settings' : 'Configuración';
  String get preferences => _isEnglish ? 'Settings' : 'Ajustes';
  String get signOut => _isEnglish ? 'Sign out' : 'Cerrar sesión';
  String get noSession => _isEnglish ? 'No session' : 'Sin sesión';
  String get confirmSignOutTitle => _isEnglish
      ? 'Are you sure you want to sign out?'
      : '¿Seguro que quieres cerrar sesión?';
  String get confirmSignOutMessage => _isEnglish
      ? 'Your current session will be closed on this device.'
      : 'Tu sesión actual se cerrará en este dispositivo.';
  String get cancel => _isEnglish ? 'Cancel' : 'Cancelar';
  String get signOutFailedTitle =>
      _isEnglish ? 'Could not sign out' : 'No se pudo cerrar sesión';

  String get loadingWorkspace => _isEnglish
      ? 'Loading workspace...'
      : 'Cargando espacio...';
  String get changeWorkspace =>
      _isEnglish ? 'Change workspace' : 'Cambiar espacio de trabajo';
  String get workspaceDemoBanner => _isEnglish
      ? 'You are viewing demo data'
      : 'Estás viendo datos de demostración';
  String get createMyWorkspace =>
      _isEnglish ? 'Create my workspace' : 'Crear mi espacio';
  String get seeReadmeGithub =>
      _isEnglish ? 'View README / GitHub' : 'Ver README / GitHub';
  String get retryAction => _isEnglish ? 'Retry' : 'Reintentar';
  String get createWorkspace =>
      _isEnglish ? 'Create workspace' : 'Crear espacio';
  String get goToWorkspace =>
      _isEnglish ? 'Go to workspace' : 'Ir a espacio de trabajo';
  String get createWorkspaceAction =>
      _isEnglish ? 'Create workspace' : 'Crear espacio de trabajo';
  String get workspaceCreatedMessage => _isEnglish
      ? 'is ready and is now your active workspace.'
      : 'quedó listo y ahora es tu espacio activo.';
  String get createWorkspaceTitle =>
      _isEnglish ? 'Create workspace' : 'Crear espacio de trabajo';
  String get createWorkspaceDescription => _isEnglish
      ? 'Create a personal inventory, a workspace for your business or a shared enterprise environment.'
      : 'Puedes crear un inventario personal, un workspace para tu negocio o un entorno empresarial compartido.';
  String get type => _isEnglish ? 'Type' : 'Tipo';
  String get personal => _isEnglish ? 'Personal' : 'Personal';
  String get business => _isEnglish ? 'Business' : 'Negocio';
  String get company => _isEnglish ? 'Company' : 'Empresa';
  String get workspaceName =>
      _isEnglish ? 'Workspace name' : 'Nombre del workspace';
  String get workspaceLabel =>
      _isEnglish ? 'Workspace name' : 'Nombre del espacio de trabajo';
  String get enterValidWorkspaceName => _isEnglish
      ? 'Enter a valid name.'
      : 'Ingresa un nombre válido.';
  String get optionalIndustry =>
      _isEnglish ? 'Optional industry' : 'Rubro opcional';
  String get createWorkspaceFailedTitle => _isEnglish
      ? 'Could not create workspace'
      : 'No se pudo crear el espacio';
  String get createWorkspaceFailedMessage => _isEnglish
      ? 'Verify your permissions or try again.'
      : 'Verifica tus permisos o intenta nuevamente.';

  String get newVersionAvailable =>
      _isEnglish ? 'New version available' : 'Nueva versión disponible';
  String get updateNow =>
      _isEnglish ? 'Update now' : 'Actualizar ahora';
  String get enableNotifications =>
      _isEnglish ? 'Enable notifications' : 'Activa las notificaciones';
  String get notificationPromptMessage => _isEnglish
      ? 'Receive low stock, expiring products and pending replenishment alerts.'
      : 'Recibe alertas de stock bajo, productos por vencer y reposiciones pendientes.';
  String get enableNotificationsAction => _isEnglish
      ? 'Enable notifications'
      : 'Activar notificaciones';
  String get notNow => _isEnglish ? 'Not now' : 'Ahora no';
  String get availableInvitation =>
      _isEnglish ? 'Invitation available' : 'Invitación disponible';
  String invitationPendingMessage(String companyName, String role) => _isEnglish
      ? 'You have a pending invitation to join $companyName as $role.'
      : 'Tienes una invitación pendiente para unirte a $companyName como $role.';
  String get acceptInvitation =>
      _isEnglish ? 'Accept invitation' : 'Aceptar invitación';
  String nowPartOfCompany(String companyName) => _isEnglish
      ? 'You are now part of $companyName.'
      : 'Ahora formas parte de $companyName.';
}

extension AppStringsBuildContextX on BuildContext {
  AppStrings get strings {
    final provider = read<LocaleProvider>();
    return AppStrings(provider.languageCode);
  }
}
