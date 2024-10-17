
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:familygps/constants/appwrite_config.dart';

Client client = Client()
    .setEndpoint(END_POINT)
    .setProject(PROJECT_ID)
    .setSelfSigned(status: true); // For self signed certificates, only use for devel

Account account = Account(client);

// Create a new user 
Future<String> createUser(String name ,String email, String password) async {
  try{
    await account.create(
      userId: ID.unique(),
      name: name,
      email: email,
      password: password
    );
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
