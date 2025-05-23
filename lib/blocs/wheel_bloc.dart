import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:math';
import 'dart:async';

class Option extends Equatable {
  final String name;
  const Option(this.name);

  @override
  List<Object?> get props => [name];
}

class WheelState extends Equatable {
  final int? selectedIndex;
  final List<Option> options;
  final bool showModify;
  final bool showResult;
  final bool shouldSpin;

  WheelState({
    this.selectedIndex,
    List<Option>? options,
    this.showModify = false,
    this.showResult = false,
    this.shouldSpin = false,
  }) : options = options ?? [];

  WheelState copyWith({
    int? selectedIndex,
    List<Option>? options,
    bool? showModify,
    bool? showResult,
    bool? shouldSpin,
  }) {
    return WheelState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      options: options ?? this.options,
      showModify: showModify ?? this.showModify,
      showResult: showResult ?? this.showResult,
      shouldSpin: shouldSpin ?? this.shouldSpin,
    );
  }

  @override
  List<Object?> get props => [selectedIndex, options, showModify, showResult, shouldSpin];
}

abstract class WheelEvent extends Equatable {
  const WheelEvent();

  @override
  List<Object?> get props => [];
}

class ShowResultEvent extends WheelEvent {}
class ShowModifyEvent extends WheelEvent {}
class CloseModifyEvent extends WheelEvent {}
class UpdateOptionEvent extends WheelEvent {
  final int index;
  final String value;
  const UpdateOptionEvent(this.index, this.value);

  @override
  List<Object?> get props => [index, value];
}
class RemoveOptionEvent extends WheelEvent {
  final int index;
  const RemoveOptionEvent(this.index);

  @override
  List<Object?> get props => [index];
}
class AddOptionEvent extends WheelEvent {}
class SpinWheelEvent extends WheelEvent {}

class WheelBloc extends Bloc<WheelEvent, WheelState> {
  final _random = Random();
  StreamController<int>? _spinController;

  WheelBloc() : super(WheelState(
    selectedIndex: 0,
    options: [Option('A'), Option('B'), Option('C')]
  )){
    on<ShowResultEvent>((event, emit) {
      emit(state.copyWith(showResult: true));
    });
    on<ShowModifyEvent>((event, emit) {
      emit(state.copyWith(showModify: true));
    });
    on<CloseModifyEvent>((event, emit) {
      emit(state.copyWith(showModify: false));
    });
    on<UpdateOptionEvent>((event, emit) {
      final newOptions = List<Option>.from(state.options);
      newOptions[event.index] = Option(event.value);
      emit(state.copyWith(options: newOptions));
    });
    on<RemoveOptionEvent>((event, emit) {
      final newOptions = List<Option>.from(state.options)..removeAt(event.index);
      emit(state.copyWith(options: newOptions));
    });
    on<AddOptionEvent>((event, emit) {
      final newOptions = List<Option>.from(state.options)..add(Option('New Option'));
      emit(state.copyWith(options: newOptions));
    });
    on<SpinWheelEvent>((event, emit) {
      final randomIndex = _random.nextInt(state.options.length);
      _spinController?.add(randomIndex);
      emit(state.copyWith(selectedIndex: randomIndex));
    });
  }

  @override
  Future<void> close() {
    _spinController?.close();
    return super.close();
  }
}
