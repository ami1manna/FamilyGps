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

//   // ------------------FOR ADD.. USER FRIENDS------------------------//

//   Future<void> addFriendsToUser(String userId, List<String> friends) async {
//     const databaseId = DATABASE_ID;
//     const collectionId = USERS_FRIENDS_COLLECTION_ID;

//     try {
//       // First, retrieve the user's document from the 'user_friends' collection
//       final userDoc = await databases.getDocument(
//         databaseId: databaseId,
//         collectionId: collectionId,
//         documentId: userId,
//       );

//       // If the document exists, update the 'friends' field
//       List<String> currentFriends =
//           List<String>.from(userDoc.data['friends'] ?? []);
//       currentFriends.addAll(friends);

//       // Update the user's document with the new friends list
//       await databases.updateDocument(
//         databaseId: databaseId,
//         collectionId: collectionId,
//         documentId: userId,
//         data: {
//           'friends': currentFriends,
//         },
//       );
//     } on AppwriteException catch (e) {
//       // If the document does not exist, create a new document
//       if (e.code == 404) {
//         await databases.createDocument(
//           databaseId: databaseId,
//           collectionId: collectionId,
//           documentId: userId,
//           data: {
//             'friends': friends,
//           },
//           permissions: [
//             Permission.read(Role.user(userId)),
//             Permission.write(Role.user(userId)),
//           ],
//         );
//       } else {
//         print('Error adding friends: ${e.message}');
//       }
//     }
//   }
}