class UserModel {
  final String? userid;
  final String name;
  final String email;
  final String? password;
  final bool? loggedIn;
 
  double? lat;
  double? long;

  UserModel({
    required this.name,
    required this.email,
    this.password,
    this.userid,
    this.loggedIn,
    this.lat,
    this.long,
  });
}