// import 'dart:io';

// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/foundation.dart';

// class Storage {
//   final FirebaseStorage storage = FirebaseStorage.instance;
//   Future<String> uploadFile(
//       String filePath, String fileName, storageRefrence) async {
//     var dowurl;
//     File file = File(filePath);
//     try {
//       UploadTask task = storage
//           .ref(storageRefrence)
//           .putFile(file);
//       dowurl = await (await task.whenComplete(() {})).ref.getDownloadURL();
//       print(">>>+" + dowurl);
//       return dowurl;
//     } on FirebaseException catch (e) {
//       print(e);
//     }
//     return dowurl;
//   }

//   Future<String> uploadFileMessage(
//     String filePath,
//     String fileName,
//   ) async {
//     var dowurl;
//     File file = File(filePath);
//     try {
//       UploadTask task = storage.ref('chat/$fileName/').putFile(file);

//       task.snapshotEvents.listen((event) {
//         double _progress =
//             event.bytesTransferred.toDouble() / event.totalBytes.toDouble();
//         print(_progress.toString() + "((((((((((");
//         //  });
//       }).onError((error) {
//         print(error.toString() + "__________");
//         // do something to handle error
//       });

//       dowurl = await (await task.whenComplete(() {})).ref.getDownloadURL();
//       print(">>>+" + dowurl);
//       return dowurl;
//     } on FirebaseException catch (e) {
//       print(e);
//     }
//     return dowurl;
//   }

//   // Future<void> uploadPromisaryFile(
//   //     File filePath, String clubid, String userId) async {
//   //   try {
//   //     await storage.ref('promissorynotes/$clubid/$userId').putFile(filePath);
//   //   } on FirebaseException catch (e) {
//   //     print(e);
//   //   }
//   // }

//   Future<String> downloadURL(String imageName, isFront) async {
//     String url = await storage
//         .ref('cnic/$imageName+${isFront ? "/front" : "/back"}')
//         .getDownloadURL();

//     return url;
//   }

//   Future<String> downloadURlPromisaryFile(
//       String filePath, String clubid, String userId) async {
//     String url =
//         await storage.ref('promissorynotes/$clubid/$userId').getDownloadURL();
//     return url;
//   }
// }
