class User {
  const User({this.id, required this.username, required this.password});

  factory User.fromMap(Map<String, Object?> map) => User(
    id: map['id'] as int?,
    username: map['username']! as String,
    password: map['password']! as String,
  );

  final int? id;

  final String username;

  final String password;

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'username': username,
    'password': password,
  };
}
