import 'package:flutter/material.dart';
import 'package:news/core/constants/strings.dart';
import 'package:news/utils/ui_utils.dart';

abstract class DurationFilter {
  Map<String, String> toMap();
  String toText(BuildContext context);
}

class LastDays extends DurationFilter {
  final int daysCount;
  LastDays({required this.daysCount});
  @override
  toMap() {
    return {
      LAST_N_DAYS: daysCount.toString(),
    };
  }

  @override
  String toText(BuildContext context) {
    if (daysCount == 1) {
      return UiUtils.getTranslatedLabel(context, 'today');
    }

    return UiUtils.getTranslatedLabel(context, 'last') +
        ' $daysCount ' +
        UiUtils.getTranslatedLabel(context, 'days');
  }

  @override
  bool operator ==(covariant DurationFilter other) {
    if (identical(this, other)) return true;
    if (other is LastDays) {
      return other.daysCount == daysCount;
    }
    return false;
  }

  @override
  int get hashCode => daysCount.hashCode;
}

class Year extends DurationFilter {
  final int year;
  Year({required this.year});
  @override
  Map<String, String> toMap() {
    return {
      YEAR: year.toString(),
    };
  }

  @override
  String toText(BuildContext context) {
    return year.toString();
  }

  @override
  bool operator ==(covariant DurationFilter other) {
    if (identical(this, other)) return true;
    if (other is Year) {
      return other.year == year;
    }
    return false;
  }

  @override
  int get hashCode => year.hashCode;
}

class DurationFilterWidget extends StatefulWidget {
  final DurationFilter? selectedFilter;
  final List<DurationFilter> filters;
  final void Function(DurationFilter? filter)? onSelected;
  const DurationFilterWidget(
      {super.key, required this.filters, this.onSelected, this.selectedFilter});

  @override
  State<DurationFilterWidget> createState() => _DurationFilterWidgetState();
}

class _DurationFilterWidgetState extends State<DurationFilterWidget> {
  late DurationFilter? selectedFilter = widget.selectedFilter;

  @override
  void didUpdateWidget(DurationFilterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedFilter != oldWidget.selectedFilter) {
      selectedFilter = widget.selectedFilter;
    }
  }

  @override
  Widget build(BuildContext context) {
    //print('Widget ${widget.selectedFilter}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.filters.map(
        (DurationFilter e) {
          return _buildDurationFilter(context, e);
        },
      ).toList(),
    );
  }

  Widget _buildDurationFilter(BuildContext context, DurationFilter filter) {
    return GestureDetector(
      onTap: () {
        if (selectedFilter == filter) {
          selectedFilter = null;
        } else {
          selectedFilter = filter;
        }
        widget.onSelected?.call(selectedFilter);

        setState(() {});
      },
      child: Container(
        // FIGMA(2250-9456): each preset chip hugs its own text (no fixed width)
        // and the selected one uses a 10% navy (secondary) highlight, rounded 4
        // - matching the design instead of a fixed 100px box.
        decoration: BoxDecoration(
          color: selectedFilter == filter
              ? UiUtils.getColorScheme(context).onPrimary.withValues(alpha: 0.1)
              : UiUtils.getColorScheme(context).surface,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(filter.toText(context),
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: UiUtils.getColorScheme(context).onPrimary)),
        ),
      ),
    );
  }
}
