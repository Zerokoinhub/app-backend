import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zero_koin/controllers/theme_controller.dart';
import 'package:zero_koin/widgets/app_bar_container.dart';
import 'package:zero_koin/widgets/guide_text.dart';
import 'package:zero_koin/widgets/my_drawer.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:zero_koin/view/bottom_bar.dart';

import 'package:flutter_svg/flutter_svg.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    return Scaffold(
      drawer: MyDrawer(),
      body: Stack(
        children: [
          Image.asset(
            'assets/Background.jpg',
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),
          Column(
            children: [
              AppBarContainer(
                color: Colors.black.withValues(alpha: 0.6),
                showTotalPosition: false,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            // Navigate to home screen (BottomBar with index 0)
                            Get.offAll(() => const BottomBar(initialIndex: 0));
                          },
                          child: Image(
                            image: AssetImage("assets/arrow_back.png"),
                          ),
                        ),
                        SizedBox(width: 20),
                        Text(
                          "Guide",
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: Obx(
                  () => Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color:
                          themeController.isDarkMode
                              ? Colors.black.withValues(alpha: 0.8)
                              : Colors.white,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SvgPicture.asset(
                                  "assets/Info Icon.svg",
                                  width: 25,
                                  height: 25,
                                  colorFilter: ColorFilter.mode(
                                    themeController.isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "Zero Koin Guide",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 25,
                                    color: themeController.textColor,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 30),
                            Text(
                              "What is Zero Koin?",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 25,
                                color: themeController.textColor,
                              ),
                            ),
                            SizedBox(height: 1),
                            Text(
                              "Re-defining crypto with tokenized learning, smart tools & real-world rewards. Built for scale. Every revolution begins from Zero.",
                              style: TextStyle(
                                fontSize: 18,
                                color: themeController.subtitleColor,
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              "Start Mining - Earn 30 ZRK Every 6 Hours",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 25,
                                color: themeController.textColor,
                              ),
                            ),

                            SizedBox(height: 20),
                            buildImageCard(
                              imagePath: "assets/google_login.png",
                              text: "Sign in with your Google account.",
                              textList: ["New users get 1 free Energy."],
                            ),
                            buildImageCard(
                              imagePath: "assets/guide_1.png",
                              text:
                                  "Tap the \"Start\" button to earn 30 ZRK per session",
                            ),
                            buildImageCard(
                              imagePath: "assets/guide_2.png",
                              text:
                                  "You can mine up to 4 times a day, with 1 session every 6 hours",
                            ),
                            buildImageCard(
                              imagePath: "assets/guide_3.png",
                              text: "Tap the \"Claim\" button.",
                            ),
                            buildImageCard(
                              imagePath: "assets/earned_sessioned.png",
                              text: "You Earned 30 ZRK",
                            ),
                            SizedBox(height: 20),
                            Text(
                              "More Rewards (Bonus)",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 25,
                                color: themeController.textColor,
                              ),
                            ),
                            SizedBox(height: 15),

                            // GuideText(
                            //   title: "After GET ZRK, tap \"More Rewards\"",
                            // ),
                            buildImageCard(
                              text: "After GET ZRK, tap \"More Rewards\".",
                              imagePath: "assets/guide_1.png",
                            ),

                            // GuideText(
                            //   title:
                            //       "Follow our social media pages to receive \n extra ZRK as a bonus",
                            // ),
                            buildImageCard(
                              text:
                                  "Follow our social media pages to receive extra ZRK as a bonus",
                              imagePath: "assets/guide_5.png",
                            ),
                            buildImageCard(
                              text: "Platforms to follow us",
                              imagePath: "assets/guide_6.png",
                            ),

                            SizedBox(height: 20),
                            Text(
                              "Learn And Earn Daily Rewards:",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 25,
                                color: themeController.textColor,
                              ),
                            ),
                            SizedBox(height: 30),

                            // GuideText(
                            //   title: "Learn & Earn - Daily Learning Rewards",
                            // ),
                            GuideText(title: "Go to the learning sections."),
                            buildImageCard(
                              text: "Learn & Earn - Daily Learning Rewards",
                              imagePath: "assets/guide_5.png",
                              textList: [
                                "Go to the \"Learn amd Earn Daily\" Section.",
                              ],
                            ),

                            buildImageCard(
                              text: "Every day, you'll get 5 pages to read.",
                              textList: [
                                "Each page requires you to read and \n understand for 2 minutes.",
                                "After 2 minutes, the \"Next\" button will appear to go to next page.",
                                "When you complete all 5 pages in a day, \n you'll earn 10 ZRK as a reward",
                              ],
                              imagePath: "assets/final_guide.jpeg",
                            ),

                            SizedBox(height: 20),
                            Text(
                              "How to Add Zero Koin to MetaMask & Get Your Address:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 25,
                                color: themeController.textColor,
                              ),
                            ),
                            SizedBox(height: 30),

                            ListView(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              children: [
                                GuideText(
                                  title:
                                      "Go to the Play Store and search for \n MetaMask.",
                                ),
                                GuideText(
                                  title:
                                      "Download and install the MetaMask app.",
                                ),
                                Card(
                                  color: Colors.grey[300],
                                  child: Image.asset(
                                    'assets/1or2.png',
                                    height: 400,
                                    width: double.infinity,
                                  ),
                                ),
                                buildImageCard(
                                  imagePath: "assets/3.png",
                                  text: "Open the app and tap \"Add\"",
                                ),
                                buildImageCard(
                                  text: "Select \"Custom Token\"",
                                  imagePath: "assets/4.png",
                                ),
                                buildImageCard(
                                  text: "Select \"Select Network\"",
                                  imagePath: "assets/5.png",
                                ),
                                buildImageCard(
                                  text: "Select \"BNB Smart Chain Mainnet\"",
                                  imagePath: "assets/6.png",
                                ),
                                buildImageCard(
                                  text:
                                      "Paste the following Zero Koin contract \n address:",
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 38.0),
                                  child: GestureDetector(
                                    onTap: () {
                                      Clipboard.setData(
                                        const ClipboardData(
                                          text:
                                              "0x220c0a61747832bf6f61cb181d4adf72daf05014",
                                        ),
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Address copied to clipboard!',
                                          ),
                                        ),
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "0x220c0a61747832bf6f61cb181d4adf72daf05014",
                                            style: TextStyle(
                                              color: Colors.blue,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Image.asset("assets/copy.png"),
                                      ],
                                    ),
                                  ),
                                ),
                                buildImageCard(
                                  text:
                                      "Confirm that the token shows ZRK than tap \"Next\"",
                                  imagePath: "assets/7or8.png",
                                ),
                                buildImageCard(
                                  text: "Tap the \"Import\" button to finish.",
                                  imagePath: "assets/9.png",
                                ),
                                buildImageCard(
                                  text:
                                      "You will see a message: \"Import Successful\", than Tap \"Zero Koin\".",
                                  imagePath: "assets/10.png",
                                ),
                                buildImageCard(
                                  text:
                                      "Tap \"Receive\" to view your Zero Koin wallet address.",
                                  imagePath: "assets/11.png",
                                ),
                                buildImageCard(
                                  text: "Tap \"Copy address\" .",
                                  imagePath: "assets/12.png",
                                ),
                                buildImageCard(
                                  text: "Paste address to wallet address.",
                                  imagePath: "assets/13.png",
                                ),
                                buildImageCard(
                                  text: "Tap \"Connect\".",
                                  imagePath: "assets/14.png",
                                ),
                              ],
                            ),

                            SizedBox(height: 20),

                            Text(
                              "Invite & Earn:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 25,
                                color: themeController.textColor,
                              ),
                            ),

                            // GuideText(
                            //   title:
                            //       'Step 1: "Invite & Earn" Enter this section.',
                            // ),
                            buildImageCard(
                              text:
                                  'Step 1: "Invite & Earn" Enter this section.',
                              imagePath: 'assets/guide_1.png',
                            ),
                            // GuideText(
                            //   title:
                            //       "Step 2: Here you can copy or share your\n reference number",
                            // ),
                            buildImageCard(
                              text:
                                  "Step 2: Here you can copy or share your reference number",
                              imagePath: 'assets/invite_1.jpeg',
                            ),
                            // GuideText(
                            //   title:
                            //       "After your friend clicks on the link and\n installs the application and registers, you\n will be rewarded.",
                            // ),
                            buildImageCard(
                              text:
                                  "After your friend clicks on the link and installs the application and registers, you will be rewarded.",
                              imagePath: 'assets/invite_2.jpeg',
                            ),

                            SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildImageCard({
    String? imagePath,
    required String text,
    List<String>? textList,
  }) {
    final ThemeController themeController = Get.find<ThemeController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(top: 30),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\u2022',
                style: TextStyle(
                  color: themeController.subtitleColor,
                  fontSize: 18,
                  height: 1.4,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: themeController.subtitleColor,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Dynamically show bullet points from textList (if exists)
        if (textList != null && textList.isNotEmpty)
          ...textList.map(
            (t) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ).copyWith(top: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\u2022',
                    style: TextStyle(
                      color: themeController.subtitleColor,
                      fontSize: 18,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t,
                      style: TextStyle(
                        color: themeController.subtitleColor,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        imagePath != null
            ? Card(
              color: Colors.grey[300],
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Image.asset(
                imagePath,
                width: double.infinity,
                height: 400,
              ),
            )
            : Container(),
      ],
    );
  }
}
