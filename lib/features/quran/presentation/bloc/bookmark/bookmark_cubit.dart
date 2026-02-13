import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:quran_app/core/services/bookmark_service.dart';

part 'bookmark_state.dart';

@injectable
class BookmarkCubit extends Cubit<BookmarkState> {
  final BookmarkService _bookmarkService;

  BookmarkCubit(this._bookmarkService) : super(BookmarkLoading());

  Future<void> loadBookmarks() async {
    try {
      emit(BookmarkLoading());
      final results = await Future.wait([
        _bookmarkService.getAll(),
        _bookmarkService.getFolders(),
      ]);
      emit(BookmarkLoaded(
        allBookmarks: results[0] as List<BookmarkItem>,
        allFolders: results[1] as List<BookmarkFolder>,
      ));
    } catch (e) {
      // In a real app, handle errors properly
      emit(const BookmarkLoaded(allBookmarks: [], allFolders: []));
    }
  }

  void toggleShowNotesOnly() {
    final currentState = state;
    if (currentState is BookmarkLoaded) {
      emit(currentState.copyWith(showNotesOnly: !currentState.showNotesOnly));
    }
  }

  void selectFolder(String? folderId) {
    final currentState = state;
    if (currentState is BookmarkLoaded) {
      // Allow unselecting by passing the same id again
      final newId = currentState.selectedFolderId == folderId ? null : folderId;
      emit(currentState.copyWith(selectedFolderId: newId));
    }
  }

  Future<void> addFolder(String name) async {
    final currentState = state;
    if (currentState is BookmarkLoaded) {
      await _bookmarkService.addFolder(name);
      // Reload everything to reflect the change
      await loadBookmarks();
    }
  }
}
