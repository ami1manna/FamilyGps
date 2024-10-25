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
  RealtimeSubscription? _subscription; // Made nullable

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
    _subscription?.close();
    _subscription = null; // Clear the subscription reference

    // Clear existing locations
    state = [];
  }

  // Function to subscribe to user locations in real-time
 void subscribeToUserLocations(List<String> userIds) {
  // Unsubscribe from any existing subscription
  _subscription?.close();

  _subscription = _realtime.subscribe([
    'databases.$databaseId.collections.$usersCollectionId.documents'
  ]);

  _subscription!.stream.listen((RealtimeMessage message) {
    if (userIds.contains(message.payload['\$id'])) {
      double? latitude = message.payload['lat'];
      double? longitude = message.payload['long'];
      String? userName = message.payload['name'];

      if (latitude != null && longitude != null && userName != null) {
        final userId = message.payload['\$id'];
        final newLocation = UserLocation(
          userId: userId,
          latitude: latitude,
          longitude: longitude,
          name: userName,
        );

        // Create a new list with the updated or new location
        final newState = [...state];
        final existingIndex = newState.indexWhere((loc) => loc.userId == userId);
        if (existingIndex >= 0) {
          newState[existingIndex] = newLocation;
        } else {
          newState.add(newLocation);
        }

        // Update the state with the new list
        state = newState;

        print('Updated location for ${newLocation.name}: ${newLocation.latitude}, ${newLocation.longitude}');
      }
    }
  });
}
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

      // Fetch latitude and longitude and ensure they are doubles
      double latitude = (userDoc.data['lat'] is int)
          ? (userDoc.data['lat'] as int).toDouble()
          : (userDoc.data['lat'] as double? ?? 0.0); // Default to 0.0 if not found

      double longitude = (userDoc.data['long'] is int)
          ? (userDoc.data['long'] as int).toDouble()
          : (userDoc.data['long'] as double? ?? 0.0); // Default to 0.0 if not found

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