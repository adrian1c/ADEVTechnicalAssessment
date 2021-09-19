import 'package:intl/intl.dart';

class Contact {
  var id;
  final String user;
  final String phone;
  final String checkin;

  Contact({
    this.id,
    required this.user,
    required this.phone,
    required this.checkin,
  });

  Map<String, dynamic> toMap() {
    return {
      'user': user,
      'phone': phone,
      'checkin': checkin,
    };
  }

  @override
  String toString() {
    return 'Contact{id: $id, user: $user, phone: $phone, checkin: $checkin}';
  }
}
