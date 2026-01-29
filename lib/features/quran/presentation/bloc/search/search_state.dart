part of 'search_cubit.dart';

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object> get props => [];
}

class SearchInitial extends SearchState {
  final List<int> surahNumbers;

  const SearchInitial(this.surahNumbers);

  @override
  List<Object> get props => [surahNumbers];
}

class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  final List<int> surahNumbers;

  const SearchLoaded(this.surahNumbers);

  @override
  List<Object> get props => [surahNumbers];
}
