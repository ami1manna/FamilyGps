class UserModel {

  final String name;
  final String email;
  final String? password;
  final bool? loggedIn;
  final bool logInAsGoogle;
  UserModel({ required this.name, required this.email,  this.password , this.loggedIn, this.logInAsGoogle = false});

}