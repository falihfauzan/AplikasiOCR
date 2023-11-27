import 'dart:io';
//import Library
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:var_project/result_scan.dart';
import 'package:image_picker/image_picker.dart';


void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Text Recognition',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  bool _isPermissionGranted = false;

  late final Future<void> _future;

  CameraController? _cameraController;

  // Objek untuk mengenali teks menggunakan Google ML Kit
  final _textRecognizer = TextRecognizer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Meminta izin kamera saat inisialisasi
    _future = _requestCameraPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCamera();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      _startCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Menggunakan FutureBuilder untuk menunggu hasil pemintaan izin kamera selesai
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        return Stack(
          children: [
            // // Menampilkan feed kamera di belakang semua elemen
            if (_isPermissionGranted)
              FutureBuilder<List<CameraDescription>>(
                future: availableCameras(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    _initCameraController(snapshot.data!);

                    return Center(child: CameraPreview(_cameraController!));
                  } else {
                    return const LinearProgressIndicator();
                  }
                },
              ),
            Scaffold(
              appBar: AppBar(
                title: const Text("PhoText Scanner"),
              ),
              backgroundColor: _isPermissionGranted ? Colors.transparent : null,
              body: _isPermissionGranted
                  ? Column(
                children: [
                  Expanded(
                    child: Container(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _scanImage,
                        child: const Text('Scan Text'),
                      ),
                      ElevatedButton(
                        onPressed: _showImagePickerDialog,
                        child: const Text('Select Image'),
                      ),
                    ],
                  ),
                ],
              )
                  : Center(
                child: Container(
                  padding: const EdgeInsets.only(
                    left: 24.0,
                    right: 24.0,
                  ),
                  child: const Text(
                    'Camera permission denied',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          ],
        );
      },
    );
  }

  // Fungsi untuk meminta izin kamera
  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    _isPermissionGranted = status == PermissionStatus.granted;
  }

  // Fungsi untuk memulai kamera
  void _startCamera() {
    if (_cameraController != null) {
      _cameraSelected(_cameraController!.description);
    }
  }

  // Fungsi untuk menghentikan kamera
  void _stopCamera() {
    if (_cameraController != null) {
      _cameraController?.dispose();
    }
  }

  // Fungsi untuk menginisialisasi controller kamera
  void _initCameraController(List<CameraDescription> cameras) {
    if (_cameraController != null) {
      return;
    }

    // Memilih kamera belakang pertama
    CameraDescription? camera;
    for (var i = 0; 1 < cameras.length; i++) {
      final CameraDescription current = cameras[i];
      if (current.lensDirection == CameraLensDirection.back) {
        camera = current;
        break;
      }
    }

    if (camera != null) {
      _cameraSelected(camera);
    }
  }

  Future<void> _cameraSelected(CameraDescription camera) async {
    _cameraController = CameraController(
      camera,
      ResolutionPreset.max,
      enableAudio: false,
    );

    await _cameraController?.initialize();

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // Fungsi untuk memindai gambar dari kamera
  Future<void> _scanImage() async {
    if (_cameraController == null) return;

    final navigator = Navigator.of(context);

    try {
      // Mengambil gambar dari kamera
      final pictureFile = await _cameraController!.takePicture();

      // Mengonversi file gambar ke tipe File
      final file = File(pictureFile.path);

      // Membuat objek input image dari file gambar
      final inputImage = InputImage.fromFile(file);

      // Memproses gambar untuk pengenalan teks
      final recognizedText = await _textRecognizer.processImage(inputImage);


      // Menampilkan hasil pemindaian di layar hasil
      await navigator.push(
        MaterialPageRoute(
          builder: (context) => ResultScreen(text: recognizedText.text),
        ),
      );
    } catch (e) { //exception
      // Menampilkan pesan kesalahan jika terjadi kesalahan saat pemindaian teks
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred when scanning text'),
        ),
      );
    }
  }

  // Fungsi untuk menampilkan dialog pemilihan sumber gambar
  Future<void> _showImagePickerDialog() async {
    final imageSource = await showDialog<ImageSource>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Select Image Source'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, ImageSource.gallery);
              },
              child: const Text('Gallery'),
            ),
          ],
        );
      },
    );

    if (imageSource != null) {
      if (imageSource == ImageSource.camera) {
        _scanImage();
      } else if (imageSource == ImageSource.gallery) {
        _pickImageFromGallery();
      }
    }
  }

  // Fungsi untuk mengambil gambar dari galeri
  Future<void> _pickImageFromGallery() async {
    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final inputImage = InputImage.fromFile(File(pickedFile.path));
      final recognizedText = await _textRecognizer.processImage(inputImage);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(text: recognizedText.text),
        ),
      );
    }
  }
}