import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/cost_centers/list_cost_centers_use_case.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/application/cost_centers/suspend_cost_center_use_case.dart';
import 'package:qayd/application/cost_centers/activate_cost_center_use_case.dart';
import 'package:qayd/domain/entities/cost_center.dart';
import 'package:qayd/domain/value_objects/cost_center_type.dart';
import 'package:qayd/presentation/pages/cost_centers/cost_center_list_state.dart';

final class CostCenterListCubit extends Cubit<CostCenterListState> {
  CostCenterListCubit({
    required this.listUseCase,
    required this.suspendUseCase,
    required this.activateUseCase,
  }) : super(const CostCenterListInitial());

  final ListCostCentersUseCase listUseCase;
  final SuspendCostCenterUseCase suspendUseCase;
  final ActivateCostCenterUseCase activateUseCase;

  // ── Filter state ──────────────────────────────────────────────────────────
  CostCenterType? _typeFilter;
  bool _showSuspended = false;
  String _searchQuery = '';

  Future<void> load() async {
    emit(const CostCenterListLoading());
    final result = await listUseCase();
    result.fold(
      (f) => emit(CostCenterListFailure(f)),
      (centers) {
        final filtered = _applyFilters(centers);
        emit(
          CostCenterListReady(
            allCenters: centers,
            filteredCenters: filtered,
            typeFilter: _typeFilter,
            showSuspended: _showSuspended,
            searchQuery: _searchQuery,
          ),
        );
      },
    );
  }

  void setTypeFilter(CostCenterType? type) {
    _typeFilter = type;
    _emit();
  }

  void setShowSuspended(bool show) {
    _showSuspended = show;
    _emit();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _emit();
  }

  Future<void> suspend(String id) async {
    await suspendUseCase(id);
    await load();
  }

  Future<void> activate(String id) async {
    await activateUseCase(id);
    await load();
  }

  void _emit() {
    final current = state;
    if (current is CostCenterListReady) {
      emit(
        current.copyWith(
          filteredCenters: _applyFilters(current.allCenters),
          typeFilter: _typeFilter,
          showSuspended: _showSuspended,
          searchQuery: _searchQuery,
        ),
      );
    }
  }

  List<CostCenter> _applyFilters(List<CostCenter> all) {
    return all.where((c) {
      if (!_showSuspended && !c.isActive) return false;
      if (_typeFilter != null && c.type != _typeFilter) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!c.name.toLowerCase().contains(q)) return false;
      }
      return true;
    }).toList();
  }
}
