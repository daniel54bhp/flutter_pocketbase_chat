import 'package:get/get.dart';
import 'package:pocketbase_chat/app/modules/new_room/new_room_controller.dart';

class NewRoomBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NewRoomController>(
      () => NewRoomController(),
    );
  }
}
