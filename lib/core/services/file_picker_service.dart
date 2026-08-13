import 'package:file_picker/file_picker.dart';

class FilePickerService {
  FilePickerService._();

  static final FilePickerService _instance =
      FilePickerService._();

  factory FilePickerService() => _instance;

  Future<String?> pickFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result == null) {
      return null;
    }

    return result.files.single.path;
  }
}