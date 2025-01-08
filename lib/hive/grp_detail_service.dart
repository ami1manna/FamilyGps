import 'package:familygps/models/group_detail_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class HiveService {
  static const String _groupBoxName = 'group_details';

  // Initialize Hive service with the application's directory
  Future<void> initHive() async {
    // Use path_provider to get the application documents directory
    final appDocumentDir = await getApplicationDocumentsDirectory();
    
    // Initialize Hive with the path
    await Hive.initFlutter(appDocumentDir.path);
    
    // Register the adapters
    Hive.registerAdapter(GroupDetailModelAdapter());
    Hive.registerAdapter(MemberListAdapter());
    
    // Open the box to ensure it's accessible before any operations
    await Hive.openBox<GroupDetailModel>(_groupBoxName);
  }

  // Save group details to the Hive box
  Future<void> saveGroupDetails(GroupDetailModel groupDetails) async {
    final box = await Hive.openBox<GroupDetailModel>(_groupBoxName);
    await box.put(groupDetails.groupCode, groupDetails);
  }

  // Retrieve group details from the Hive box
  GroupDetailModel? getGroupDetails(String groupCode) {
    final box = Hive.box<GroupDetailModel>(_groupBoxName);
    return box.get(groupCode);
  }

  // Delete group details from the Hive box
  Future<void> deleteGroupDetails(String groupCode) async {
    final box = await Hive.openBox<GroupDetailModel>(_groupBoxName);
    await box.delete(groupCode);
  }

  // Check whether to fetch data from the network based on age of data
  bool shouldFetchFromNetwork(GroupDetailModel? localData) {
    if (localData == null) return true;

    // Refresh data if older than 5 minutes
    return DateTime.now().difference(localData.lastUpdated).inMinutes > 5;
  }
}
