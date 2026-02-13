part of 'search_cubit.dart';


abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object> get props => [];
}

class SearchInitial extends SearchState {
  final List<int> surahNumbers;
  final List<int> juzs;
  final List<BookmarkItem> bookmarks;
  final List<BookmarkFolder> folders;

  const SearchInitial(this.surahNumbers, this.juzs, this.bookmarks, this.folders);

  @override
  List<Object> get props => [surahNumbers, juzs, bookmarks, folders];
}

class SearchLoading extends SearchState {
  const SearchLoading();
}

class SearchLoaded extends SearchState {
  final List<int> surahNumbers;
  final List<int> juzs;
  final List<BookmarkItem> bookmarks;
  final List<BookmarkFolder> folders;

  const SearchLoaded(this.surahNumbers, this.juzs, this.bookmarks, this.folders);

  @override
  List<Object> get props => [surahNumbers, juzs, bookmarks, folders];
}
