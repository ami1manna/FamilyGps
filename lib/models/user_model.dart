class UserModel {
  final String? userid;
  final String name;
  final String email;
  final String? password;
  
 
  double? lat;
  double? long;

  UserModel({
    required this.name,
    required this.email,
    this.password,
    this.userid,
    
    this.lat,
    this.long,
  });
}