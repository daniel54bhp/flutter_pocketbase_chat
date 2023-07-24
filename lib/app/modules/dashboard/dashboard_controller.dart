import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:pocketbase_chat/app/data/helper.dart';
import 'package:pocketbase_chat/app/models/chat_room.dart';
import 'package:pocketbase_chat/app/routes/app_pages.dart';

import '../../models/user.dart';
import '../../services/pocketbase_service.dart';

class DashboardController extends GetxController
    with GetSingleTickerProviderStateMixin {
  RxBool isLoading = false.obs;
  List<ChatRoom> rooms = <ChatRoom>[];
  List<User> users = <User>[];
  RxString photo = ''.obs;

  final _roomNameEditingController = TextEditingController();
  late TabController tabController;
  @override
  void onInit() {
    loadRooms();
    loadUsers();
    profilePhoto();
    tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    tabController.addListener(() async {});
    super.onInit();
  }

  Future<void> loadRooms() async {
    isLoading.value = true;
    try {
      User? user = PocketbaseService.to.user;
      rooms = await PocketbaseService.to
          .getRoomsByUser(idUser: user!.id.toString());
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      Get.log('GotError : $e');
      showErrorSnackbar(e.toString());
    }
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

  void onRoomTap(ChatRoom chatRooms) {
    User? user = PocketbaseService.to.user;
    if (user == null) {
      Get.offAllNamed(Routes.LOGIN);
    } else {
      Get.toNamed(Routes.CHATTING, arguments: [chatRooms, user]);
    }
  }

  Future<void> onRoomLongTap(ChatRoom chatRooms) async {
    // only room owner can delete room
    bool isRoomOwner =
        chatRooms.createdBy == PocketbaseService.to.user?.id.toString();
    if (!isRoomOwner) return;
    Get.defaultDialog(
      title: "Delete room",
      content: Text("Are you sure want to delete ${chatRooms.name}?"),
      onCancel: () {},
      onConfirm: () async {
        Get.back();
        try {
          await PocketbaseService.to.deleteRoom(chatRooms.id!);
          loadRooms();
        } catch (e) {
          Get.log(e.toString());
        }
      },
    );
  }

  Future<void> addNewRoom() async {
    // Get.defaultDialog(
    //   title: "Add new room",
    //   content: TextFormField(
    //     controller: _roomNameEditingController,
    //     decoration: const InputDecoration(
    //       labelText: "Room name",
    //     ),
    //   ),
    //   onCancel: () {
    //     _roomNameEditingController.text = "";
    //   },
    //   onConfirm: () async {
    //     try {
    //       User? user = PocketbaseService.to.user;
    //       Get.back();
    //       await PocketbaseService.to.addRoom(
    //           room: _roomNameEditingController.text,
    //           userId: user!.id.toString(),
    //           users: []);
    //       loadRooms();
    //       _roomNameEditingController.text = "";
    //     } catch (e) {
    //       showErrorSnackbar(e.toString());
    //       Get.log(e.toString());
    //     }
    //   },
    // );
    Get.toNamed(Routes.NEWROOM);
  }

  void onLogoutTap() {
    try {
      PocketbaseService.to.logout();
      Get.offAllNamed(Routes.LOGIN);
    } catch (e) {
      Get.log(e.toString());
    }
  }

  Future<ChatRoom?> createOrGetRoomThowUser({
    required String idToUser,
  }) async {
    isLoading.value = true;
    try {
      User? user = PocketbaseService.to.user;
      final response = await PocketbaseService.to.addRoomThowUsers(
        room: 'Chat con ${user!.id.toString()} y $idToUser',
        toUserId: idToUser,
        userId: user.id.toString(),
      );
      isLoading.value = false;
      return response;
    } catch (e) {
      isLoading.value = false;
      Get.log('GotError : $e');
      showErrorSnackbar(e.toString());
      return null;
    }
  }

  Future<void> profilePhoto() async {
    User? user = PocketbaseService.to.user;
    final response =
        await PocketbaseService.to.getUserDetails(user!.id.toString());
    final linkResponse =
        await PocketbaseService.to.getProfilePhoto(user: response);

    photo.value = linkResponse;
  }

  Future<void> changeProfilePhoto({required File file}) async {
    User? user = PocketbaseService.to.user;

    final linkResponse = await PocketbaseService.to
        .changePhotoProfile(file: file, userID: user!.id.toString());

    photo.value = linkResponse;
  }
}
