// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:chatview/chatview.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:pocketbase_chat/app/data/helper.dart';
import 'package:pocketbase_chat/app/data/message_builder.dart';
import 'package:pocketbase_chat/app/models/chat_room.dart';
import 'package:pocketbase_chat/app/models/user.dart';
import 'package:pocketbase_chat/app/services/storage_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime_type/mime_type.dart';

import 'dart:math' as Math;
import 'package:image/image.dart' as Im;

class PocketbaseService extends GetxService {
  static PocketbaseService get to => Get.find();
  //final _pocketBaseUrl = "http://79.153.92.241:80";
  //final _pocketBaseUrl = "http://127.0.0.1:8090";
  //final _pocketBaseUrl = "http://192.168.0.113:80";
  final _pocketBaseUrl = "http://192.168.0.46:80";
  //final _pocketBaseUrl = "http://10.0.2.2:8090";
  late PocketBase _client;
  late AuthStore _authStore;
  late String _temporaryDirectory;

  final _httpClient = HttpClient();
  final _cachedUsersData = {};
  User? user;
  bool get isAuth => user != null;

  Future<PocketbaseService> init() async {
    _temporaryDirectory = (await getTemporaryDirectory()).path;
    _initializeAuthStore();
    _client = PocketBase(_pocketBaseUrl, authStore: _authStore);
    // Listen to authStore changes
    _client.authStore.onChange.listen((AuthStoreEvent event) {
      if (event.model is RecordModel) {
        user = User.fromJson(event.model.toJson());
        user?.token = event.token;
        StorageService.to.user = user;
      }
    });
    return this;
  }

  void _initializeAuthStore() {
    _authStore = AuthStore();
    user = StorageService.to.user;
    String? token = user?.token;
    if (user == null || token == null) return;
    RecordModel model = RecordModel.fromJson(user!.toJson());
    _authStore.save(token, model);
  }

  /// Messages
  Future sendMessage(String roomId, Message message) async {
    try {
      // add message to database
      var result = await _client.collection('mensajes').create(
            body: MessageBuilder.parseMessageToJson(roomId, message),
            files: MessageBuilder.parseMessageToMultipart(message),
          );
      // update chatId in room, to trigger chat update
      await _client
          .collection('salas')
          .update(roomId, body: {'chat_id': result.id});
    } on ClientException catch (e) {
      throw e.errorMessage;
    }
  }

  Future<List<Message>> getMessages({
    required String? roomId,
    String? chatId,
  }) async {
    if (roomId == null) return [];
    try {
      String filterString = "room_id = '$roomId'";
      if (chatId != null) filterString = "id = '$chatId'";
      ResultList result =
          await _client.collection('mensajes').getList(filter: filterString);
      List<Message> messages = [];
      for (var e in result.items) {
        messages.add(await MessageBuilder.parseJsonToMessage(e.toJson(), e));
      }
      return messages;
    } on ClientException catch (e) {
      throw e.errorMessage;
    }
  }

  Future<UnsubscribeFunc> subscribeToChatUpdates({
    required String roomId,
    required Function(Message) onChat,
  }) {
    return _client.collection('salas').subscribe(roomId, (
      RecordSubscriptionEvent event,
    ) async {
      RecordModel? data = event.record;
      if (data == null) return;
      String? chatId = ChatRoom.fromJson(data.toJson()).chatId;
      if (chatId == null) return;
      List<Message> chats = await getMessages(roomId: roomId, chatId: chatId);
      if (chats.isNotEmpty) onChat(chats.first);
    });
  }

  Future<String> getProfilePhoto({required User user}) async {
    try {
      final linkResponse = _client.files.getUrl(
          RecordModel(
              collectionId: user.collectionId.toString(),
              collectionName: user.collectionName.toString(),
              created: user.created.toString(),
              data: {},
              expand: {},
              id: user.id.toString(),
              updated: user.updated.toString()),
          user.avatar.toString());

      return linkResponse.origin + linkResponse.path;
    } on ClientException catch (e) {
      throw e.errorMessage;
    }
  }

  Future<File> jpgTOpng(path) async {
    File imagePath = File(path);
    //get temporary directory
    final tempDir = await getTemporaryDirectory();
    int rand = Math.Random().nextInt(10000);
    //reading jpg image
    Im.Image? image = Im.decodeImage(imagePath.readAsBytesSync());
    //decreasing the size of image- optional
    Im.Image smallerImage = Im.copyResize(image!, width: 800);
    //get converting and saving in file
    File compressedImage = File('${tempDir.path}/img_$rand.png')
      ..writeAsBytesSync(Im.encodePng(smallerImage, level: 8));

    return compressedImage;
  }

  Future<String> changePhotoProfile(
      {required String userID, required File file}) async {
    try {
      final img = await jpgTOpng(file.path);
      file = img;
      final message = MessageBuilder.parseMessageToMultipart(Message(
          message: file.path.toString(),
          createdAt: DateTime.now(),
          sendBy: userID));
      final response =
          await _client.collection('usuarios').update(userID, files: message);

      final linkResponse =
          _client.files.getUrl(response, response.data['avatar'].toString());

      return 'linkResponse.origin + linkResponse.path';
    } on ClientException catch (e) {
      throw e.errorMessage;
    }
  }

