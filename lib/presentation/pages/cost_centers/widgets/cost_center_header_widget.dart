import 'package:flutter/material.dart';
import 'package:qayd/application/cost_centers/dtos/cost_center_details_dto.dart';
import 'package:qayd/domain/entities/cost_center.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:qayd/presentation/pages/cost_centers/cost_center_extensions.dart';
import 'package:qayd/presentation/theme/color_tokens.dart';
import 'package:qayd/presentation/theme/radius_tokens.dart';
import 'package:qayd/presentation/theme/spacing_tokens.dart';
import 'package:qayd/presentation/utils/numerical_styling.dart';

/// Premium hero header for the cost center detail page.
///
/// The focal point is the **total confirmed amount** rendered in large
/// typography. The card-less approach lets the content breathe against
/// the gradient background while a subtle trend indicator (arrow + %)
/// contextualises the figure at a glance.
class CostCenterHeaderWidget extends StatefulWidget {
  const CostCenterHeaderWidget({
    super.key,
    required this.center,
    required this.dto,
    required this.typeColor,
    required this.isProfit,
  });

  final CostCenter center;
  final CostCenterDetailsDto dto;
  final Color typeColor;
  final bool isProfit;

  @override
  State<CostCenterHeaderWidget> createState() =>
      _CostCenterHeaderWidgetState();
}

class _CostCenterHeaderWidgetState extends State<CostCenterHeaderWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final center = widget.center;
    final dto = widget.dto;
    final growthPct = dto.growthPct;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.typeColor,
            Color.lerp(widget.typeColor, Colors.black, 0.25)!,
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Subtle radial highlight ──────────────────────────────
          Positioned(
            top: -60,
            right: -40,
            width: 220,
            height: 220,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  Colors.white.withValues(alpha: 0.07),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                SpacingTokens.lg,
                SpacingTokens.xxl + 16,
                SpacingTokens.lg,
                SpacingTokens.lg,
              ),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // ── Type pill + status ──────────────────────
                      Row(
                        children: [
                          _Pill(
                            icon: center.type.icon,
                            label: center.type.labelAr,
                            isProfit: widget.isProfit,
                          ),
                          if (!center.isActive) ...[
                            SizedBox(width: SpacingTokens.xs),
                            _Pill(
                              icon: Icons.pause_rounded,
                              label: AppStrings.costCenterSuspendedBadge,
                              isWarning: true,
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: SpacingTokens.sm + 2),

                      // ── Center Name ─────────────────────────────
                      Text(
                        center.name,
                        style: tt.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (center.description?.isNotEmpty == true) ...[
                        SizedBox(height: 4),
                        Text(
                          center.description!,
                          style: tt.bodySmall?.copyWith(
                            color: Colors.white60,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      SizedBox(height: SpacingTokens.lg),

                      // ── Focal Balances ───────────────────────────
                      if (dto.totalsByCurrency.isEmpty)
                        Text.rich(
                          buildNumericalScaledSpan(
                            '0',
                            TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                              letterSpacing: -0.5,
                            ),
                          ),
                        )
                      else
                        ...dto.totalsByCurrency.entries.map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text.rich(
                                buildNumericalScaledSpan(
                                  _fmtBalance(e.value ~/ 100, e.key),
                                  TextStyle(
                                    color: Colors.white,
                                    fontSize: dto.totalsByCurrency.length > 1
                                        ? 28
                                        : 34,
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                            )),
                      SizedBox(height: SpacingTokens.xs),

                      // ── Growth indicator ────────────────────────
                      Row(
                        children: [
                          Text(
                            AppStrings.costCenterTotalLabel,
                            style: tt.labelSmall?.copyWith(
                              color: Colors.white54,
                            ),
                          ),
                          if (growthPct != null) ...[
                            SizedBox(width: SpacingTokens.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                  RadiusTokens.pill,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    growthPct >= 0
                                        ? Icons.trending_up_rounded
                                        : Icons.trending_down_rounded,
                                    size: 13,
                                    color: Colors.white70,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    '${growthPct >= 0 ? '+' : ''}${growthPct.toStringAsFixed(1)}%',
                                    style: tt.labelSmall?.copyWith(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtBalance(int major, String currency) {
    if (major == 0) return '0';
    // Add thousands separators
    final formatted = major.abs().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return '$formatted $currency';
  }
}

/// A tiny translucent pill badge used inside the hero header.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    this.isWarning = false,
    this.isProfit,
  });
  final IconData icon;
  final String label;
  final bool isWarning;
  final bool? isProfit;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    
    if (isWarning) {
      bg = Colors.redAccent.withValues(alpha: 0.25);
      fg = Colors.white;
    } else if (isProfit == true) {
      bg = ColorTokens.emerald500.withValues(alpha: 0.25);
      fg = Colors.greenAccent;
    } else if (isProfit == false) {
      bg = ColorTokens.debitBlue.withValues(alpha: 0.25);
      fg = Colors.lightBlueAccent;
    } else {
      bg = Colors.white.withValues(alpha: 0.12);
      fg = Colors.white70;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(RadiusTokens.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }
}
