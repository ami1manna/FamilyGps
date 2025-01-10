class UserLocation {
  final String userId;
  final double latitude;
  final double longitude;
  final String name;
  DateTime? timestamp;
   String? Profile;
  UserLocation({
    required this.userId,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.timestamp,
  }){
    getProfile(name);
  }
  String getProfile(String name) {
    List<String>  list = name.toUpperCase().split(' ');
    String initials = '';
    list.map((val){
      initials += val[0];
    });
    return initials;
  }
}
