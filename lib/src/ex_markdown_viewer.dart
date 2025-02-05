import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart' as fhtml;
import 'package:markdown/markdown.dart' as md;

class ExtendedMarkDownViewer extends StatefulWidget {
  final String markdownText;
  final int? maxCollapsedLength;
  final Widget? readMoreWidget, readLessWidget;
  final String readMoreText, readLessText;
  final Color? expandedTextColor,
      collapsedTextColor,
      readMoreTextColor,
      readLessTextColor;

  final Function(
    String? url,
    Map<String, String> args,
  )? onLinkTap;

  Widget _buildReadMoreIcon(BuildContext context) {
    return Text(readMoreText,
        style: TextStyle(fontSize: 14, color: readMoreTextColor));
  }

  Widget _buildReadLessIcon(BuildContext context) {
    return Text(readLessText,
        style: TextStyle(fontSize: 14, color: readLessTextColor));
  }

  const ExtendedMarkDownViewer({
    required this.markdownText,
    this.maxCollapsedLength = 80,
    this.readMoreWidget,
    this.readLessWidget,
    this.readMoreText = "Read more",
    this.readLessText = "Read less",
    this.expandedTextColor,
    this.collapsedTextColor,
    this.readMoreTextColor,
    this.readLessTextColor,
    this.onLinkTap,
    super.key,
  });

  @override
  State<ExtendedMarkDownViewer> createState() => _ExtendedMarkDownViewerState();
}

class _ExtendedMarkDownViewerState extends State<ExtendedMarkDownViewer> {
  bool _expanded = false;
  late String _fullHtmlContent;
  late String _collapsedHtmlContent;
  late bool _shouldShowReadMore = false;

  @override
  void initState() {
    super.initState();
    _processContent();
  }

