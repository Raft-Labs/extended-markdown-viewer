# Extended Markdown Viewer

A Flutter package that provides a customizable Markdown viewer with "Read More/Less" functionality, perfect for displaying collapsible Markdown content in your Flutter applications.

## Features

- 📝 Renders Markdown content with HTML support
- ↕️ Expandable/Collapsible text with smooth animation
- 🎨 Customizable appearance including text colors and read more/less widgets
- 🔗 Customizable link tap handling
- 📏 Configurable collapsed text length
- 🎯 Smart text truncation that preserves Markdown structure
- ⚡ Smooth transitions with fade animations
- 📐 Configurable content alignment (start, center, end)

## Getting started

Add this package to your Flutter project by including it in your `pubspec.yaml`:

```yaml
dependencies:
  extended_markdown_viewer: ^1.0.0
```

## Usage

Here's a simple example of how to use ExtendedMarkDownViewer:

```dart
ExtendedMarkDownViewer(
  markdownText: '''
# Hello World
This is a markdown text that can be collapsed and expanded.
It supports **bold**, *italic*, and [links](https://example.com).
  ''',
  maxCollapsedLength: 100,
  readMoreText: 'Show more',
  readLessText: 'Show less',
)
```

### Customization

You can customize various aspects of the viewer:

```dart
ExtendedMarkDownViewer(
  markdownText: yourMarkdownText,
  maxCollapsedLength: 150,
  readMoreText: 'Continue reading',
  readLessText: 'Close',
  expandedTextColor: Colors.black,
  collapsedTextColor: Colors.grey,
  readMoreTextColor: Colors.blue,
  readLessTextColor: Colors.blue,
  readMoreWidget: CustomWidget(), // Custom widget for read more button
  readLessWidget: CustomWidget(), // Custom widget for read less button
  contentAlignment: CrossAxisAlignment.center, // Align content center
  isExpandable: true, // Toggle expandability
  onLinkTap: (url, params) {
    // Handle link taps
  },
)
```

## Additional information

### Properties

- `markdownText`: The Markdown content to display
- `maxCollapsedLength`: Maximum length of text when collapsed (default: 80)
- `readMoreText`: Text for expand button (default: "Read more")
- `readLessText`: Text for collapse button (default: "Read less")
- `expandedTextColor`: Color of text when expanded
- `collapsedTextColor`: Color of text when collapsed
- `readMoreTextColor`: Color of read more text
- `readLessTextColor`: Color of read less text
- `contentAlignment`: Alignment of content (start, center, end)
- `isExpandable`: Whether the content can be expanded/collapsed
- `onLinkTap`: Callback for handling link taps
- `readMoreWidget`: Custom widget to replace default read more button
- `readLessWidget`: Custom widget to replace default read less button

### Features in Detail

#### Smart Text Truncation
The viewer intelligently truncates text while preserving Markdown structure, ensuring that the formatting is preserved.

#### Animations
- Smooth size transitions when expanding/collapsing
- Fade animations for content changes
- Configurable animation durations

#### Layout
- Zero default margins and padding for clean integration
- Customizable list indentation
- Responsive width handling
- Support for different text alignments

### Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### License

This project is licensed under the MIT License - see the LICENSE file for details.
Developed by 
[Rohan Kumar Panigrahi](https://www.linkedin.com/in/rohan-kumar-panigrahi-187a12193/) at [RaftLabs](https://www.raftlabs.com/).
