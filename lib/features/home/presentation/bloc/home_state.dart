part of 'home_cubit.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeLoading extends HomeState {}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}

class HomeLoaded extends HomeState {
  final String locationLabel;
  final LastRead? lastRead;
  final DailyVerse? dailyVerse;
  final Set<String> bookmarkKeys;
  final bool isDailyVerseLoading;

  const HomeLoaded({
    required this.locationLabel,
    this.lastRead,
    this.dailyVerse,
    required this.bookmarkKeys,
    this.isDailyVerseLoading = false,
  });

  HomeLoaded copyWith({
    String? locationLabel,
    LastRead? lastRead,
    DailyVerse? dailyVerse,
    Set<String>? bookmarkKeys,
    bool? isDailyVerseLoading,
  }) {
    return HomeLoaded(
      locationLabel: locationLabel ?? this.locationLabel,
      lastRead: lastRead ?? this.lastRead,
      dailyVerse: dailyVerse ?? this.dailyVerse,
      bookmarkKeys: bookmarkKeys ?? this.bookmarkKeys,
      isDailyVerseLoading: isDailyVerseLoading ?? this.isDailyVerseLoading,
    );
  }

  @override
  List<Object?> get props => [
        locationLabel,
        lastRead,
        dailyVerse,
        bookmarkKeys,
        isDailyVerseLoading,
      ];
}

class DailyVerse {
  final int surah;
  final int ayah;
  final String arabic;
  final String translation;

  const DailyVerse({
    required this.surah,
    required this.ayah,
    required this.arabic,
    required this.translation,
  });
}
