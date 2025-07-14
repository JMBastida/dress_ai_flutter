import 'dart:typed_data';

import 'package:local_rembg/local_rembg.dart';

Future<LocalRembgResultModel> removeBackground(String path, Uint8List image) async {
  LocalRembgResultModel localRembgResultModel = await LocalRembg.removeBackground(
    imagePath: path,// Your Image Path ,
    imageUint8List: image,// Your image Uint8List ,
    cropTheImage: false,
  );
  return localRembgResultModel;
}
