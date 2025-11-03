import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:zero_koin/widgets/app_bar_container.dart';
import 'package:zero_koin/widgets/socail_media_widgets.dart';
import 'package:zero_koin/widgets/my_drawer.dart';
import 'package:zero_koin/services/api_service.dart';

class SocailMediaPages extends StatefulWidget {
  const SocailMediaPages({super.key});

  @override
  State<SocailMediaPages> createState() => _SocailMediaPagesState();
}

class _SocailMediaPagesState extends State<SocailMediaPages> {
  List<File> _selectedFiles = [];

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        List<File> newFiles =
            result.files
                .where((file) => file.path != null)
                .map((file) => File(file.path!))
                .toList();

        // Check for duplicate file names
        List<String> existingFileNames =
            _selectedFiles.map((file) => file.path.split('/').last).toList();
        List<File> uniqueNewFiles =
            newFiles.where((file) {
              String fileName = file.path.split('/').last;
              return !existingFileNames.contains(fileName);
            }).toList();

        if (uniqueNewFiles.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('All selected files already exist'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedFiles.addAll(uniqueNewFiles);
        });

        if (mounted) {
          String message =
              uniqueNewFiles.length == 1
                  ? 'File selected: ${uniqueNewFiles.first.path.split('/').last}'
                  : '${uniqueNewFiles.length} files selected';

          if (uniqueNewFiles.length < newFiles.length) {
            message +=
                ' (${newFiles.length - uniqueNewFiles.length} duplicate files skipped)';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting files: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _clearFiles() {
    setState(() {
      _selectedFiles.clear();
    });
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _sendFiles() async {
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No screenshots selected to upload'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.black.withValues(alpha: 0.8),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C9FF)),
                ),
                SizedBox(height: 16),
                Text(
                  'Uploading screenshots...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        },
      );

      // Filter only image files (jpg, jpeg, png) for screenshot upload
      List<File> imageFiles =
          _selectedFiles.where((file) {
            String extension = file.path.split('.').last.toLowerCase();
            return ['jpg', 'jpeg', 'png'].contains(extension);
          }).toList();

      if (imageFiles.isEmpty) {
        // Close loading dialog
        if (mounted) {
          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please select at least one image file (JPG, JPEG, PNG)',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Upload screenshots using API service
      final result = await ApiService.uploadScreenshots(imageFiles);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();

        if (result != null) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${imageFiles.length} screenshot${imageFiles.length > 1 ? 's' : ''} uploaded successfully!',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Clear files after successful upload
          setState(() {
            _selectedFiles.clear();
          });
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload screenshots. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if it's still open
      if (mounted) {
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting files: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
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
          SingleChildScrollView(
            child: Column(
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
                              Navigator.pop(context);
                            },
                            child: Image(
                              image: AssetImage("assets/arrow_back.png"),
                            ),
                          ),
                          SizedBox(width: 20),
                          Text(
                            "Back",
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Follow our social media pages\n",
                              style: TextStyle(
                                color: Colors.white,
                                fontStyle: FontStyle.italic,
                                fontSize: 20,
                              ),
                            ),
                            TextSpan(
                              text: "Get 30 ZRK",
                              style: TextStyle(
                                color: Color(0xFF00C9FF),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30),
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SocailMediaWidgets(
                                imageUrl: 'assets/Telegram.svg',
                                socialMediaUrl: 'https://t.me/zerokoinapp',
                              ),
                              SocailMediaWidgets(
                                imageUrl: 'assets/Discord.svg',
                                socialMediaUrl:
                                    'https://discord.com/invite/KauZWYznV8',
                              ),
                              SocailMediaWidgets(
                                imageUrl: 'assets/X.svg',
                                socialMediaUrl: 'https://x.com/zerokoinapp',
                              ),
                            ],
                          ),
                          SizedBox(height: 50),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SocailMediaWidgets(
                                imageUrl: 'assets/Facebook.svg',
                                socialMediaUrl:
                                    'https://www.facebook.com/share/1B8maXwpJy/',
                              ),
                              SocailMediaWidgets(
                                imageUrl: 'assets/Instagram.svg',
                                socialMediaUrl:
                                    'https://www.instagram.com/zerokoinapp?igsh=eDU2aHVwMGtqc2Vj',
                              ),
                              SocailMediaWidgets(
                                imageUrl: 'assets/Whatsapp.svg',
                                socialMediaUrl:
                                    'https://whatsapp.com/channel/0029VbAvkVc1iUxStQFiCG1d',
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 30),
                      DottedBorder(
                        options: RectDottedBorderOptions(
                          color: Color(0xFF0682A2),
                          dashPattern: [10, 5],
                          strokeWidth: 2,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            _pickFiles();
                          },
                          child: Container(
                            width: double.infinity,
                            height: screenHeight * 0.07,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset("assets/cloud.png"),
                                  Text(
                                    "Browse Screenshots to upload",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: screenHeight * 0.01,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      // Selected files display
                      if (_selectedFiles.isEmpty)
                        Container(
                          height: screenHeight * 0.04,
                          width: screenWidth,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color: Colors.grey,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Image.asset("assets/file.png"),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Text(
                                      "No screenshots selected",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                Opacity(
                                  opacity: 0.5,
                                  child: Image.asset("assets/delete.png"),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Column(
                          children: [
                            // Summary container
                            Container(
                              height: screenHeight * 0.04,
                              width: screenWidth,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                color: Colors.grey,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Image.asset("assets/file.png"),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        child: Text(
                                          "${_selectedFiles.length} screenshot${_selectedFiles.length > 1 ? 's' : ''} selected",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _clearFiles,
                                      child: Image.asset("assets/delete.png"),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 15),
                            // Upload Files Button (when files are selected)
                            Container(
                              height: screenHeight * 0.04,
                              width: screenWidth,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                color: Color(0xFF0682A2),
                                border: Border.all(color: Colors.white),
                              ),
                              child: ElevatedButton(
                                onPressed: _sendFiles,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                ),
                                child: Text(
                                  'Upload ${_selectedFiles.length} Screenshot${_selectedFiles.length > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            // Individual files list
                            Container(
                              constraints: BoxConstraints(
                                maxHeight: screenHeight * 0.2,
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _selectedFiles.length,
                                itemBuilder: (context, index) {
                                  final file = _selectedFiles[index];
                                  final fileName = file.path.split('/').last;
                                  return Container(
                                    margin: EdgeInsets.only(bottom: 5),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 15,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(25),
                                      color: Colors.grey.withValues(alpha: 0.7),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.insert_drive_file,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            fileName,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => _removeFile(index),
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      SizedBox(height: 30),
                      Text(
                        "Thank you for supporting us! Just follow our social media pages and upload screenshots -\nyour coins will be sent after verification.",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
