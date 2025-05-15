import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Wheel option model
class WheelOption extends Equatable {
  final String name;
  const WheelOption(this.name);

  WheelOption copyWith({String? name}) => WheelOption(name ?? this.name);

  @override
  List<Object?> get props => [name];
}

// Events
abstract class WheelEvent extends Equatable {
  const WheelEvent();
  @override
  List<Object?> get props => [];
}

class ShowResultEvent extends WheelEvent {}
class ShowModifyEvent extends WheelEvent {}
class CloseModifyEvent extends WheelEvent {}
class AddOptionEvent extends WheelEvent {}
class RemoveOptionEvent extends WheelEvent {
  final int index;
  const RemoveOptionEvent(this.index);
  @override
  List<Object?> get props => [index];
}
class UpdateOptionEvent extends WheelEvent {
  final int index;
  final String name;
  const UpdateOptionEvent(this.index, this.name);
  @override
  List<Object?> get props => [index, name];
}

// State
class WheelState extends Equatable {
  final bool showResult;
  final bool showModify;
  final List<WheelOption> options;
  const WheelState({
    this.showResult = false,
    this.showModify = false,
    this.options = const [
      WheelOption('Golden Dragon'),
      WheelOption('Spicy House'),
      WheelOption('Veggie Delight'),
      WheelOption('Noodle Bar'),
    ],
  });

  WheelState copyWith({
    bool? showResult,
    bool? showModify,
    List<WheelOption>? options,
  }) => WheelState(
    showResult: showResult ?? this.showResult,
    showModify: showModify ?? this.showModify,
    options: options ?? this.options,
  );

  @override
  List<Object?> get props => [showResult, showModify, options];
}

// Bloc
class WheelBloc extends Bloc<WheelEvent, WheelState> {
  WheelBloc() : super(const WheelState()) {
    on<ShowResultEvent>((event, emit) => emit(state.copyWith(showResult: true)));
    on<ShowModifyEvent>((event, emit) => emit(state.copyWith(showModify: true)));
    on<CloseModifyEvent>((event, emit) => emit(state.copyWith(showModify: false)));
    on<AddOptionEvent>((event, emit) {
      final updated = List<WheelOption>.from(state.options)..add(const WheelOption('New Option'));
      emit(state.copyWith(options: updated));
    });
    on<RemoveOptionEvent>((event, emit) {
      final updated = List<WheelOption>.from(state.options)..removeAt(event.index);
      emit(state.copyWith(options: updated));
    });
    on<UpdateOptionEvent>((event, emit) {
      final updated = List<WheelOption>.from(state.options);
      updated[event.index] = updated[event.index].copyWith(name: event.name);
      emit(state.copyWith(options: updated));
    });
  }
}
