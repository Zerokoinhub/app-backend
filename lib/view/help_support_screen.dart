import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});
  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {

  Future<void> _showEmailWarning(String email) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: const Text(
            'Make sure you are logged in with the same email as in your ZeroKoin app before proceeding.',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0682A2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _launchEmail(email);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );

    try {
      // Try to launch with platformDefault first to show app chooser
      await launchUrl(
        emailUri,
        mode: LaunchMode.platformDefault,
      );
    } catch (e) {
      // Fallback to externalApplication mode
      try {
        await launchUrl(
          emailUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e2) {
        // Final fallback to share
        await SharePlus.instance.share(ShareParams(text: email));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Image.asset(
            'assets/Background.jpg',
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // Header with transparent background
                Container(
                  height: screenHeight * 0.15,
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 20),
                        const Text(
                          "Help and Support",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          // Main Title Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black,
                                ),
                                children: [
                                  TextSpan(text: "Get in Touch with the Right\n"),
                                  TextSpan(
                                    text: "Team",
                                    style: TextStyle(
                                      color: Color(0xFF00C9FF),
                                      fontWeight: FontWeight.w900,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),

                          // General Information Section
                          const Text(
                            "General information",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 15),
                          _buildContactCard(
                            icon: null,
                            email: "info@zerokoin.com",
                            onTap: () => _showEmailWarning("info@zerokoin.com"),
                            svgAsset: 'assets/info.svg',
                          ),
                          const SizedBox(height: 30),

                          // Technical Issues Section
                          const Text(
                            "Technical issues & bug reports",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 30),
                          _buildContactCard(
                            icon: null,
                            email: "support@zerokoin.com",
                            onTap: () => _showEmailWarning("support@zerokoin.com"),
                            svgAsset: 'assets/support.svg',
                          ),
                          const SizedBox(height: 30),

                          // Business Inquiries Section
                          const Text(
                            "For business inquiries, token sales, listing deals",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 30),
                          _buildContactCard(
                            icon: null,
                            email: "sales@zerokoin.com",
                            onTap: () => _showEmailWarning("sales@zerokoin.com"),
                            svgAsset: 'assets/sales.svg',
                            iconSize: 36,
                          ),
                          const SizedBox(height: 30),

                          // Admin Level Section
                          const Text(
                            "Admin-level queries, legal, compliance, escalation",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 30),
                          _buildContactCard(
                            icon: null,
                            email: "admin@zerokoin.com",
                            onTap: () => _showEmailWarning("admin@zerokoin.com"),
                            svgAsset: 'assets/admin.svg',
                            iconSize: 36,
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    IconData? icon,
    required String email,
    required VoidCallback onTap,
    String? svgAsset,
    double iconSize = 30,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: Colors.white,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(2.5),
              child: Container(
                child: svgAsset != null
                    ? SvgPicture.asset(
                        svgAsset,
                        width: iconSize,
                        height: iconSize,
                      )
                    : Icon(
                        icon,
                        color: Colors.white,
                        size: iconSize,
                      ),
              ),
            ),
            const SizedBox(width: 2),
            Text(
              email,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
