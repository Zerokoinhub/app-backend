import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:zero_koin/controllers/theme_controller.dart';
import 'package:zero_koin/view/bottom_bar.dart';
import 'package:zero_koin/services/api_service.dart';

import 'package:zero_koin/widgets/app_bar_container.dart';
import 'package:zero_koin/widgets/my_drawer.dart';
import 'package:zero_koin/widgets/pop_up_button.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  int leverageValue = 0;
  bool isLongPosition = true; // Default to long position
  final TextEditingController leverageController = TextEditingController();
  final TextEditingController entryPriceController = TextEditingController();
  final TextEditingController liquidationController = TextEditingController();

  @override
  void dispose() {
    leverageController.dispose();
    entryPriceController.dispose();
    liquidationController.dispose();
    super.dispose();
  }

  double calculateLiquidationPrice({
    required double entryPrice,
    required double leverage,
    required bool isLong,
  }) {
    if (leverage <= 0) return 0;

    if (isLong) {
      return entryPrice * (1 - (1 / leverage) + 0.005);
    } else {
      return entryPrice * (1 + (1 / leverage) - 0.005);
    }
  }

  void showAlertDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Required Field'),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void calculateLiquidation() {
    if (entryPriceController.text.isEmpty) {
      showAlertDialog('Please enter Entry Price');
      return;
    }
    if (leverageController.text.isEmpty) {
      showAlertDialog('Please enter Leverage');
      return;
    }

    double entryPrice = double.parse(entryPriceController.text);
    double leverage = double.parse(leverageController.text);

    double liquidationPrice = calculateLiquidationPrice(
      entryPrice: entryPrice,
      leverage: leverage,
      isLong: isLongPosition,
    );

    liquidationController.text = liquidationPrice.toStringAsFixed(2);

    // Increment calculator usage in backend
    ApiService.incrementCalculatorUsage().then((usage) {
      if (usage != null) {
        print('Calculator usage incremented: $usage');
      } else {
        print('Failed to increment calculator usage');
      }
    });
  }

  @override
  void initState() {
    super.initState();
  }

  void incrementLeverage() {
    setState(() {
      if (leverageController.text.isNotEmpty) {
        int currentValue = int.tryParse(leverageController.text) ?? 0;
        leverageValue = currentValue + 1;
        leverageController.text = leverageValue.toString();
      } else {
        leverageValue = 1;
        leverageController.text = leverageValue.toString();
      }
    });
  }

  void decrementLeverage() {
    setState(() {
      if (leverageController.text.isNotEmpty) {
        int currentValue = int.tryParse(leverageController.text) ?? 0;
        if (currentValue > 1) {
          leverageValue = currentValue - 1;
          leverageController.text = leverageValue.toString();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
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
              AppBarContainer(color: Colors.black.withOpacity(0.6), showTotalPosition: false),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (Navigator.canPop(context)) {
                          Get.back();
                        } else {
                          Get.offAll(() => const BottomBar());
                        }
                      },
                      child: const Image(
                        image: AssetImage("assets/arrow_back.png"),
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Text(
                      "Calculator",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Obx(
                  () => Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: themeController.contentBackgroundColor,
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Crypto Liquidation Calculator",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                color: themeController.textColor,
                              ),
                            ),
                            SizedBox(height: 25),
                            Container(
                              width: screenWidth,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: themeController.borderColor,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          "Entry Price",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: themeController.textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    TextFormField(
                                      controller: entryPriceController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                      ],
                                      style: TextStyle(
                                        color: themeController.textColor,
                                      ),
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: themeController.cardColor,
                                        hintText: "Entry Price",
                                        hintStyle: TextStyle(
                                          fontSize: 15,
                                          color: themeController.subtitleColor,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: BorderSide(
                                            color: themeController.borderColor,
                                            width: 2,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: BorderSide(
                                            color: themeController.borderColor,
                                            width: 2,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.red,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Text(
                                          "Leverage",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: themeController.textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    TextFormField(
                                      controller: leverageController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          if (value.isNotEmpty) {
                                            int? newValue = int.tryParse(value);
                                            if (newValue != null &&
                                                newValue > 0) {
                                              leverageValue = newValue;
                                            }
                                          } else {
                                            leverageValue = 0;
                                          }
                                        });
                                      },
                                      style: TextStyle(
                                        color: themeController.textColor,
                                      ),
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: themeController.cardColor,
                                        hintText:
                                            screenWidth < 360
                                                ? "Enter Leverage"
                                                : "Enter Leverage Details",
                                        hintStyle: TextStyle(
                                          fontSize: screenWidth < 360 ? 10 : 15,
                                          color: themeController.subtitleColor,
                                        ),

                                        suffixIcon: Container(
                                          width: screenWidth < 360 ? 120 : 160,
                                          decoration: BoxDecoration(
                                            color: Color(0xFF086F8A),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            children: [
                                              GestureDetector(
                                                onTap: decrementLeverage,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                                  child: Text(
                                                    "-",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                width: 1,
                                                height: 30,
                                                color: Colors.white.withValues(
                                                  alpha: 0.3,
                                                ),
                                              ),
                                              Text(
                                                leverageValue > 0
                                                    ? "${leverageValue}X"
                                                    : "0X",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize:
                                                      screenWidth < 360
                                                          ? 12
                                                          : 14,
                                                ),
                                              ),
                                              Container(
                                                width: 1,
                                                height: 30,
                                                color: Colors.white.withValues(
                                                  alpha: 0.3,
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: incrementLeverage,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                                  child: Text(
                                                    "+",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: BorderSide(
                                            color: themeController.borderColor,
                                            width: 2,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: BorderSide(
                                            color: themeController.borderColor,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Text(
                                          "Position Type",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: themeController.textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                isLongPosition = true;
                                              });
                                            },
                                            child: Container(
                                              padding: EdgeInsets.symmetric(vertical: 12),
                                              decoration: BoxDecoration(
                                                color: isLongPosition ? Colors.green : themeController.cardColor,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: isLongPosition ? Colors.green : themeController.borderColor,
                                                  width: 2,
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  "Long",
                                                  style: TextStyle(
                                                    color: isLongPosition ? Colors.white : themeController.textColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                isLongPosition = false;
                                              });
                                            },
                                            child: Container(
                                              padding: EdgeInsets.symmetric(vertical: 12),
                                              decoration: BoxDecoration(
                                                color: !isLongPosition ? Colors.red : themeController.cardColor,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: !isLongPosition ? Colors.red : themeController.borderColor,
                                                  width: 2,
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  "Short",
                                                  style: TextStyle(
                                                    color: !isLongPosition ? Colors.white : themeController.textColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Text(
                                          "Your Liquidation",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: themeController.textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    TextFormField(
                                      controller: liquidationController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                      ],
                                      textAlign: TextAlign.end,
                                      enabled: false,
                                      style: TextStyle(
                                        color: themeController.textColor,
                                      ),
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: themeController.cardColor,
                                        hintText: "18.00.0",
                                        hintStyle: TextStyle(
                                          fontSize: 15,
                                          color: themeController.subtitleColor,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: BorderSide(
                                            color: themeController.borderColor,
                                            width: 2,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: BorderSide(
                                            color: themeController.borderColor,
                                            width: 2,
                                          ),
                                        ),
                                        disabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: BorderSide(
                                            color: themeController.borderColor,
                                            width: 2,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.red,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    SizedBox(
                                      width: double.infinity,
                                      child: PopUpButton(
                                        buttonText: "Calculate Now",
                                        buttonColor: Color(0xFF086F8A),
                                        onPressed: calculateLiquidation,
                                        textColor: Colors.white,
                                        borderColor: Color(0xFF086F8A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 80,
                            ), // Add bottom padding to prevent overflow
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
}
