import 'package:appwrite/appwrite.dart';
import 'package:familygps/constants/appwrite_config.dart';

// To update the location in the Appwrite database
Future<void> updateUserLocationInDatabase(
    double lat, double long, String userId) async {
  Client client = Client();
  client.setEndpoint(END_POINT).setProject(PROJECT_ID);

  Databases databases = Databases(client);

  try {
    await databases.updateDocument(
      databaseId: DATABASE_ID,
      collectionId: USERS_COLLECTION_ID,
      documentId: userId,
      data: {
        'lat': lat,
        'long': long,
      },
    );
  } catch (e) {
    print('Failed to update user location: $e');
  }
}

// functio to fetch location
class LocationFetcher {
  Client client = Client();
  late Databases databases;
  LocationFetcher() {
    client = Client().setEndpoint(END_POINT).setProject(PROJECT_ID);
    databases = Databases(client);
  }

  Future<Map<String, dynamic>?> getDocumentData(
      String databaseId, String collectionId, String documentId) async {
    try {
      final document = await databases.getDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: documentId,

      );
      print('Document data: ${document.data}');
      return document.data; // Returns the document data as a map
    } catch (e) {
      print('Error fetching document: $e');
      return null;
    }
  }
}

