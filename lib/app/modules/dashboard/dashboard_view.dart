import 'dart:async';
import 'dart:io';

import 'package:chatview/chatview.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pocketbase_chat/app/data/helper.dart';
import 'package:pocketbase_chat/app/models/chat_room.dart';
import 'package:pocketbase_chat/app/models/user.dart';
import 'package:pocketbase_chat/app/routes/app_pages.dart';
import '../../services/pocketbase_service.dart';
import 'dashboard_controller.dart';

Timer? _timer;

class DashboardView extends GetView<DashboardController> {
  const DashboardView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: Get.size.height * .80,
            child: TabBarView(controller: controller.tabController, children: [
              Scaffold(
                appBar: AppBar(
                  title: const Text('Usuarios'),
                  centerTitle: true,
                  backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                  leading: IconButton(
                    onPressed: controller.loadUsers,
                    icon: const Icon(Icons.refresh),
                  ),
                  actions: [
                    IconButton(
                      onPressed: controller.onLogoutTap,
                      icon: const Icon(Icons.logout),
                    ),
                  ],
                ),
                body: Obx(() => controller.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : controller.users.isEmpty
                        ? const Center(child: Text("No hay usuarios"))
                        : ListView.builder(
                            itemCount: controller.users.length,
                            itemBuilder: (BuildContext context, int index) {
                              User user = controller.users[index];
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Card(
                                  child: ListTile(
                                    onTap: () async {
                                      final roomResponse = await controller
                                          .createOrGetRoomThowUser(
                                              idToUser: user.id.toString());
                                      if (roomResponse != null) {
                                        Get.toNamed(Routes.CHATTING,
                                            arguments: [roomResponse, user]);
                                      }
                                    },
                                    title: Text(user.name ?? "No name"),
                                    // subtitle:
                                    //     LastMessageBuilder(chatRoom: room),
                                    trailing:
                                        const Icon(Icons.arrow_forward_ios),

                                    // onTap: () => controller.onRoomTap(room),
                                  ),
                                ),
                              );
                            },
                          )),
              ),
              Scaffold(
                appBar: AppBar(
                  title: const Text('Salas'),
                  centerTitle: true,
                  backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                  leading: IconButton(
                    onPressed: controller.loadRooms,
                    icon: const Icon(Icons.refresh),
                  ),
                  actions: [
                    IconButton(
                      onPressed: controller.addNewRoom,
                      icon: const Icon(Icons.add),
                    ),
                    IconButton(
                      onPressed: controller.onLogoutTap,
                      icon: const Icon(Icons.logout),
                    ),
                  ],
                ),
                body: Obx(() => controller.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : controller.rooms.isEmpty
                        ? const Center(
                            child: Text("No hay Salas de chats, agrega una +"))
                        : ListView.builder(
                            itemCount: controller.rooms.length,
                            itemBuilder: (BuildContext context, int index) {
                              ChatRoom room = controller.rooms[index];
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Card(
                                  child: ListTile(
                                    title: Text(room.name ?? "No name"),
                                    subtitle:
                                        LastMessageBuilder(chatRoom: room),
                                    trailing:
                                        const Icon(Icons.arrow_forward_ios),
                                    onLongPress: () =>
                                        controller.onRoomLongTap(room),
                                    onTap: () => controller.onRoomTap(room),
                                  ),
                                ),
                              );
                            },
                          )),
              ),
              Scaffold(
                  appBar: AppBar(
                    title: const Text('Perfil'),
                    centerTitle: true,
                    backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                    leading: IconButton(
                      onPressed: controller.loadRooms,
                      icon: const Icon(Icons.refresh),
                    ),
                    actions: [
                      IconButton(
                        onPressed: controller.onLogoutTap,
                        icon: const Icon(Icons.logout),
                      ),
                    ],
                  ),
                  body: Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 10.0,
                        ),
                        InkWell(
                          onTap: () => mainDialogBottom(
                              context,
                              Column(
                                children: [
                                  ListTile(
                                    onTap: () async {
                                      File? file = await getImage(
                                          type: ImageSource.camera);
                                      if (file != null) {
                                        await controller.changeProfilePhoto(
                                            file: file);
                                      }
                                    },
                                    title: const Text('Cámara'),
                                  ),
                                  ListTile(
                                    onTap: () async {
                                      File? file = await getImage(
                                          type: ImageSource.gallery);
                                      if (file != null) {
                                        await controller.changeProfilePhoto(
                                            file: file);
                                      }
                                    },
                                    title: const Text('Galería'),
                                  )
                                ],
                              )),
                          child: CircleAvatar(
                              radius: 1.0,
                              backgroundImage:
                                  NetworkImage(controller.photo.toString())),
                        ),
                        const SizedBox(
                          height: 20.0,
                        ),
                        Text(
                          PocketbaseService.to.user!.name.toString(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20.0,
                              color: Colors.black),
                        )
                      ],
                    ),
                  )),
            ]),
          ),
          const Spacer(),
          SizedBox(
            height: Get.size.height * .10,
            child: Container(
              decoration: const BoxDecoration(color: Colors.black, boxShadow: [
                BoxShadow(
                    blurRadius: 20.0, color: Color.fromARGB(255, 197, 189, 189))
              ]),
              child: TabBar(
                  controller: controller.tabController,
                  indicatorColor: Colors.white,
                  tabs: [
                    IconButton(
                        onPressed: () => controller.tabController.index = 0,
                        icon: const Icon(
                          Icons.people,
                          color: Colors.white,
                        )),
                    IconButton(
                        onPressed: () => controller.tabController.index = 1,
                        icon: const Icon(
                          Icons.chat,
                          color: Colors.white,
                        )),
                    IconButton(
                        onPressed: () {
                          controller.tabController.index = 2;
                          controller.profilePhoto();
                        },
                        icon: const Icon(
                          Icons.person,
                          color: Colors.white,
                        ))
                  ]),
            ),
          )
        ],
      ),
    );
  }
}

class LastMessageBuilder extends StatelessWidget {
  final ChatRoom chatRoom;
  const LastMessageBuilder({key, required this.chatRoom, ss});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: PocketbaseService.to
          .getMessages(roomId: chatRoom.id, chatId: chatRoom.chatId),
      initialData: const <Message>[],
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        List<Message> messages = snapshot.data;
        if (messages.isEmpty) {
          return const Text("No hay mensajes");
        }
        Message message = messages.first;
        if (message.messageType == MessageType.image) {
          return Text("Imagen de: ${message.sendBy}");
        } else if (message.messageType == MessageType.voice) {
          return Text("Mensaje de voz de: ${message.sendBy}");
        }
        return Text(message.message);
      },
    );
  }
}
