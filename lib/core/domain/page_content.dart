class PageContent {
  const PageContent({
    required this.pageNumber,
    required this.text,
    this.location = '',
  });

  final int pageNumber;
  final String text;
  final String location;
}
