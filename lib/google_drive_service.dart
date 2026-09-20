import 'dart:convert';
import 'dart:typed_data';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart';

class GoogleDriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  Future<drive.DriveApi> _getDriveApi() async {
    final account = await _googleSignIn.signIn();

    final authHeaders = await account!.authHeaders;

    final authenticateClient = GoogleAuthClient(authHeaders);

    return drive.DriveApi(authenticateClient);
  }

  Future<void> updateJsonFile() async {
    final driveApi = await _getDriveApi();

    const fileId = '14yDD4C3Q1PRDNT0XpsjtmroNBgUhLdW-';

    // READ FILE
    final response = await driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final data = await utf8.decoder.bind(response.stream).join();

    final jsonMap = jsonDecode(data);

    // MODIFY JSON
    jsonMap['newData'] = 'Hello From Flutter';

    // CONVERT BACK TO JSON
    final updatedJson = jsonEncode(jsonMap);

    // UPLOAD UPDATED FILE
    final media = drive.Media(
      Stream.value(
        Uint8List.fromList(
          utf8.encode(updatedJson),
        ),
      ),
      updatedJson.length,
    );

    await driveApi.files.update(
      drive.File(),
      fileId,
      uploadMedia: media,
    );

    print("JSON Updated Successfully");
  }
}

class GoogleAuthClient extends BaseClient {
  final Map<String, String> _headers;

  GoogleAuthClient(this._headers);

  @override
  Future<StreamedResponse> send(BaseRequest request) {
    request.headers.addAll(_headers);

    return request.send();
  }
}