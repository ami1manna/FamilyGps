// import 'package:appwrite/appwrite.dart';
// import 'package:familygps/constants/appwrite_config.dart';

// class AppwriteService {
//   Client client = Client();
//   late Realtime realtime;

//   AppwriteService() {
//     client
//         .setEndpoint(END_POINT) // Set your Appwrite endpoint
//         .setProject(PROJECT_ID); // Set your project ID

//     realtime = Realtime(client);
//   }

//   LatLng listenToDocumentChanges(String databaseId, String collectionId, String documentId) {
//     final channel = 'databases.$databaseId.collections.$collectionId.documents.$documentId';

//     realtime.subscribe([channel]).stream.listen((response) {
//       print('Document changes detected: ${response.payload}');
//       // Handle the document change here
//     });
//   }
// }
