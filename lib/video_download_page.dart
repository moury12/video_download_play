import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:video_dowload_play/database.dart';
import 'package:video_dowload_play/video_player.dart';

import 'notification_service.dart';

class VideoDownloadScreen extends StatefulWidget {
  const VideoDownloadScreen({super.key});

  @override
  State<VideoDownloadScreen> createState() => _VideoDownloadScreenState();
}

class _VideoDownloadScreenState extends State<VideoDownloadScreen> {
  double _percentage = 0;
  String dowloadMessage = 'Waiting...';
  bool isDownloading = false;
  bool isWantCancel = false;
  CancelToken cancelToken = CancelToken();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  var _progressList = <double>[];
  int currentIndex = -1;

  double currentProgress(int index) {
    if (index >= 0 && index < _progressList.length) {
      return _progressList[index];
    } else {
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FloatingActionButton(
              onPressed: () {
                setState(() {
                  isDownloading = !isDownloading;
                });
                currentIndex++;
                downloadAndSaveFile(
                    // 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
                    'https://rr5---sn-npoe7nds.googlevideo.com/videoplayback?expire=1696855664&ei=EKIjZba2K8_V7gS1sYvADA&ip=138.199.59.216&id=o-AEdhQV0FRMnnj62CRbWLy1xZgswcMds27fOguY-ZCIp6&itag=22&source=youtube&requiressl=yes&spc=UWF9f9Q8Uwyl7bcRm5uMEhTjrI_o01Q&vprv=1&svpuc=1&mime=video%2Fmp4&cnr=14&ratebypass=yes&dur=528.880&lmt=1683822433138265&fexp=24007246,24350018&beids=24350018&c=ANDROID&txp=5318224&sparams=expire%2Cei%2Cip%2Cid%2Citag%2Csource%2Crequiressl%2Cspc%2Cvprv%2Csvpuc%2Cmime%2Ccnr%2Cratebypass%2Cdur%2Clmt&sig=AGM4YrMwRQIhALOVgSKmFy-zKCRSNXtTGnIiY4QgsWGVcHP8vrKgdzSgAiAlrj7CSsvvh6bjR3DRbFsE6h6mF7suIBsD-mCfOolbVg%3D%3D&title=MS%20Excel%2015%20Keyboard%20Shortcut%20For%20Office%20Work%20!%20MS%20Excel%20Top%20Keyboard%20Shortcut&rm=sn-5uh5o-f5fs7e,sn-f5fez7l&req_id=59dc60eea549a3ee&cmsv=e&redirect_counter=2&cms_redirect=yes&ipbypass=yes&mh=jJ&mip=103.81.199.65&mm=29&mn=sn-npoe7nds&ms=rdu&mt=1696833681&mv=m&mvi=5&pl=24&lsparams=ipbypass,mh,mip,mm,mn,ms,mv,mvi,pl&lsig=AK1ks_kwRQIhAI94Myx938WpvHumgO-HbA9UxS-8BBKpaD6wL1DxG0hXAiAqBCg2XT5J9VBEIABNlDWNrll7ACT5Pmo_hX9dmrEYZQ%3D%3D',
                    'video.mp4_${DateTime.timestamp().millisecondsSinceEpoch}');
              },
              child: Icon(Icons.download),
            ),
            SizedBox(
              height: 20,
            ),
            // ElevatedButton(
            //     onPressed: () =>
            //         OfflineFileManager().alterTable('files', 'nowPlaying'),
            //     child: Text('Alter')),
            SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(dowloadMessage),
                Text((_percentage.floor()).toString()),
                isDownloading
                    ? isWantCancel
                        ? InkWell(
                            child: Icon(Icons.play_arrow),
                            onTap: () {
                              setState(() {
                                isWantCancel = false;
                              });
                              cancelDownload();
                            })
                        : InkWell(
                            child: Icon(Icons.pause),
                            onTap: () {
                              cancelToken.cancel();
                              setState(() {
                                isWantCancel = true;
                              });
                            },
                          )
                    : SizedBox.shrink()
              ],
            ),
            SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: LinearProgressIndicator(
                value: _percentage,
                backgroundColor:
                    isWantCancel ? Colors.red.shade100 : Colors.green.shade100,
                color: isWantCancel ? Colors.red : Colors.green,
              ),
            ),
            SizedBox(
              height: 20,
            ),
            FloatingActionButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) {
                    return VideoListScreen();
                  },
                ));
              },
              child: Icon(Icons.play_arrow),
            )
          ],
        ),
      ),
    );
  }

  Future<void> downloadAndSaveFile(String fileUrl, String fileName) async {
    final dio = Dio();

    try {
      final response = await dio.get(
        fileUrl,
        cancelToken: cancelToken,
        onReceiveProgress: (count, total) async {
          var percentage = count / total * 100;

          if (currentIndex < _progressList.length) {
            _progressList[currentIndex] = percentage.toDouble();
          } else {
            _progressList.add(percentage.toDouble());
          }

          // Update notification progress
          await NotificationService().updateDownloadProgress(
            currentIndex,
            percentage.floor(),
          );

          if (percentage < 100) {
            _percentage = percentage / 100;

            setState(() {
              dowloadMessage = "Downloading..${percentage.floor()}";
            });
          } else if (percentage == 100) {
            setState(() {
              dowloadMessage = "Completed..${percentage.floor()}";
              isDownloading = false;
            });
          }
        },
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data;

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(bytes);
      final result = await OfflineFileManager().insertFile(file);

      if (result != -1) {
        print('File saved successfully');
      } else {
        print('File saved failed');

        // File insertion failed
      }
      print('File saved at: $filePath');
    } catch (e) {
      print('Error downloading and saving file: $e');
    }
  }

  void cancelDownload() {
    if (cancelToken.isCancelled) {
      return; // Already canceled
    }
    cancelToken.cancel("Canceled by user");
  }
}
