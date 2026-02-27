import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ScanScreen extends StatefulWidget {
  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {

  Interpreter? interpreter;
  File? imageFile;
  String result = "No scan yet";

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future loadModel() async {

    interpreter = await Interpreter.fromAsset(
      'model.tflite',
    );

    print("MODEL LOADED");
  }

  Future pickImage() async {

    final picker = ImagePicker();

    final pickedFile =
        await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {

      setState(() {
        imageFile = File(pickedFile.path);
        result = "Scanned (Model Ready)";
      });

    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text("Scan Waste"),
      ),

      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          if (imageFile != null)
            Image.file(imageFile!, height: 250),

          SizedBox(height: 20),

          Text(
            result,
            style: TextStyle(fontSize: 20),
          ),

          SizedBox(height: 20),

          ElevatedButton(
            onPressed: pickImage,
            child: Text("Open Camera"),
          ),

        ],
      ),

    );
  }
}
