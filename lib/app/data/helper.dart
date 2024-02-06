import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:file_picker/file_picker.dart';

/// Extensions
extension ClientExceptionExtension on ClientException {
  String get errorMessage {
    var message = response["message"] ?? "";
    var data = response["data"];
    try {
      data.forEach((key, value) {
        var detailedMessage = value["message"];
        if (detailedMessage != null) {
          message += detailedMessage.toString();
        }
      });
    } catch (_) {}
    try {
      if (originalError != null) {
        message += ' $originalError';
      }
    } catch (_) {}
    return message;
  }
}

/// Snackbar
void showErrorSnackbar(String message) {
  Get.showSnackbar(GetSnackBar(
    messageText: Text(
      message,
      style: const TextStyle(color: Colors.white),
    ),
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: Colors.red,
    duration: const Duration(seconds: 2),
  ));
}

void showSuccessSnackbar(String message) {
  Get.showSnackbar(
    GetSnackBar(
      messageText: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
    ),
  );
}

void mainDialogBottom(BuildContext context, childWidget) {
  showGeneralDialog(
    barrierLabel: "Barrier",
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 400),
    context: context,
    pageBuilder: (_, __, ___) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0),
          height: 130.0,
          width: Get.width,
          child: Material(
            child: childWidget,
          ),
          decoration: const BoxDecoration(color: Colors.white),
        ),
      );
    },
    transitionBuilder: (_, anim, __, child) {
      return SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: const Offset(0, 0))
            .animate(anim),
        child: child,
      );
    },
  );
}

Future<File?> getImage({required ImageSource type}) async {
  final ImagePicker picker = ImagePicker();
  late XFile? file;
  file = await picker.pickImage(source: type);

  if (file != null) {
    return File(file.path);
  }

  return null;
}

Future<File?> getFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles();

  if (result != null) {
    File file = File(result.files.first.path!);
    return file;
  }

  return null;
}
