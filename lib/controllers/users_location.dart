import 'package:appwrite/appwrite.dart'; // Ensure you're importing Appwrite SDK
import 'package:familygps/constants/appwrite_config.dart';

class UserLocationService {
   late Client client;
  late Databases _databases;
  late Realtime _realtime;

  UserLocationService() {
    client = Client()
        .setEndpoint(END_POINT) // Your Appwrite endpoint
        .setProject(PROJECT_ID) // Your project ID
        .setSelfSigned();
    _databases = Databases(client);
    _realtime = Realtime(client);
  }


  // Function to fetch lat/long for a list of users and subscribe to real-time updates
  void subscribeToUserLocations(List<String> userIds, void Function(List<Map<String, double>>) onLocationUpdate) {
    // Initialize an empty list to store the lat/long of users
    List<Map<String, double>> userLocations = [];

    // Subscribe to real-time changes for the specified user IDs
    final subscription = _realtime.subscribe([
      'databases.$DATABASE_ID.collections.$USERS_COLLECTION_ID.documents'
    ]);

    subscription.stream.listen((RealtimeMessage message) async {
      // Check if the event is related to one of the user IDs we're interested in
      if (userIds.contains(message.payload['\$id'])) {
        // Extract the user's latitude and longitude
        double? latitude = message.payload['latitude'];
        double? longitude = message.payload['longitude'];

        if (latitude != null && longitude != null) {
          // Check if the user is already in the list
          var existingUserIndex = userLocations.indexWhere((location) => location['userId'] == message.payload['\$id']);

          if (existingUserIndex >= 0) {
            // Update the user's location if they already exist in the list
            userLocations[existingUserIndex] = {
              'userId': message.payload['\$id'],
              'latitude': latitude,
              'longitude': longitude,
            };
          } else {
            // Add the new user location if not already in the list
            userLocations.add({
              'userId': message.payload['\$id'],
              'latitude': latitude,
              'longitude': longitude,
            });
          }

          // Trigger the callback function with the updated locations
          onLocationUpdate(userLocations);
        }
      }
    });
  }
}
