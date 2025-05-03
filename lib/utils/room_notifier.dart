import 'package:flutter/foundation.dart';

// Global ValueNotifier to track when rooms are created or updated
class RoomNotifier {
  static final ValueNotifier<bool> roomsUpdated = ValueNotifier<bool>(false);
  
  // Trigger a notification that rooms have been updated
  static void notifyRoomsUpdated() {
    roomsUpdated.value = !roomsUpdated.value;
  }
}
