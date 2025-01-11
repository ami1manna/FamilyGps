import 'package:appwrite/models.dart';
import 'package:familygps/constants/appwrite_config.dart';
import 'package:familygps/controllers/group_detail_operation.dart';
import 'package:familygps/hive/grp_detail_service.dart';
import 'package:familygps/hive/user_detail_service.dart';
import 'package:familygps/models/hive_models.dart';
import 'package:familygps/models/users_locations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';

class UserLocationProvider extends StateNotifier<List<UserLocation>> {
  late final Databases _databases;
  late final Realtime _realtime;
  late final String databaseId;
  late final String usersCollectionId;
  RealtimeSubscription? _subscription; // Made nullable
  UserLocation? _selectedUser; // Track the selected user
  HiveServiceGroupDetails hiveServiceGroupDetails = HiveServiceGroupDetails();
  HiveServiceUserDetails hiveServiceUserDetails = HiveServiceUserDetails();
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

  void subscribeToUserLocations(List<String> userIds) async {
    // Unsubscribe from any existing subscription
    _subscription?.close();

    try {
      _subscription = _realtime.subscribe(
          ['databases.$databaseId.collections.$usersCollectionId.documents']);

      _subscription!.stream.listen((RealtimeMessage message) async {
        try {
          // Check if the updated document is for a user in our group
          if (userIds.contains(message.payload['\$id'])) {
            // Extract payload data with null safety
            final userId = message.payload['\$id'];
            final latitude = _parseDouble(message.payload['lat']);
            final longitude = _parseDouble(message.payload['long']);
            final userName = message.payload['name'] as String?;
            final userStatus = message.payload['status'] as String?;
            final userEmail = message.payload['email'] as String;
            // Validate required data
            if (latitude != null && longitude != null && userName != null) {
              // Create new UserLocation object
              final newLocation = UserLocation(
                userId: userId,
                latitude: latitude,
                longitude: longitude,
                name: userName,
               
                timestamp: DateTime.now(),
              );

              // Update user details in Hive
              final userDetails = UserDetailModel(
                userId: userId,
                name: userName,
                lat: latitude,
                long: longitude,
                email:userEmail,
                status: userStatus ?? 'online',
                lastUpdatedLocation: DateTime.now(),
              );

              // Save/Update user details and location in Hive
              await HiveServiceUserDetails().updateUserDetails(userDetails);

              // Create a new list with the updated or new location
              final newState = [...state];
              final existingIndex =
                  newState.indexWhere((loc) => loc.userId == userId);

              if (existingIndex >= 0) {
                newState[existingIndex] = newLocation;
              } else {
                newState.add(newLocation);
              }

              // Update the state with the new list
              state = newState;

              print('Updated location for $userName: $latitude, $longitude');
            }
          }
        } catch (e) {
          print('Error processing real-time location update: $e');
        }
      }, onError: (error) {
        print('Realtime subscription error: $error');
      });
    } catch (e) {
      print('Error setting up realtime subscription: $e');
    }
  }

// Utility method to safely parse doubles
  double? _parseDouble(dynamic value) {
    if (value == null) return null;

    if (value is int) {
      return value.toDouble();
    }

    if (value is double) {
      return value;
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }

 Future<void> fetchUserLocations(String selectedGroupCode) async {
  // Call cleanup to clear previous data and unsubscribe
  cleanup();

  List<UserLocation> initialLocations = [];

  // Check if local data is available
  final localData = HiveServiceGroupDetails().getGroupDetails(selectedGroupCode);

  if (localData != null && localData.members.isNotEmpty) {
     
    for (String userId in localData.members) {
      // Fetch user details from Hive
      UserDetailModel? userDetails =
          HiveServiceUserDetails().getUserDetails(userId);
      
      if (userDetails != null) {
        initialLocations.add(UserLocation(
          userId: userId,
          latitude: userDetails.lat ?? 0.0,
          longitude: userDetails.long ?? 0.0,
          name: userDetails.name ?? '',
        ));
      }
    }
  }

  // If no local data or empty, fetch from database
  if (initialLocations.isEmpty) {
     print("group: is empty");
    // Fetch group members using DetailGroupOperation
    List<Map<String, String>> memberDetails =
        await DetailGroupOperation().fetchGroupMembers(selectedGroupCode);

    for (Map<String, String> memberDetail in memberDetails) {
      String userId = memberDetail['userId']!;
      
      // Create UserLocation from fetched details
      initialLocations.add(UserLocation(
        userId: userId,
        latitude: double.tryParse(memberDetail['lat'] ?? '0.0') ?? 0.0,
        longitude: double.tryParse(memberDetail['long'] ?? '0.0') ?? 0.0,
        name: memberDetail['name'] ?? '',
      ));
    }
  }

  // by default select first user as selected
  _selectedUser = initialLocations.isNotEmpty ? initialLocations.first : null;

  // Update the state with the initial locations
  state = initialLocations;

  // Subscribe to user locations for real-time updates
  subscribeToUserLocations(localData?.members ?? 
    initialLocations.map((loc) => loc.userId).toList());
}
  void setSelectedUser(UserLocation user) {
    _selectedUser = user;
    // Notify listeners that the selected user has changed
    state = [...state];
  }

  // Method to get the selected user
  UserLocation? get selectedUser => _selectedUser;
}

// Define a provider for UserLocationProvider
final userLocationProvider =
    StateNotifierProvider<UserLocationProvider, List<UserLocation>>((ref) {
  return UserLocationProvider([]);
});