  @override
  void didUpdateWidget(ExtendedMarkDownViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.markdownText != widget.markdownText) {
      _processContent();
    }
  }

  void _processContent() {
    // Convert markdown to HTML with our preprocessing
    String baseHtml = md.markdownToHtml(
      _preProcessMarkdown(widget.markdownText),
      extensionSet: md.ExtensionSet.gitHubWeb,
    );

    // Add read less button to full content
    _fullHtmlContent = baseHtml;

    // Create collapsed version if needed
    if (widget.maxCollapsedLength != null) {
      final bs = BeautifulSoup(baseHtml);
      final plainText = bs.getText();

      _shouldShowReadMore = plainText.length > widget.maxCollapsedLength!;

      if (_shouldShowReadMore) {
        _collapsedHtmlContent = _createCollapsedVersion(baseHtml);
      } else {
        _collapsedHtmlContent = baseHtml;
      }
    } else {
      _collapsedHtmlContent = baseHtml;
      _shouldShowReadMore = false;
    }
  }

  String _preProcessMarkdown(String content) {
    String processed = content;
    processed = processed.replaceAll("&#x20", "<br>");
    return processed;
  }

  String _createCollapsedVersion(String htmlContent) {
    // First convert the markdown to HTML if it hasn't been converted yet
    final html = htmlContent.startsWith('<')
        ? htmlContent
        : md.markdownToHtml(
            widget.markdownText,
            extensionSet: md.ExtensionSet.gitHubWeb,
          );

    final bs = BeautifulSoup(html);
    final plainText = bs.getText();

    if (plainText.length <= widget.maxCollapsedLength!) {
      return html;
    }

    // Find a good breaking point near maxCollapsedLength
    int breakPoint = widget.maxCollapsedLength!;
    while (breakPoint > 0 && plainText[breakPoint] != ' ') {
      breakPoint--;
    }

    // // Get the truncated text
    // final truncatedText = plainText.substring(0, breakPoint);

    // Find the position in the HTML where we should truncate
    int htmlCutoff = 0;
    int textLength = 0;

    // Helper function to find the cutoff point
    void findCutoff(String text) {
      if (textLength >= breakPoint) return;

      if (textLength + text.length > breakPoint) {
        // This text contains our breaking point
        htmlCutoff += (breakPoint - textLength);
        textLength = breakPoint;
      } else {
        htmlCutoff += text.length;
        textLength += text.length;
      }
    }

    // Process the HTML character by character to find the cutoff point
    bool inTag = false;
    int tagStart = -1;

    for (int i = 0; i < html.length; i++) {
      if (textLength >= breakPoint) break;

      if (html[i] == '<') {
        inTag = true;
        tagStart = i;
      } else if (html[i] == '>') {
        inTag = false;
        htmlCutoff = i + 1;
      } else if (!inTag) {
        findCutoff(html[i]);
      }
    }

    // Get all opening tags up to our cutoff point
    final openTags = <String>[];
    final tagRegExp = RegExp(r'<(\w+)[^>]*>');
    final matches = tagRegExp.allMatches(html.substring(0, htmlCutoff));

    for (final match in matches) {
      final tag = match.group(1);
      if (tag != null) {
        openTags.add(tag);
      }
    }

    // Close any open tags in reverse order
    final closingTags = openTags.reversed.map((tag) => '</$tag>').join('');

    // Return the truncated HTML with read more link
    final lastTag = openTags.lastOrNull;
    if (lastTag == 'p' || lastTag == 'div') {
      // If the last tag is a paragraph or div, put the read more link inside it
      return '${html.substring(0, htmlCutoff)}...$closingTags';
    } else {
      // Otherwise wrap in a span to control spacing
      return '${html.substring(0, htmlCutoff)}...$closingTags';
    }
  }

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShowReadMore) {
      // If content is shorter than maxCollapsedLength, just show the content without buttons
      return fhtml.Html(
        data: _fullHtmlContent,
        style: {
          "body": fhtml.Style(
              margin: fhtml.Margins.zero,
              padding: fhtml.HtmlPaddings.zero,
              color: widget.expandedTextColor),
          "p": fhtml.Style(
            margin: fhtml.Margins.zero,
            padding: fhtml.HtmlPaddings.zero,
          ),
          "span": fhtml.Style(
            margin: fhtml.Margins.zero,
            padding: fhtml.HtmlPaddings.zero,
          ),
        },
        onLinkTap: (url, args, element) {
          if (widget.onLinkTap != null) {
            widget.onLinkTap!(url, args);
          }
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedCrossFade(
          firstChild: GestureDetector(
            onTap: _toggleExpanded,
            child: Column(
              children: [
                fhtml.Html(
                  data: _collapsedHtmlContent,
                  style: {
                    "body": fhtml.Style(
                        margin: fhtml.Margins.zero,
                        padding: fhtml.HtmlPaddings.zero,
                        color: widget.collapsedTextColor),
                    "p": fhtml.Style(
                      margin: fhtml.Margins.zero,
                      padding: fhtml.HtmlPaddings.zero,
                    ),
                    "span": fhtml.Style(
                      margin: fhtml.Margins.zero,
                      padding: fhtml.HtmlPaddings.zero,
                    ),
                  },
                  onLinkTap: (
                    url,
                    args,
                    element,
                  ) {
                    if (widget.onLinkTap != null) {
                      widget.onLinkTap!(url, args);
                    }
                  },
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: widget.readMoreWidget ??
                      widget._buildReadMoreIcon(context),
                ),
              ],
            ),
          ),
          secondChild: GestureDetector(
            onTap: _toggleExpanded,
            child: Column(
              children: [
                fhtml.Html(
                  data: _fullHtmlContent,
                  style: {
                    "body": fhtml.Style(
                        margin: fhtml.Margins.zero,
                        padding: fhtml.HtmlPaddings.zero,
                        color: widget.expandedTextColor),
                    "p": fhtml.Style(
                      margin: fhtml.Margins.zero,
                      padding: fhtml.HtmlPaddings.zero,
                    ),
                    "span": fhtml.Style(
                      margin: fhtml.Margins.zero,
                      padding: fhtml.HtmlPaddings.zero,
                    ),
                  },
                  onLinkTap: (url, args, element) {
                    if (widget.onLinkTap != null) {
                      widget.onLinkTap!(url, args);
                    }
                  },
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: widget.readLessWidget ??
                      widget._buildReadLessIcon(context),
                ),
              ],
            ),
          ),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
          sizeCurve: Curves.easeOut,
        ),
      ],
    );
  }
}
