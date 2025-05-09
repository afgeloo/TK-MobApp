import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';



class EmbedGoogleMapWidget extends StatelessWidget {
  final String address;
  const EmbedGoogleMapWidget({super.key, required this.address});

  @override
  Widget build(BuildContext context) {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return const SizedBox.shrink();

    final mapUrl = 'https://www.google.com/maps?q=${Uri.encodeComponent(trimmed)}&output=embed';

    // wrap the embed URL in a minimal HTML page
    final html = '''
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="initial-scale=1.0"/>
    <style>html, body { margin:0; padding:0; height:100%; }</style>
  </head>
  <body>
    <iframe
      width="100%" height="100%" frameborder="0" style="border:0"
      src="$mapUrl"
      allowfullscreen>
    </iframe>
  </body>
</html>
''';

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: 250,
        // key forces Flutter to rebuild when mapUrl changes
        key: ValueKey(mapUrl),
        child: InAppWebView(
          key: ValueKey(mapUrl),
          // load our HTML rather than a bare Google URL
          initialData: InAppWebViewInitialData(data: html),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            mediaPlaybackRequiresUserGesture: false,
            clearCache: true,
            transparentBackground: true,
          ),
        ),
      ),
    );
  }
}
