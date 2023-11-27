import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import package untuk Clipboard

// Kelas utama yang akan menampilkan hasil pemindaian teks
class ResultScreen extends StatefulWidget {
  final String text;

  // Constructor untuk menginisialisasi objek ResultScreen dengan teks hasil pemindaian
  const ResultScreen({Key? key, required this.text}) : super(key: key);

  @override
  _ResultScreenState createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController(text: widget.text);
  }

  // Metode untuk membangun tampilan widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Result'),
      ),
      body: Container(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: TextField(
                  controller: _textEditingController,
                  maxLines: null, // Allow multiple lines
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Salin teks ke clipboard saat tombol diklik
                Clipboard.setData(ClipboardData(text: _textEditingController.text));

                // Tampilkan snackbar untuk memberi tahu pengguna bahwa teks telah disalin
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Text copied to clipboard'),
                  ),
                );
              },
              child: const Text('Copy Text'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }
}
