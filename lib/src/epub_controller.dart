part of 'ui/epub_view.dart';

class EpubController {
  _EpubViewState? _epubViewState;
  List<EpubViewChapter>? _cacheTableOfContents;
  Map<String, Style>? _style;

  EpubBook? document;

  EpubChapterViewValue? get currentValue => _epubViewState?._currentValue;

  final isBookLoaded = ValueNotifier<bool>(false);
  final ValueNotifier<EpubViewLoadingState> loadingState =
      ValueNotifier(EpubViewLoadingState.loading);

  final currentValueListenable = ValueNotifier<EpubChapterViewValue?>(null);

  final tableOfContentsListenable = ValueNotifier<List<EpubViewChapter>>([]);

  void jumpTo({required int index, double alignment = 0}) =>
      _epubViewState?._itemScrollController?.jumpTo(
        index: index,
        alignment: alignment,
      );

  Future<void>? scrollTo({
    required int index,
    Duration duration = const Duration(milliseconds: 250),
    double alignment = 0,
    Curve curve = Curves.linear,
  }) =>
      _epubViewState?._itemScrollController?.scrollTo(
        index: index,
        duration: duration,
        alignment: alignment,
        curve: curve,
      );

  void gotoEpubCfi(
    String epubCfi, {
    double alignment = 0,
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.linear,
  }) {
    _epubViewState?._gotoEpubCfi(
      epubCfi,
      alignment: alignment,
      duration: duration,
      curve: curve,
    );
  }

  String? generateEpubCfi() => _epubViewState?._epubCfiReader?.generateCfi(
        book: document,
        chapter: _epubViewState?._currentValue?.chapter,
        paragraphIndex: _epubViewState?._getAbsParagraphIndexBy(
          positionIndex: _epubViewState?._currentValue?.position.index ?? 0,
          trailingEdge:
              _epubViewState?._currentValue?.position.itemTrailingEdge,
          leadingEdge: _epubViewState?._currentValue?.position.itemLeadingEdge,
        ),
      );

  List<EpubViewChapter> tableOfContents() {
    if (_cacheTableOfContents != null) {
      return _cacheTableOfContents ?? [];
    }

    if (document == null) {
      return [];
    }

    int index = -1;

    return _cacheTableOfContents =
        document!.Chapters!.fold<List<EpubViewChapter>>(
      [],
      (acc, next) {
        index += 1;
        acc.add(EpubViewChapter(next.Title, _getChapterStartIndex(index)));
        for (final subChapter in next.SubChapters!) {
          index += 1;
          acc.add(EpubViewSubChapter(
              subChapter.Title, _getChapterStartIndex(index)));
        }
        return acc;
      },
    );
  }

  void setDocument(EpubBook document) {
    this.document = document;
  }

  void dispose() {
    _epubViewState = null;
    isBookLoaded.dispose();
    currentValueListenable.dispose();
    tableOfContentsListenable.dispose();
  }

  int _getChapterStartIndex(int index) =>
      index < _epubViewState!._chapterIndexes.length
          ? _epubViewState!._chapterIndexes[index]
          : 0;

  void _attach(_EpubViewState epubReaderViewState) {
    _epubViewState = epubReaderViewState;
    _reloadView();
  }

  void _detach() {
    _epubViewState = null;
  }

  void _reloadView() async {
    isBookLoaded.value = false;
    try {
      _cacheTableOfContents = null;
      loadingState.value = EpubViewLoadingState.loading;
      var css = document!.Content?.Css;
      _style = Style.fromCss(
          css?['Styles/stylesheet.css']?.Content ??
              css?['styles/stylesheet.css']?.Content ??
              css?.entries.firstOrNull?.value.Content ??
              '',
          (_, __) => null);

      await _epubViewState?._init();
      tableOfContentsListenable.value = tableOfContents();
      loadingState.value = EpubViewLoadingState.success;
    } catch (error) {
      _epubViewState?._loadingError = error is Exception
          ? error
          : Exception('An unexpected error occurred');
      loadingState.value = EpubViewLoadingState.error;
    }
  }
}
