import 'package:flutter/material.dart';
import 'package:zero_koin/widgets/wallet_web3_widget.dart';

class WalletWeb3Popup extends StatefulWidget {
  final VoidCallback? onMetaMaskConnect;
  final VoidCallback? onTrustWalletConnect;
  final bool isConnecting;

  const WalletWeb3Popup({
    super.key,
    this.onMetaMaskConnect,
    this.onTrustWalletConnect,
    this.isConnecting = false,
  });

  @override
  State<WalletWeb3Popup> createState() => _WalletWeb3PopupState();
}

class _WalletWeb3PopupState extends State<WalletWeb3Popup> {
  String selectedWallet = 'trustWallet';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive font sizes
    final titleFontSize = screenWidth * 0.045; // Responsive title font size
    final buttonFontSize = screenWidth * 0.04; // Responsive button font size
    final orFontSize = screenWidth * 0.05; // Responsive "OR" text font size
    final launchingSoonFontSize =
        screenWidth * 0.025; // Responsive "Launching Soon" font size

    return Container(
      width: screenWidth * 0.9, // 90% of screen width
      constraints: BoxConstraints(
        maxWidth: 400, // Maximum width for larger screens
        minWidth: 300, // Minimum width for smaller screens
        maxHeight: screenHeight * 0.5, // Maximum 50% of screen height
      ),
      padding: EdgeInsets.only(
        left: screenWidth * 0.05, // 5% of screen width
        right: screenWidth * 0.05, // 5% of screen width
        top: screenHeight * 0.02, // 2% of screen height
        bottom: screenHeight * 0.05, // Small bottom padding
      ),
      decoration: BoxDecoration(
        color: Color(0xFF0C091E),
        border: Border.all(color: Colors.white, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(top: screenHeight * 0.02),
            child: Text(
              "Wallet Web 3",
              style: TextStyle(color: Colors.white, fontSize: titleFontSize),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: screenHeight * 0.015), // Responsive spacing
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap:
                    widget.isConnecting
                        ? null
                        : () async {
                          setState(() {
                            selectedWallet = 'trustWallet';
                          });

                          // Call the Trust Wallet connection function
                          if (widget.onTrustWalletConnect != null) {
                            widget.onTrustWalletConnect!();
                            // Close the popup after initiating connection
                            Navigator.of(context).pop();
                          }
                        },
                child: WalletWeb3Widget(
                  containerColor:
                      selectedWallet == 'trustWallet'
                          ? Color(0xFF0682A2)
                          : Color(0xFF393746),
                  imageUrl: "assets/trust.png",
                  text:
                      widget.isConnecting
                          ? "CONNECTING..."
                          : "CONNECT-TRUSTWALLET",
                  fontSize: buttonFontSize,
                ),
              ),
              SizedBox(height: screenHeight * 0.008), // Responsive spacing
              GestureDetector(
                onTap:
                    widget.isConnecting
                        ? null
                        : () async {
                          setState(() {
                            selectedWallet = 'metamask';
                          });

                          // Call the MetaMask connection function
                          if (widget.onMetaMaskConnect != null) {
                            widget.onMetaMaskConnect!();
                            // Close the popup after initiating connection
                            Navigator.of(context).pop();
                          }
                        },
                child: WalletWeb3Widget(
                  containerColor:
                      selectedWallet == 'metamask'
                          ? Color(0xFF0682A2)
                          : Color(0xFF393746),
                  imageUrl: "assets/icon-metamask.png",
                  text:
                      widget.isConnecting
                          ? "CONNECTING..."
                          : "CONNECT-METAMASK",
                  fontSize: buttonFontSize,
                ),
              ),
              SizedBox(height: screenHeight * 0.008), // Responsive spacing
              SizedBox(height: screenHeight * 0.02), // Responsive spacing
              Text(
                "OR",
                style: TextStyle(color: Colors.white, fontSize: orFontSize),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 0),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  height: screenHeight * 0.025,
                  width: screenWidth * 0.28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    color: Color(0xFF0682A2),
                  ),
                  child: Center(
                    child: Text(
                      "Launching Soon",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: launchingSoonFontSize,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
              WalletWeb3Widget(
                containerColor: Color(0xFF393746),
                imageUrl: "assets/zero_koin_logo.png",
                text: "CONNECT-ZEROKWALLET",
                fontSize: buttonFontSize,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
