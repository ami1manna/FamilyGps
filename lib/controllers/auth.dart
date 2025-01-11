import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:familygps/constants/appwrite_config.dart';
import 'package:familygps/controllers/user_operation.dart';

Client client = Client()
    .setEndpoint(END_POINT)
    .setProject(PROJECT_ID)
    .setSelfSigned(status: true); // For self signed certificates, only use for devel

Account account = Account(client);

// Helper function to capitalize first and last names
String capitalizeName(String name) {
  final words = name.split(' ');
    return words.map((word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}

// Create a new user 
Future<String> createUser(String name, String email, String password) async {
  try {
    // Capitalize name
    name = capitalizeName(name);

    // Create user in the Auth system
    final user = await account.create(
      userId: ID.unique(),
      name: name,
      email: email,
      password: password,
    );

    // Add the user to the database collection
    UsersDatabaseOperations userdb = UsersDatabaseOperations();
    await userdb.addUserToDatabase(user.$id, name, email, password); // Use the user ID from Auth for database

    return 'success';
  } on AppwriteException catch (e) {
    return e.message.toString();
  }
}

// Login to create a session
Future<String> loginUser(String email, String password) async {
  try {
    await account.createEmailPasswordSession(email: email, password: password);
    return 'success';
  } on AppwriteException catch (e) {
    return e.message.toString();
  }
}

// Check session TODO
Future<bool> checkSession() async {
  try {
    await account.getSession(sessionId: "current");
    return true;
  } catch (e) {
    return false;
  }
}

// Logout
Future<String> logoutUser() async {
  try {
    await account.deleteSession(sessionId: "current");
    return 'success';
  } on AppwriteException catch (e) {
    return e.message.toString();
  }
}

// Get details of the current user
Future<User?> getUser() async {
  try {
    final user = await account.get();
    return user;
  } on AppwriteException catch (e) {
    print(e.message);
    return null;
  }
}

// Update user details
Future<String> updateUserDetails(String userId, {String? name, String? email, String? password}) async {
  try {
    Map<String, dynamic> updatedData = {};

    // Update name if provided
    if (name != null) {
      name = capitalizeName(name);  // Capitalize the name
      await account.updateName(name: name);
      updatedData['name'] = name;
    }

    // Update user in database only if there are changes
    if (updatedData.isNotEmpty) {
      UsersDatabaseOperations userdb = UsersDatabaseOperations();
      await userdb.updateUserInDatabase(userId, updatedData);
    }

    return 'success';
  } on AppwriteException catch (e) {
    print('Error updating user: ${e.message}');
    return e.message.toString();
  } catch (e) {
    print('Unexpected error: $e');
    return 'An unexpected error occurred';
  }
}
