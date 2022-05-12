import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';

class NotLoggedInPage extends StatefulWidget {
  const NotLoggedInPage({Key? key}) : super(key: key);

  @override
  State<NotLoggedInPage> createState() => _NotLoggedInPageState();
}

class _NotLoggedInPageState extends State<NotLoggedInPage> {
  String? _email;
  String? _password;
  String? _name;
  String? _verificationCode;

  bool _login = true;
  bool _inputVerificationCode = false;

  Widget _loginWidget(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('Login to your account',),
        const SizedBox(
          height: 16.0,
        ),
        if (_inputVerificationCode) ...[
          TextField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Verification Code',
            ),
            keyboardType: TextInputType.number,
            onChanged: (code) {
              setState(() {
                _verificationCode = code;
              });
            },
          ),
          const SizedBox(
            height: 16.0,
          ),
          MaterialButton(
            child: const Text('Verify'),
            color: Colors.blue,
            textColor: Colors.white,
            onPressed: () async {
              try {
                await Amplify.Auth.confirmSignUp(
                  username: _email!,
                  confirmationCode: _verificationCode!,
                );
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Verification Success! Please login to your account!'),
                ));
                setState(() {
                  _inputVerificationCode = false;
                });
              } catch (ex) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ex.toString()),
                ));
              }
            },
          ),
        ] else ...[
          TextField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Email',
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (email) {
              setState(() {
                _email = email;
              });
            },
          ),
          const SizedBox(
            height: 8.0,
          ),
          TextField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Password',
            ),
            keyboardType: TextInputType.text,
            obscureText: true,
            onChanged: (pass) {
              setState(() {
                _password = pass;
              });
            },
          ),
          const SizedBox(
            height: 16.0,
          ),
          MaterialButton(
            child: const Text('Login'),
            color: Colors.blue,
            textColor: Colors.white,
            onPressed: () async {
              try {
                await Amplify.Auth.signIn(
                  username: _email!,
                  password: _password!,
                );
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Sign In Success!'),
                ));
              } on UserNotConfirmedException catch (_) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('You need to confirm your account first!'),
                ));
                await Amplify.Auth.resendSignUpCode(username: _email!);
                setState(() {
                  _inputVerificationCode = true;
                });
              } catch (ex) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ex.toString()),
                ));
              }
            },
          ),
        ],
        const SizedBox(
          height: 16.0,
        ),
        InkWell(
          onTap: () {
            setState(() {
              _login = false;
            });
          },
          child: const Text(
            'or, sign up instead?',
          ),
        ),
      ],
    );
  }

  Widget _signupWidget(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('Sign up to our services',),
        const SizedBox(
          height: 16.0,
        ),
        TextField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Email',
          ),
          keyboardType: TextInputType.emailAddress,
          onChanged: (email) {
            setState(() {
              _email = email;
            });
          },
        ),
        const SizedBox(
          height: 8.0,
        ),
        TextField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Name',
          ),
          keyboardType: TextInputType.name,
          onChanged: (name) {
            setState(() {
              _name = name;
            });
          },
        ),
        const SizedBox(
          height: 8.0,
        ),
        TextField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Password',
          ),
          keyboardType: TextInputType.text,
          obscureText: true,
          onChanged: (pass) {
            setState(() {
              _password = pass;
            });
          },
        ),
        const SizedBox(
          height: 16.0,
        ),
        MaterialButton(
          child: const Text('Sign Up'),
          color: Colors.blue,
          textColor: Colors.white,
          onPressed: () async {
            try {
              Map<CognitoUserAttributeKey, String> userAttributes = {
                CognitoUserAttributeKey.email: _email!,
                CognitoUserAttributeKey.name: _name!,
                // additional attributes as needed
              };
              await Amplify.Auth.signUp(
                username: _email!,
                password: _password!,
                options: CognitoSignUpOptions(
                  userAttributes: userAttributes,
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Sign Up Success! Please confirm your code'),
              ));
              setState(() {
                _login = true;
                _inputVerificationCode = true;
              });
            } catch (ex) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(ex.toString()),
              ));
            }
          },
        ),
        const SizedBox(
          height: 16.0,
        ),
        InkWell(
          onTap: () {
            setState(() {
              _login = true;
            });
          },
          child: const Text(
            'or, login instead?',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Center(
        child: _login
            ? _loginWidget(context)
            : _signupWidget(context),
      ),
    );
  }
}