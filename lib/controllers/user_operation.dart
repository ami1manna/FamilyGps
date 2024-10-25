import 'package:appwrite/appwrite.dart';
import 'package:familygps/constants/appwrite_config.dart';


class UsersDatabaseOperations {
  late Client client;
  late Databases databases;

  UsersDatabaseOperations() {
    client = Client()
        .setEndpoint(END_POINT) // Your Appwrite endpoint
        .setProject(PROJECT_ID) // Your project ID
        .setSelfSigned();
    databases = Databases(client);
  }

  Future<void> updateUserInDatabase(
    String userId, Map<String, dynamic> updatedData) async {
  const databaseId = DATABASE_ID; // Replace with your actual database ID
  const collectionId = USERS_COLLECTION_ID; // Replace with your actual collection ID

  try {
    print('Attempting to update user with ID: $userId');
    await databases.updateDocument(
      databaseId: databaseId,
      collectionId: collectionId,
      documentId: userId,
      data: updatedData,
    );
    print('User updated successfully.');
  } on AppwriteException catch (e) {
    print('Error updating user in database: ${e.code} - ${e.message}');
  } catch (e) {
    print('Unexpected error: $e');
  }
}
  // Function to create a new user
  Future<void> addUserToDatabase(
      String userId, String name, String email, String password) async {
    const databaseId = DATABASE_ID; // Replace with your actual database ID
    const collectionId =
        USERS_COLLECTION_ID; // Replace with your actual collection ID

    try {
      print('Attempting to add user $name to database with ID: $userId');
      await databases.createDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: userId, // Use userId from Auth system as the document ID
        data: {'name': name, 'email': email, 'password': password},
        permissions: [
          // Set read and write permissions for the user
          Permission.read(Role.any()),
          Permission.write(Role.any()),
        ],
      );
      print('User added successfully.');
    } on AppwriteException catch (e) {
      print('Error adding user to database: ${e.code} - ${e.message}');
    } catch (e) {
      print('Unexpected error: $e');
    }
  }

  

  // for fetch user email and names
  Future<List<String>> fetchUsersList() async {
    try {
      const databaseId = DATABASE_ID; // Ensure this is set correctly
      const collectionId = USERS_COLLECTION_ID; // Ensure this is set correctly

      final result = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: collectionId,
      );

// Map the documents to a list of email strings
    List<String> usersList = result.documents.map<String>((doc) {
      return doc.data['email'] as String; // Return the email string directly
    }).toList();

      return usersList;

    } on AppwriteException catch (e) {
      print('Error fetching users: ${e.message}');
      return []; // Return an empty list in case of error
    } catch (e) {
      print('Unexpected error: $e');
      return []; // Return an empty list in case of unexpected error
    }
  }
}
