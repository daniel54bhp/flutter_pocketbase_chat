import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pocketbase_chat/app/models/user.dart';
import 'package:pocketbase_chat/app/modules/new_room/new_room_controller.dart';

class NewRoomView extends GetView<NewRoomController> {
  const NewRoomView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Nueva sala'),
        centerTitle: true,
        backgroundColor: Colors.black,
        leading: IconButton(
          onPressed: controller.loadUsers,
          icon: const Icon(Icons.refresh),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(
            height: 10.0,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: TextFormField(
              controller: controller.nameRoomController,
              decoration: const InputDecoration(
                labelText: "Nombre de Sala",
              ),
            ),
          ),
          const SizedBox(
            height: 10.0,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 10.0,
            ),
            child: Text(
              'Usuarios',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
            child: Text(
                'Seleciona los usuarios con los que quieres crear la sala de chat'),
          ),
          SizedBox(
            width: Get.width * .98,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: Get.width * .80,
                  child: TextFormField(
                    controller: controller.nameSearchController,
                    onFieldSubmitted: (value) async {
                      if (value != '') {
                        await controller.searchUser(textSearch: value);
                      }
                    },
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                        icon: Icon(Icons.search_outlined),
                        hintText: 'Buscar usuario'),
                  ),
                ),
                IconButton(
                    onPressed: () {
                      controller.closeSearch();
                    },
                    icon: const Icon(Icons.close))
              ],
            ),
          ),
          SizedBox(
            height: Get.height * .50,
            child: Obx(() => controller.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : controller.users.isEmpty
                    ? const Center(child: Text("No hay usuarios"))
                    : !controller.isSearch.value
                        ? ListView.builder(
                            itemCount: controller.users.length,
                            itemBuilder: (BuildContext context, int index) {
                              User user = controller.users[index];
                              bool isSelect = controller.checkSelect(
                                  idUser: user.id.toString());
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: isSelect
                                    ? Card(
                                        color: Colors.black,
                                        child: ListTile(
                                          onTap: () => controller.selectUser(
                                              idUser: user.id.toString()),
                                          title: Text(user.name ?? "No name",
                                              style: const TextStyle(
                                                  color: Colors.white)),
                                          // subtitle:
                                          //     LastMessageBuilder(chatRoom: room),

                                          // onTap: () => controller.onRoomTap(room),
                                        ),
                                      )
                                    : Card(
                                        child: ListTile(
                                          onTap: () => controller.selectUser(
                                              idUser: user.id.toString()),
                                          title: Text(user.name ?? "No name"),
                                          // subtitle:
                                          //     LastMessageBuilder(chatRoom: room),

                                          // onTap: () => controller.onRoomTap(room),
                                        ),
                                      ),
                              );
                            },
                          )
                        : ListView.builder(
                            itemCount: controller.usersSearch.length,
                            itemBuilder: (BuildContext context, int index) {
                              User user = controller.usersSearch[index];
                              bool isSelect = controller.checkSelect(
                                  idUser: user.id.toString());
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: isSelect
                                    ? Card(
                                        color: Colors.black,
                                        child: ListTile(
                                          onTap: () => controller.selectUser(
                                              idUser: user.id.toString()),
                                          title: Text(user.name ?? "No name",
                                              style: const TextStyle(
                                                  color: Colors.white)),
                                          // subtitle:
                                          //     LastMessageBuilder(chatRoom: room),

                                          // onTap: () => controller.onRoomTap(room),
                                        ),
                                      )
                                    : Card(
                                        child: ListTile(
                                          onTap: () => controller.selectUser(
                                              idUser: user.id.toString()),
                                          title: Text(user.name ?? "No name"),
                                          // subtitle:
                                          //     LastMessageBuilder(chatRoom: room),

                                          // onTap: () => controller.onRoomTap(room),
                                        ),
                                      ),
                              );
                            },
                          )),
          ),
          const Spacer(),
          SizedBox(
            width: Get.width * .80,
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                onPressed: () => controller.newRoom(),
                child: const Text('Crear')),
          )
        ],
      ),
    );
  }
}
