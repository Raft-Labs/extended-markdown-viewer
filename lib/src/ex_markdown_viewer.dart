import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart' as fhtml;
import 'package:markdown/markdown.dart' as md;

class ExtendedMarkDownViewer extends StatefulWidget {
  final String markdownText;
  final int? maxCollapsedLength;
  final bool isExpandable;
  final Widget? readMoreWidget, readLessWidget;
  final String readMoreText, readLessText;
  final Color? expandedTextColor,
      collapsedTextColor,
      readMoreTextColor,
      readLessTextColor;
  final CrossAxisAlignment contentAlignment;

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
    this.isExpandable = true,
    this.readMoreText = "Read more",
    this.readLessText = "Read less",
    this.expandedTextColor,
    this.collapsedTextColor,
    this.readMoreTextColor,
    this.readLessTextColor,
    this.onLinkTap,
    this.contentAlignment = CrossAxisAlignment.start,
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
    _processContent();
    super.initState();
  }

  // @override
  // void didUpdateWidget(ExtendedMarkDownViewer oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   if (oldWidget.markdownText != widget.markdownText) {
  //     _processContent();
  //   }
  // }

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

      if (_shouldShowReadMore || !widget.isExpandable) {
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
    processed = processed.replaceAll("&#x20;", "<br>");
    processed = processed.replaceAll("&#x20", "<br>");

    return processed;
  }

  String _createCollapsedVersion(String htmlContent) {
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

    int htmlCutoff = 0;
    int textLength = 0;
    bool inTag = false;
    final openTags = <String>[];
    String currentTag = '';

    for (int i = 0; i < html.length; i++) {
      if (textLength >= breakPoint) break;

      if (html[i] == '<') {
        inTag = true;
        currentTag = '';
      } else if (html[i] == '>') {
        inTag = false;
        if (!currentTag.startsWith('/')) {
          openTags.add(currentTag.split(' ')[0]); // Handle tags with attributes
        } else {
          final closingTag = currentTag.substring(1);
          if (openTags.isNotEmpty && openTags.last == closingTag) {
            openTags.removeLast();
          }
        }
        htmlCutoff = i + 1;
      } else if (inTag) {
        currentTag += html[i];
      } else {
        if (textLength + 1 > breakPoint) break;
        textLength++;
        htmlCutoff = i + 1;
      }
    }

    // Clean up any incomplete list items or other structures
    String truncatedHtml = html.substring(0, htmlCutoff);

    // If we're inside a list, find the last complete list item
    if (openTags.contains('ol') || openTags.contains('ul')) {
      final lastCompleteListItemMatch =
          RegExp(r'(<li[^>]*>.*?<\/li>)', dotAll: true)
              .allMatches(truncatedHtml)
              .lastOrNull;

      if (lastCompleteListItemMatch != null) {
        truncatedHtml =
            truncatedHtml.substring(0, lastCompleteListItemMatch.end);

        // Reset openTags based on the complete structure
        openTags.clear();
        final remainingStructure = truncatedHtml;
        bool inTag = false;
        String currentTag = '';

        for (int i = 0; i < remainingStructure.length; i++) {
          if (remainingStructure[i] == '<') {
            inTag = true;
            currentTag = '';
          } else if (remainingStructure[i] == '>') {
            inTag = false;
            if (!currentTag.startsWith('/')) {
              openTags.add(currentTag.split(' ')[0]);
            } else {
              final closingTag = currentTag.substring(1);
              if (openTags.isNotEmpty && openTags.last == closingTag) {
                openTags.removeLast();
              }
            }
          } else if (inTag) {
            currentTag += remainingStructure[i];
          }
        }
      }
    }

    // Close any remaining open tags in reverse order
    final closingTags = openTags.reversed.map((tag) => '</$tag>').join('');

    return '$truncatedHtml...$closingTags';
  }

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final htmlStyles = {
      "body": fhtml.Style(
        margin: fhtml.Margins.zero,
        padding: fhtml.HtmlPaddings.zero,
        color: _expanded ? widget.expandedTextColor : widget.collapsedTextColor,
        alignment: switch (widget.contentAlignment) {
          CrossAxisAlignment.center => Alignment.topCenter,
          CrossAxisAlignment.end => Alignment.topRight,
          _ => Alignment.topLeft,
        },
        textAlign: switch (widget.contentAlignment) {
          CrossAxisAlignment.center => TextAlign.center,
          CrossAxisAlignment.end => TextAlign.right,
          _ => TextAlign.left,
        },
      ),
      "p": fhtml.Style(
        margin: fhtml.Margins.zero,
        padding: fhtml.HtmlPaddings.zero,
      ),
      "span": fhtml.Style(
        margin: fhtml.Margins.zero,
        padding: fhtml.HtmlPaddings.zero,
      ),
      "ol": fhtml.Style(
        margin: fhtml.Margins.zero,
        padding: fhtml.HtmlPaddings.only(left: 16),
      ),
      "ul": fhtml.Style(
        margin: fhtml.Margins.zero,
        padding: fhtml.HtmlPaddings.only(left: 16),
      ),
      "li": fhtml.Style(
        margin: fhtml.Margins.zero,
        padding: fhtml.HtmlPaddings.zero,
      ),
    };

    if (!_shouldShowReadMore || !widget.isExpandable) {
      return fhtml.Html(
        shrinkWrap: true,
        data: widget.isExpandable ? _fullHtmlContent : _collapsedHtmlContent,
        style: htmlStyles,
        onLinkTap: (url, args, element) {
          if (widget.onLinkTap != null) {
            widget.onLinkTap!(url, args);
          }
        },
      );
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          layoutBuilder: (widget, list) => Stack(
            alignment: Alignment.topLeft,
            children: [widget!, ...list],
          ),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: GestureDetector(
            key: ValueKey<bool>(_expanded),
            onTap: _toggleExpanded,
            child: Column(
              crossAxisAlignment: widget.contentAlignment,
              mainAxisSize: MainAxisSize.min,
              children: [
                fhtml.Html(
                  shrinkWrap: true,
                  data: _expanded ? _fullHtmlContent : _collapsedHtmlContent,
                  style: htmlStyles,
                  onLinkTap: (url, args, element) {
                    if (widget.onLinkTap != null) {
                      widget.onLinkTap!(url, args);
                    }
                  },
                ),
                Align(
                  alignment: switch (widget.contentAlignment) {
                    CrossAxisAlignment.center => Alignment.center,
                    CrossAxisAlignment.end => Alignment.centerRight,
                    _ => Alignment.centerLeft,
                  },
                  child: _expanded
                      ? (widget.readLessWidget ??
                          widget._buildReadLessIcon(context))
                      : (widget.readMoreWidget ??
                          widget._buildReadMoreIcon(context)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
