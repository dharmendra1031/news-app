import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:news/commons/widgets/custom_appbar.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/utils/ui_utils.dart';

class ENewsPdfViewerScreen extends StatefulWidget {
  final String title;
  final String pdfUrl;

  const ENewsPdfViewerScreen({
    super.key,
    required this.title,
    required this.pdfUrl,
  });

  static Route route(RouteSettings routeSettings) {
    final args = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => ENewsPdfViewerScreen(
        title: args['title'],
        pdfUrl: args['pdfUrl'],
      ),
    );
  }

  @override
  State<ENewsPdfViewerScreen> createState() => _ENewsPdfViewerScreenState();
}

class _ENewsPdfViewerScreenState extends State<ENewsPdfViewerScreen> {
  String? _localFilePath;
  bool _isLoading = true;
  String? _errorMessage;
  int _totalPages = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _downloadAndLoadPdf();
  }

  Future<void> _downloadAndLoadPdf() async {
    try {
      final response = await http.get(Uri.parse(widget.pdfUrl));
      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final fileName = 'enews_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        if (mounted) {
          setState(() {
            _localFilePath = file.path;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load PDF (${response.statusCode})';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        height: 45,
        isBackBtn: true,
        label: widget.title,
        isConvertText: false,
        actionWidget: [
          if (_totalPages > 0)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 16),
              child: Center(
                child: Text(
                  '${_currentPage + 1} / $_totalPages',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: UiUtils.getColorScheme(context).primaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Theme.of(context).primaryColor),
            const SizedBox(height: 16),
            Text(
              UiUtils.getTranslatedLabel(context, 'loadingPdfLbl'),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                // Dark only: the default colorScheme.primary is the fromSeed
                // tonal shade, not the Figma Button/Primary/BG red.
                style: Theme.of(context).brightness == Brightness.dark
                    ? ElevatedButton.styleFrom(backgroundColor: primaryColor)
                    : null,
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _downloadAndLoadPdf();
                },
                child: Text(UiUtils.getTranslatedLabel(context, 'RetryLbl')),
              ),
            ],
          ),
        ),
      );
    }

    return PDFView(
      filePath: _localFilePath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      pageSnap: true,
      defaultPage: _currentPage,
      fitPolicy: FitPolicy.BOTH,
      preventLinkNavigation: false,
      onRender: (pages) {
        if (mounted) {
          setState(() {
            _totalPages = pages ?? 0;
          });
        }
      },
      onViewCreated: (PDFViewController pdfViewController) {},
      onPageChanged: (int? page, int? total) {
        if (mounted && page != null) {
          setState(() {
            _currentPage = page;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _errorMessage = error.toString();
          });
        }
      },
      onPageError: (page, error) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Error on page $page: $error';
          });
        }
      },
    );
  }
}
