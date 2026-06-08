class Profile {
  final int? id;
  final String name;
  final String icon;
  final String color;
  final bool isActive;

  Profile({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isActive = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'],
      name: map['name'],
      icon: map['icon'],
      color: map['color'],
      isActive: map['is_active'] == 1,
    );
  }
}
