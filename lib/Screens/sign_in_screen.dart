import 'package:flutter/material.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  bool keepSignedIn = false;
  String emailOrUsername = '';
  String password = '';

  void _login() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signing In...')),
      );
      // TODO: Add real sign-in logic here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Email or Username'),
                onChanged: (val) => emailOrUsername = val,
                validator: (val) =>
                    val!.isEmpty ? 'Please enter your email or username' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                onChanged: (val) => password = val,
                validator: (val) => val!.length < 6
                    ? 'Password must be at least 6 characters'
                    : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Checkbox(
                    value: keepSignedIn,
                    onChanged: (val) {
                      setState(() {
                        keepSignedIn = val!;
                      });
                    },
                  ),
                  const Text("Keep me signed in")
                ],
              ),
              TextButton(
                onPressed: () {
                  // TODO: Implement Forgot Password Logic
                },
                child: const Text("Forgot Password?"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF57C00),
                  foregroundColor: Colors.white,
                ),
                child: const Text("Sign In"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
