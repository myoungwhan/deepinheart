import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:deepinheart/Controller/Viewmodel/userviewmodel.dart';
import 'package:deepinheart/config/string_constants.dart';
import 'package:deepinheart/views/colors.dart';

class ProfileImageView extends StatefulWidget {
  const ProfileImageView({Key? key}) : super(key: key);

  @override
  _ProfileImageViewState createState() => _ProfileImageViewState();
}

class _ProfileImageViewState extends State<ProfileImageView> {
  final _picker = ImagePicker();
  XFile? pickedFile;
  bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    return profileicon(context);
  }

  Container profileicon(BuildContext context, {String? url}) {
    return Container(
      width: 80,
      height: 80,
      child: Stack(
        children: [
          pickedFile != null
              ? CircleAvatar(
                  radius: 50.0,
                  backgroundImage: FileImage(File(pickedFile!.path)),
                )
              : url != null
                  ? CircleAvatar(
                      radius: 50.0,
                      backgroundImage: CachedNetworkImageProvider(url),
                    )
                  : CircleAvatar(
                      radius: 50.0,
                      backgroundImage: CachedNetworkImageProvider(ringImage),
                    ),
          Positioned(
            right: 5,
            bottom: 0,
            child: Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                border: Border.all(),
                shape: BoxShape.circle,
                color: whiteColor,
              ),
              child: IconButton(
                padding: EdgeInsets.all(3),
                onPressed: () {
                  showAlertForImageSelection(context);
                },
                icon: Icon(Icons.add, size: 15.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectImage(bool isFromCamera) async {
    if (isFromCamera) {
      pickedFile = await _picker.pickImage(source: ImageSource.camera);
    } else {
      pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    }
    UserViewModel provider = Provider.of<UserViewModel>(context, listen: false);
    var profileurl = "";
    EasyLoading.show();
    if (pickedFile != null) {
      // profileurl =
      //     await provider.uploadFile(pickedFile!.path.toString(), "profile");
    } else {
      // profileurl = provider.userModel!.profile_img;
    }
    // await provider.updateUser(
    //     docId: provider.userModel!.docId,
    //     context: context,
    //     payload: {"profile_img": profileurl});
    EasyLoading.dismiss();
  }

  showAlertForImageSelection(BuildContext context) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("Gallery".tr),
      onPressed: () {
        Navigator.pop(context);
        _selectImage(false);
      },
    );
    Widget continueButton = TextButton(
      child: Text("Camera".tr),
      onPressed: () {
        Navigator.pop(context);
        _selectImage(true);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Profile Photo".tr),
      content: Text("Choose a Photo Source".tr),
      actions: [cancelButton, continueButton],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
