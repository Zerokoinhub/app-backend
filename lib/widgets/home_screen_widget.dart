import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeScreenWidget extends StatelessWidget {
  const HomeScreenWidget({
    super.key,
    required this.title,
    required this.subTitle,
    required this.imageURl,
  });

  final String title;
  final String subTitle;
  final String imageURl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      width: 183,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: imageURl.toLowerCase().endsWith('.svg')
                  ? (imageURl.contains('tabler_battery-2-filled') ||
                      imageURl.contains('Group (1).svg') ||
                      imageURl.contains('Vector (7).svg')
                      ? SvgPicture.asset(
                          imageURl,
                          fit: BoxFit.contain,
                        )
                      : SvgPicture.asset(
                          imageURl,
                          fit: BoxFit.contain,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ))
                  : Image.asset(imageURl, fit: BoxFit.contain),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: 1),
                  Text(
                    subTitle,
                    style: TextStyle(
                      fontSize: 15.44,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
