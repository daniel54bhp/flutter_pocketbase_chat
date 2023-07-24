import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:pocketbase_chat/app/data/helper.dart';
import 'package:pocketbase_chat/app/models/user.dart';
import 'package:pocketbase_chat/app/routes/app_pages.dart';
import 'package:pocketbase_chat/app/services/pocketbase_service.dart';

class NewRoomController extends GetxController {
  List<User> users = <User>[].obs;
  RxMap<dynamic, dynamic> usersSelect = {}.obs;
  TextEditingController nameRoomController = TextEditingController();

  RxBool isLoading = false.obs;

  @override
  void onInit() {
    loadUsers();
    super.onInit();
  }

  Future<void> loadUsers() async {
    isLoading.value = true;
    try {
      users = await PocketbaseService.to.getAllUsers();
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      Get.log('GotError : $e');
      showErrorSnackbar(e.toString());
    }
  }

  void selectUser({required String idUser}) {
    if (!usersSelect.containsKey(idUser)) {
      usersSelect[idUser] = idUser;
      usersSelect;
    } else {
      usersSelect.remove(idUser);
    }
    loadUsers();
  }

  void newRoom() async {
    if (usersSelect.length < 2) {
      showErrorSnackbar('Selecciona almenos dos usuarios');

      return;
    }

    if (nameRoomController.text == '') {
      showErrorSnackbar('Escribe el nombre de la sala para continuar');

      return;
    }
    User? user = PocketbaseService.to.user;
    await PocketbaseService.to.addRoom(
        room: nameRoomController.text,
        userId: user!.id.toString(),
        users: usersSelect.value.values.toList());
    nameRoomController.text = "";
    usersSelect.clear();
    Get.offAndToNamed(Routes.DASHBOARD);
  }

  bool checkSelect({required String idUser}) {
    return usersSelect.containsKey(idUser);
  }
}
