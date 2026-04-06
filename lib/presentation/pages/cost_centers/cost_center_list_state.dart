import 'package:equatable/equatable.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/domain/entities/cost_center.dart';
import 'package:qayd/domain/value_objects/cost_center_type.dart';

sealed class CostCenterListState extends Equatable {
  const CostCenterListState();

  @override
  List<Object?> get props => [];
}

final class CostCenterListInitial extends CostCenterListState {
  const CostCenterListInitial();
}

final class CostCenterListLoading extends CostCenterListState {
  const CostCenterListLoading();
}

final class CostCenterListFailure extends CostCenterListState {
  const CostCenterListFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class CostCenterListReady extends CostCenterListState {
  const CostCenterListReady({
    required this.allCenters,
    required this.filteredCenters,
    required this.typeFilter,
    required this.showSuspended,
    required this.searchQuery,
  });

  final List<CostCenter> allCenters;
  final List<CostCenter> filteredCenters;
  final CostCenterType? typeFilter; // null = all
  final bool showSuspended;
  final String searchQuery;

  @override
  List<Object?> get props => [
    allCenters,
    filteredCenters,
    typeFilter,
    showSuspended,
    searchQuery,
  ];

  CostCenterListReady copyWith({
    List<CostCenter>? allCenters,
    List<CostCenter>? filteredCenters,
    CostCenterType? typeFilter,
    bool? showSuspended,
    String? searchQuery,
  }) {
    return CostCenterListReady(
      allCenters: allCenters ?? this.allCenters,
      filteredCenters: filteredCenters ?? this.filteredCenters,
      typeFilter: typeFilter ?? this.typeFilter,
      showSuspended: showSuspended ?? this.showSuspended,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
