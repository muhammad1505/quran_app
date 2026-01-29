part of 'bookmark_cubit.dart';

abstract class BookmarkState extends Equatable {
  const BookmarkState();

  @override
  List<Object?> get props => [];
}

class BookmarkLoading extends BookmarkState {}

class BookmarkLoaded extends BookmarkState {
  final List<BookmarkItem> allBookmarks;
  final List<BookmarkFolder> allFolders;
  final bool showNotesOnly;
  final String? selectedFolderId;

  const BookmarkLoaded({
    required this.allBookmarks,
    required this.allFolders,
    this.showNotesOnly = false,
    this.selectedFolderId,
  });

  List<BookmarkItem> get filteredBookmarks {
    List<BookmarkItem> filtered = showNotesOnly
        ? allBookmarks.where((item) => (item.note ?? '').isNotEmpty).toList()
        : allBookmarks;

    if (selectedFolderId != null) {
      filtered = filtered
          .where((item) => item.folderId == selectedFolderId)
          .toList();
    }
    return filtered;
  }

  BookmarkLoaded copyWith({
    List<BookmarkItem>? allBookmarks,
    List<BookmarkFolder>? allFolders,
    bool? showNotesOnly,
    String? selectedFolderId,
  }) {
    return BookmarkLoaded(
      allBookmarks: allBookmarks ?? this.allBookmarks,
      allFolders: allFolders ?? this.allFolders,
      showNotesOnly: showNotesOnly ?? this.showNotesOnly,
      selectedFolderId: selectedFolderId,
    );
  }

  @override
  List<Object?> get props => [
        allBookmarks,
        allFolders,
        showNotesOnly,
        selectedFolderId,
      ];
}
