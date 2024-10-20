import 'package:appwrite/appwrite.dart';
import 'package:familygps/constants/appwrite_config.dart';

class UsersDatabaseOperations {
  final Client client;

  final Databases databases;
  UsersDatabaseOperations(this.client) : databases = Databases(client);
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

  // Function to fetch users from a custom collection based on name or email
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      const databaseId = DATABASE_ID; // Ensure this is set correctly
      const collectionId = USERS_COLLECTION_ID; // Ensure this is set correctly

      final result = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: collectionId,
        queries: [
          Query.search('name', query),
          Query.search('email', query),
        ],
      );

      // Ensure the result.documents is properly typed
      List<Map<String, dynamic>> users =
          result.documents.map<Map<String, dynamic>>((doc) {
        return {
          'name': doc.data['name'],
          'email': doc.data['email'],
        };
      }).toList();

      return users; // Return the properly typed list
    } on AppwriteException catch (e) {
      print('Error fetching users: ${e.message}');
      return []; // Return an empty list in case of error
    } catch (e) {
      print('Unexpected error: $e');
      return []; // Return an empty list in case of unexpected error
    }
  }
}