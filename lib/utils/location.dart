import 'package:appwrite/appwrite.dart';
import 'package:familygps/constants/appwrite_config.dart';
class LocationCallbackHandler {
}

// To update the location in the Appwrite database
Future<void> updateUserLocationInDatabase(double lat, double long, String userId) async {
  Client client = Client();
  client.setEndpoint(END_POINT)
        .setProject(PROJECT_ID);

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

