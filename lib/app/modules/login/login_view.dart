import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';

import 'package:get/get.dart';

import 'login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
        title: 'Yatiya',
        theme: LoginTheme(
          primaryColor: Color.fromARGB(255, 26, 15, 24),
        ),
        logo: const AssetImage('assets/icon.png'),
        onLogin: controller.onLogin,
        onSignup: controller.onSignup,
        additionalSignupFields: const [
          UserFormField(keyName: 'name', displayName: 'Name'),
        ],
        onSubmitAnimationCompleted: controller.onLoginComplete,
        loginAfterSignUp: true,
        hideForgotPasswordButton: true,
        onRecoverPassword: (_) => null,
        messages: LoginMessages(
          userHint: 'Correo Electronico',
          passwordHint: 'Contraseña',
          confirmPasswordHint: 'Confirmar',
          loginButton: 'Iniciar Sesión',
          signupButton: '',
          forgotPasswordButton: 'Contraseña Olvidada?',
          recoverPasswordButton: 'Ayuda',
          goBackButton: 'Ir Atras',
          confirmPasswordError: 'No Coincide',
          recoverPasswordDescription: 'Contacte con el Administrador',
          recoverPasswordSuccess: 'Contraseña Cambiada!',
        ));
  }
}