  /// Rooms
  Future<List<ChatRoom>> getRoomsByUser({required idUser}) async {
    try {
      ResultList result = await _client
          .collection('usuarios_salas')
          .getList(filter: 'user = "$idUser" && room.type=1', expand: 'room');
      return result.items
          .map((e) => ChatRoom.fromJson(e.toJson()['expand']['room']))
          .toList();
    } on ClientException catch (e) {
      throw e.errorMessage;
    }
  }

  Future<void> addRoom(
      {required String room,
      required String userId,
      int type = 1,
      required List<dynamic> users}) async {
    try {
      final response = await _client.collection('salas').create(body: {
        'name': room,
        "created_by": userId,
        'type': type,
      });
      users.forEach((element) {
        _client.collection('usuarios_salas').create(body: {
          'user': element,
          "room": response.id,
        });
      });
    } on ClientException catch (e) {
      throw e.errorMessage;
    }
  }

  Future<ChatRoom> addRoomThowUsers({
    required String room,
    required String userId,
    required String toUserId,
  }) async {
    try {
      String idOne = '${userId}_$toUserId';
      String idThow = '${toUserId}_$userId';
      final response = await _client.collection('salas').getList(
            filter: 'users_ids="$idOne" || users_ids="$idThow"',
          );
      if (response.items.isEmpty) {
        final responseCreate = await _client.collection('salas').create(body: {
          'name': room,
          "created_by": userId,
          "users_ids": idOne,
          "type": 2,
        });
        ChatRoom model = ChatRoom.fromJson(responseCreate.toJson());
        List<dynamic> users = [userId, toUserId];
        users.forEach((element) {
          _client.collection('usuarios_salas').create(body: {
            'user': element,
            "room": model.id,
          });
        });
        return model;
      } else {
        ChatRoom model = ChatRoom.fromJson(response.items.first.toJson());
        return model;
      }
    } on ClientException catch (e) {
      throw e.errorMessage;
    }
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      await _client.collection('salas').delete(roomId);
    } on ClientException catch (e) {
      throw e.errorMessage;
    }
  }

  /// Auth
  Future login(String email, String password) async {
    try {
      RecordAuth userDataTemp = await _client
          .collection('usuarios')
          .authWithPassword(email, password);

      return userDataTemp;
    } on ClientException catch (e) {
      throw e.errorMessage;
    }
  }

  Future signUp(String name, String email, String password) async {
    try {
      final body = <String, dynamic>{
        "email": email,
        "password": password,
        "passwordConfirm": password,
        "name": name,
        "emailVisibility": true,
      };
      final response = await _client.collection('usuarios').create(body: body);

      return response;
    } on ClientException catch (e) {
      throw e.errorMessage;
    }
  }

  Future logout() async {
    _client.authStore.clear();
    StorageService.to.user = null;
  }

  Future<User> getUserDetails(
    String userId, {
    bool useCache = false,
  }) async {
    try {
      if (useCache && _cachedUsersData.containsKey(userId)) {
        return _cachedUsersData[userId];
      }
      final result = await _client.collection('usuarios').getOne(userId);
      var user = User.fromJson(result.toJson());

      _cachedUsersData[userId] = user;
      return user;
    } on ClientException catch (e) {
      Get.log(e.toString());
      throw e.errorMessage;
    }
  }

  Future<List<User>> getAllUsers() async {
    try {
      final result = await _client.collection('usuarios').getList();
      List<User> users =
          result.items.map((e) => User.fromJson(e.toJson())).toList();
      return users;
    } on ClientException catch (e) {
      Get.log(e.toString());
      throw e.errorMessage;
    }
  }

  Future<List<User>> getUserByName({required String textSearch}) async {
    try {
      print(textSearch);

      final result = await _client
          .collection('usuarios')
          .getList(filter: 'name ?~ "$textSearch"');
      print(result.items.first.data);
      List<User> users =
          result.items.map((e) => User.fromJson(e.toJson())).toList();
      return users;
    } on ClientException catch (e) {
      Get.log(e.toString());
      throw e.errorMessage;
    }
  }

  /// Helpers
  Uri getFileUrl(RecordModel recordModel, String fileName) =>
      _client.getFileUrl(recordModel, fileName);

  /// Either pass [uri] or [recordModel] to download file
  /// [useCache] will return the cached file if its already downloaded
  Future<File?> downloadFile({
    required RecordModel recordModel,
    required String fileName,
    bool useCache = false,
  }) async {
    try {
      Uri fileUri = _client.getFileUrl(recordModel, fileName);
      File file = File('$_temporaryDirectory/$fileName');
      if (useCache && file.existsSync()) return file;
      var request = await _httpClient.getUrl(fileUri);
      var response = await request.close();
      var bytes = await consolidateHttpClientResponseBytes(response);
      return await file.writeAsBytes(bytes);
    } catch (error) {
      return null;
    }
  }
}
