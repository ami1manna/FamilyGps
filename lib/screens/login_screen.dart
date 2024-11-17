import 'package:familygps/utils/permissions.dart';
import 'package:familygps/widgets/Toast.dart';
import 'package:familygps/controllers/auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
   LoginScreen({super.key});

    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    // Create a global key for the form
    final _formKey = GlobalKey<FormState>();

    
  void dispose() {
   
    emailController.dispose();
    passwordController.dispose();
    
  }

  void _signIn(BuildContext ctx) {
    // Validate the form
    if (!_formKey.currentState!.validate()) {
      // If the form is valid, display a snackbar or perform signup
          Toast.show(ctx, "Invalid Data", ToastType.error);
      // Handle the sign-up logic here
    }
    else{
      loginUser(emailController.text , passwordController.text)
      .then((value)async{
        if(value == 'success'){
          Toast.show(ctx, "Login successful!", ToastType.success);
          
          bool permissionsGranted = await arePermissionsGranted();

      // Navigate based on the permissions result
      if (permissionsGranted) {
        Navigator.pushReplacementNamed(ctx, '/home');
      } else {
        Navigator.pushReplacementNamed(ctx, '/permissions');
      }
        }
        else{
          Toast.show(ctx, value, ToastType.error);
        }
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA011F2), // Full screen #A011F2
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Assign the form key
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo or Title
              const Text(
                'Login',
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.white, // White text
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Email field
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Colors.white),
                  hintText: 'Enter your email',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.email, color: Colors.white),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.white.withOpacity(0.5)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Password field
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.white),
                  hintText: 'Enter your password',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.lock, color: Colors.white),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.white.withOpacity(0.5)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  } else if (value.length < 8) {
                    return 'Password must be at least 8 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Sign Up Button
              ElevatedButton(
                onPressed: ()=>_signIn(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // White button
                  foregroundColor: const Color(0xFFA011F2), // Text in #A011F2
                ), // Call sign up method
                child: const Text('Login'),
              ),
              const SizedBox(height: 20),

             
            ],
          ),
        ),
      ),
    );
  }
}