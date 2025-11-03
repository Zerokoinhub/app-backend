import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

class SocailMediaWidgets extends StatelessWidget {
  const SocailMediaWidgets({
    super.key, 
    required this.imageUrl,
    required this.socialMediaUrl,
  });

  final String imageUrl;
  final String socialMediaUrl;

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse(socialMediaUrl);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Image.asset("assets/blur_background.png", height: 100, width: 100),
            SvgPicture.asset(imageUrl, height: 40, width: 40),
          ],
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _launchUrl,
          style: ElevatedButton.styleFrom(
            side: BorderSide(color: Colors.white),
            backgroundColor: Color(0xFF0682A2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text("Follow", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
