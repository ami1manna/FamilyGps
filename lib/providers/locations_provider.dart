import 'package:appwrite/models.dart';
import 'package:familygps/constants/appwrite_config.dart';
import 'package:familygps/models/users_locations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';

// Define a provider for user locations
class UserLocationProvider extends StateNotifier<List<UserLocation>> {
  late final Databases _databases;
  late final Realtime _realtime;
  late final String databaseId;
  late final String usersCollectionId;
  late final RealtimeSubscription _subscription;

  // Constructor that initializes the state and Appwrite services
  UserLocationProvider(super._state) {
    Client client = Client()
      .setEndpoint(END_POINT) // Your Appwrite endpoint
      .setProject(PROJECT_ID) // Your project ID
      .setSelfSigned(); // Use self-signed certificates for development (if needed)

    _databases = Databases(client);
    _realtime = Realtime(client);
    
    // Set the database ID and collection ID
    databaseId = DATABASE_ID;
    usersCollectionId = USERS_COLLECTION_ID;
  }

  // Cleanup function to unsubscribe and clear state
  void cleanup() {
    // Unsubscribe from the previous subscription if it exists
    if (_subscription != null) {
      _subscription.close();
    }

    // Clear existing locations
    state = [];
  }

  // Function to subscribe to user locations in real-time
  void subscribeToUserLocations(List<String> userIds) {
    // Subscribe to real-time updates for user locations
    _subscription = _realtime.subscribe([
      'databases.$databaseId.collections.$usersCollectionId.documents'
    ]);

    _subscription.stream.listen((RealtimeMessage message) {
      // Check if the event is related to one of the user IDs we're interested in
      if (userIds.contains(message.payload['\$id'])) {
        double? latitude = message.payload['lat'];
        double? longitude = message.payload['long'];
        String?  userName = message.payload['name'];

        if (latitude != null && longitude != null) {
          final userId = message.payload['\$id'];
          final existingUserIndex = state.indexWhere((location) => location.userId == userId);

          if (existingUserIndex >= 0) {
            // Update the user's location if they already exist
            state[existingUserIndex] = UserLocation(
              userId: userId,
              latitude: latitude,
              longitude: longitude,
              name: userName as String,
            );
          } else {
            // Add the new user location if not already in the list
            state = [
              ...state,
              UserLocation(userId: userId, latitude: latitude, longitude: longitude, name : userName as String),
            ];
          }
        }
      }
    });
  }

  // Function to fetch initial user locations based on user IDs
  Future<void> fetchUserLocations(List<String> userIds) async {
    // Call cleanup to clear previous data and unsubscribe
    cleanup();

    List<UserLocation> initialLocations = [];

    for (String userId in userIds) {
      try {
        // Fetch the user's document by their userId
        Document userDoc = await _databases.getDocument(
          databaseId: databaseId,
          collectionId: usersCollectionId,
          documentId: userId,
        );

        double latitude = userDoc.data['lat'] ?? 0.0; // Default to 0.0 if not found
        double longitude = userDoc.data['long'] ?? 0.0; // Default to 0.0 if not found

        initialLocations.add(UserLocation(
          userId: userId,
          latitude: latitude,
          longitude: longitude,
          name: userDoc.data['name'] as String,
        ));
      } catch (e) {
        print('Error fetching user document for $userId: $e');
      }
    }

    // Update the state with the initial locations
    state = initialLocations;

    // Subscribe to user locations for real-time updates
    subscribeToUserLocations(userIds);
  }
}

// Define a provider for UserLocationProvider
final userLocationProvider = StateNotifierProvider<UserLocationProvider, List<UserLocation>>((ref) {
  return UserLocationProvider([]);
});
