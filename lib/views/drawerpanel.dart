// ignore_for_file: prefer_const_constructors

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:deepinheart/views/text_styles.dart';

class drawer extends StatefulWidget {
  var selectedPage;
  drawer(this.selectedPage);
  @override
  State<drawer> createState() => _drawerState();
}

class _drawerState extends State<drawer> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build

    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width * 0.2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.71, 0.94),
          end: Alignment(0.8, -0.82),
          colors: [
            const Color(0xffA31C53),
            const Color(0xFFA12892),
            const Color(0xFF2A012B)
          ],
          stops: [0.0, 0.03, 1.0],
        ),
      ),
      child: Column(
        // ignore: prefer_const_literals_to_create_immutables
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: CircleAvatar(
              radius: 40, // Image radius
              child: Image.asset(
                "images/hrlogo.jpeg",
              ),
            ),
          ),

          FadeInUp(
            child: Container(
                margin: EdgeInsets.only(top: 20),
                child: Text("Welcome Charis Manor",
                    style: textStyleLMS(color: Colors.white, fontSize: 20.0))),
          ),
          SizedBox(
            height: 30,
          ),
          Container(
            height: 1,
            color: Colors.white,
          ),
          SizedBox(
            height: 20,
          ),
          InkWell(
            onTap: () {
              // Get.to(AddProducts());
              print("clicked dashboard");
            },
            child: customlisttile(
              context: context,
              img: "images/dashboard.png",
              text: "Products",
            ),
          ),
          InkWell(
            onTap: () {
              //   Get.to(UserInstallmentScreen());
              print("clicked investor");
            },
            child: customlisttile(
              context: context,
              img: "images/people.png",
              text: "Users Installment",
            ),
          ),

          // InkWell(
          //   onTap:(){

          //     // Get.to(InvestingDetail()

          //     // );
          //   print("clicked sales");
          //   },
          // child: customlisttile(
          //   context: context,
          //   img: "images/money.png",
          //   text: "Invoices",

          // ),),

          // ),
          // InkWell(
          //   onTap: (){
          //  //   Get.to(InvestorDetail());

          //   },
          //   child: customlisttile(
          //     context: context,
          //     img: "images/money.png",
          //     text: "Purchases",
          //   ),
          // ),
          // customlisttile(
          //   context: context,
          //   img: "images/home.png",
          //   text: "Rentals",
          // ),
          // customlisttile(
          //   context: context,
          //   img:  "images/place.png",
          //   text: "Lands",
          // ),
          Spacer(),
          InkWell(
            onTap: () {
              //     Get.to(LoginPage());
            },
            child: Container(
              margin: EdgeInsets.only(
                bottom: 20,
              ),
              child: logoutButton(
                context,
                "Logout",
                AssetImage(
                  "images/logout.png",
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget customlisttile({context, var img, var text, indexx}) {
    return Container(
      child: ListTile(
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Image(
            image: AssetImage(
              img,
            ),
            height: 18,
            width: 18,
          ),
        ),
        // onTap: () {
        //   setState(() {
        //     selectedPage = text;
        //   }
        //   );
        // },

        title: Text(
          text,
          style: textStyleLMS(color: Colors.white, fontSize: 14.0),
        ),
        trailing: widget.selectedPage == text
            ? Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: Colors.white),
              )
            : Container(
                width: 0,
                height: 0,
              ),
      ),
    );
  }

  Widget logoutButton(context, var text, var image) {
    return Container(
      height: 40,
      margin: EdgeInsets.only(left: 15, right: 15),
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(text, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(
            width: 10,
          ),
          Image(
            image: image,
            width: 20,
            height: 15,
          )
        ],
      ),
    );
  }
}
