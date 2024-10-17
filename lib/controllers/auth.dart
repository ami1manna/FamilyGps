import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart';
import 'package:familygps/constants/appwrite_config.dart';
import 'package:familygps/controllers/user_operation.dart';
import 'package:familygps/widgets/Toast.dart';
import 'package:flutter/material.dart';

Client client = Client()
    .setEndpoint(END_POINT)
    .setProject(PROJECT_ID)
    .setSelfSigned(status: true); // For self signed certificates, only use for devel

Account account = Account(client);

// Create a new user 
Future<String> createUser(String name ,String email, String password) async {
  try{
    //  Create user in the Auth system
    final user = await account.create(
      userId: ID.unique(),
      name: name,
      email: email,
      password: password,
    );

    // Add the user to the database collection
    UsersDatabaseOperations userdb = UsersDatabaseOperations(client);
    await userdb.addUserToDatabase(user.$id, name, email,password); // Use the user ID from Auth for database

    return 'success';
  }
  on AppwriteException catch(e){
    return e.message.toString();
  }
}

// Login create Session
Future<String> loginUser(String email, String password) async {
  try {
    await account.createEmailPasswordSession(email: email, password: password); // Add await here
    return 'success';
  } on AppwriteException catch (e) {
    return e.message.toString();
  }
}


// Check Seesion
Future<bool> checkSession() async {
  try{
    await account.getSession(sessionId: "current");
    return true;
  }
  catch(e){
    return false;
  }
}
// logout 
Future<String> logoutUser() async {
  try{
    await account.deleteSession(sessionId: "current");
    return 'success';
  }
  on AppwriteException catch(e){
    return e.message.toString();
  }
}

// Get details of the current user
Future<User?> getUser() async {
  try {
    final user = await account.get();
    return user;
  } on AppwriteException catch (e) {
    print(e.message);  // Optionally log the error message
    return null;
  }
}

// Email Verification
 Future<String> sendEmailVerification() async {
    try {
      await account.createVerification(
        url: 'https://your-app-url.com/verification', // Replace with your app's verification URL
      );
      return 'success';
    } on AppwriteException catch (e) {
      return e.message ?? 'Failed to send verification email';
    }
  }


// Google Auth - TODO: remove this it not working 
Future<bool> continueWithGoogle(BuildContext context) async {
  try {
    final response = await account.createOAuth2Session(
      provider: OAuthProvider.google,
      scopes: ['email', 'profile'],
    );

    // Navigate to the OAuthCallbackScreen after a successful login
    Toast.show(context, 'Login successful', ToastType.success);
    // ignore: use_build_context_synchronously
    Navigator.pushReplacementNamed(context, '/oauth/callback');
    return true;
  } on AppwriteException catch (e) {
    Toast.show(context, e.message.toString(), ToastType.error);
    print(e.message);  // Optionally log the error message
    return false;
  }
}