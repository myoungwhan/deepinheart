import 'package:blurrycontainer/blurrycontainer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:deepinheart/Controller/Model/custom_banner_model.dart';
import 'package:deepinheart/Controller/Model/service_category_model.dart';
import 'package:deepinheart/Controller/Model/texnomy_model.dart';
import 'package:deepinheart/Controller/Viewmodel/service_provider.dart';
import 'package:deepinheart/Views/colors.dart';
import 'package:deepinheart/screens/home/widget/advoisor_card.dart';
import 'package:deepinheart/screens/home/widget/custom_banner_view.dart';
import 'package:deepinheart/screens/home/widget/custom_titlewithbutton.dart';
import 'package:deepinheart/screens/home/widget/freq_question_tile.dart';
import 'package:deepinheart/screens/home/widget/popular_laber_view.dart';
import 'package:deepinheart/screens/home/widget/sub_category_chip.dart';
import 'package:deepinheart/screens/home/widget/view_more_tellers_button.dart';
import 'package:deepinheart/screens/retings/widget/rating_tileview.dart';
import 'package:deepinheart/views/custom_text.dart';
import 'package:deepinheart/views/font_constants.dart';
import 'package:deepinheart/views/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class CategoryDetailScreen extends StatefulWidget {
  Category model;
  CategoryDetailScreen({Key? key, required this.model}) : super(key: key);

  @override
  _CategoryDetailScreenState createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  bool isForune = true;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (widget.model.name != enumServiceSection.Fortune.name) {
      setState(() {
        isForune = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, bool innerBoxIsScrolle) {
          return [
            SliverAppBar(
              expandedHeight: Get.height * 0.4,

              // toolbarHeight: 0.0,
              //  toolbarHeight: 0.0,
              leading: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Card(
                  color: Colors.black12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: IconButton(
                    onPressed: () {
                      Get.back();
                    },
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              ),
              floating: false,
              leadingWidth: 75,
              backgroundColor: Colors.white,
              automaticallyImplyLeading: false,
              surfaceTintColor: Colors.white,
              pinned: true,

              flexibleSpace: FlexibleSpaceBar(
                background: headerWidget(context),
              ),
            ),
          ];
        },

        body: Container(
          width: Get.width,
          padding: EdgeInsets.symmetric(horizontal: 15.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children:
                      widget.model.subCategories.map((e) {
                        return SubCategoryChip(
                          text: e.name,
                          color: e.getColor(),
                        );
                      }).toList(),
                ),
                UIHelper.verticalSpaceMd,
                PopularLaberView(
                  text:
                      "POPULAR".tr +
                      " ${widget.model.name.toUpperCase()} TELLERS",
                ),
                //  UIHelper.verticalSpaceMd,
                GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 items per row
                    crossAxisSpacing: 5.0, // Space between columns
                    mainAxisSpacing: 5.0, // Space between rows
                    childAspectRatio:
                        0.58, // Custom height (height/width ratio)
                  ),
                  itemCount: 4,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    // return AdvisorCardView(); // AdvisorCardView widget
                    return Container();
                  },
                ),

                UIHelper.verticalSpaceSm,

                ViewMoreTellersButton(
                  text: "View More ${widget.model.name} Tellers",
                  onTap: () {},
                ),
                UIHelper.verticalSpaceMd,
                CustomBannerView(
                  bannerModel: BannerModel(
                    bannerName: 'Special First Consultation Discount',
                    bannerType: 'text', // Image banner or text banner
                    imageUrl:
                        '', // Empty for text banners, URL for image banners
                    externalLink: 'https://example.com',
                    exposureBegin: DateTime.now(),
                    exposureEnd: DateTime.now().add(Duration(days: 30)),
                    couponDescription:
                        'Get 50% off on your first consultation as a new member.',
                    buttonText: 'Start Now',
                    buttonColor: Colors.blue, // Customize button color
                  ),
                ),

                UIHelper.verticalSpaceSm,
                PopularLaberView(
                  text: "Features of".tr + " ${widget.model.name}",
                ),

                UIHelper.verticalSpaceSm,
                Column(
                  children:
                      widget.model.features
                          .map(
                            (e) => ListTile(
                              tileColor: primaryColor.withAlpha(5),
                              contentPadding: EdgeInsets.all(0),
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                child: Icon(
                                  Icons.info_outline,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                              ),
                              minLeadingWidth: 40,
                              title: CustomText(
                                text: e.title,
                                weight: FontWeightConstants.medium,
                              ),
                              subtitle: CustomText(
                                text: e.text,
                                maxlines: 3,
                                weight: FontWeightConstants.regular,
                                fontSize: FontConstants.font_14,
                              ),
                            ),
                          )
                          .toList(),
                ),

                UIHelper.verticalSpaceSm,
                CustomBannerView(
                  bannerModel: BannerModel(
                    bannerName: 'Coin Charging Event',
                    bannerType: 'text', // Image banner or text banner
                    imageUrl:
                        '', // Empty for text banners, URL for image banners
                    externalLink: 'https://example.com',
                    exposureBegin: DateTime.now(),
                    exposureEnd: DateTime.now().add(Duration(days: 30)),
                    couponDescription:
                        'Get 20% bonus when charging over 10,000 coins!',
                    buttonText: 'Charge Now',
                    buttonColor: Colors.blue, // Customize button color
                  ),
                ),

                UIHelper.verticalSpaceSm,
                CustomTitleWithButton(
                  title: "Reviews".tr,
                  onButtonPressed: () {},
                ),
                UIHelper.verticalSpaceSm,

                SizedBox(
                  height: 205.0.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      return RatingTileview();
                    },
                  ),
                ),
                UIHelper.verticalSpaceSm,

                PopularLaberView(text: "Frequential ASKED Questions"),

                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: widget.model.questions.length,
                  itemBuilder: (context, index) {
                    return FreqQuestionTile(
                      model: widget.model.questions[index],
                    );
                  },
                ),
                UIHelper.verticalSpaceL,
              ],
            ),
          ),
        ),
      ),
    );
  }

  headerWidget(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: Get.width,
        height: Get.height * 0.4,
        margin: EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          image: DecorationImage(
            fit: BoxFit.cover,
            image: CachedNetworkImageProvider(widget.model!.image),
          ),
        ),
        child: BlurryContainer(
          blur: 0,
          elevation: 1,
          color: Colors.black.withAlpha(100),
          borderRadius: BorderRadius.circular(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: widget.model!.name,
                fontSize: 20.0,
                color: Colors.white,
                weight: FontWeightConstants.bold,
              ),
              UIHelper.verticalSpaceMd,
              CustomText(
                text: widget.model.description,
                fontSize: FontConstants.font_14,
                color: Colors.white70,
                height: 1.3,
              ),
              UIHelper.verticalSpaceMd,
            ],
          ),
        ),
      ),
    );
  }
}
