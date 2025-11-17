import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../utils/app_theme.dart';

class TrailerScreen extends StatefulWidget {
  final String? trailerUrl;
  final String movieTitle;

  const TrailerScreen({
    super.key,
    required this.trailerUrl,
    required this.movieTitle,
  });

  @override
  State<TrailerScreen> createState() => _TrailerScreenState();
}

class _TrailerScreenState extends State<TrailerScreen> {
  late WebViewController _webViewController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            print('❌ WebView Error: ${error.description}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi tải video: ${error.description}'),
                backgroundColor: AppTheme.error,
              ),
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(_getEmbedUrl(widget.trailerUrl)));
  }

  /// Convert YouTube URL to embedded player URL
  String _getEmbedUrl(String? url) {
    if (url == null || url.isEmpty) {
      return 'about:blank';
    }

    String videoId = '';

    // Extract video ID from various YouTube URL formats
    if (url.contains('youtu.be/')) {
      videoId = url.split('youtu.be/').last.split('?').first;
    } else if (url.contains('youtube.com/watch?v=')) {
      videoId = url.split('v=').last.split('&').first;
    } else if (url.contains('youtube.com/embed/')) {
      videoId = url.split('embed/').last.split('?').first;
    } else {
      // Assume it's already a video ID
      videoId = url;
    }

    print('🎬 YouTube Video ID: $videoId');
    return 'https://www.youtube.com/embed/$videoId?autoplay=1&modestbranding=1';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.movieTitle), elevation: 0),
      body: widget.trailerUrl == null || widget.trailerUrl!.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Không có trailer cho phim này',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                WebViewWidget(controller: _webViewController),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
    );
  }
}
