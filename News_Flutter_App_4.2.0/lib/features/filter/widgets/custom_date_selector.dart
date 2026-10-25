import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/utils/ui_utils.dart';

class CustomDateSelector extends StatefulWidget {
  final DateTime? selectedDate;
  final void Function(DateTime? date) onDateChanged;
  const CustomDateSelector({
    Key? key,
    required this.onDateChanged,
    this.selectedDate,
  }) : super(key: key);
  @override
  _CustomDateSelectorState createState() => _CustomDateSelectorState();
}

class _CustomDateSelectorState extends State<CustomDateSelector> {
  late DateTime? selectedDate = widget.selectedDate;

  @override
  void didUpdateWidget(covariant CustomDateSelector oldWidget) {
    if (oldWidget.selectedDate != widget.selectedDate) {
      selectedDate = widget.selectedDate;
      setState(() {});
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Theme(
        data: Theme.of(context).copyWith(
            colorScheme:
                ColorScheme.of(context).copyWith(primary: primaryColor),
            datePickerTheme: UiUtils.buildDatePickerTheme(context)),
        child: CalendarDatePicker(
          initialDate: DateTime.now(),
          firstDate: DateTime(1999),
          currentDate: selectedDate,
          lastDate: DateTime.now(),
          onDateChanged: (DateTime date) {
            setState(() {
              selectedDate = date;
            });
            widget.onDateChanged(date);
          },
        ),
      ),
    );
  }
}

class CustomCalendarView extends StatefulWidget {
  final Function(DateTime date) onDateSelected;
  final DateTime? selectedDate;
  const CustomCalendarView(
      {super.key, required this.onDateSelected, this.selectedDate});
  @override
  _CustomCalendarViewState createState() => _CustomCalendarViewState();
}

class _CustomCalendarViewState extends State<CustomCalendarView> {
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final startWeekday = firstDayOfMonth.weekday; // Mon = 1, Sun = 7
    final daysInMonth =
        DateUtils.getDaysInMonth(selectedDate.year, selectedDate.month);

    // Previous month filler days
    final prevMonth = DateTime(selectedDate.year, selectedDate.month - 1);
    final daysInPrevMonth =
        DateUtils.getDaysInMonth(prevMonth.year, prevMonth.month);
    final prefixDays = List.generate(
        startWeekday - 1,
        (i) => DateTime(prevMonth.year, prevMonth.month,
            daysInPrevMonth - (startWeekday - 2 - i)));

    // Current month days
    final currentMonthDays = List.generate(daysInMonth,
        (i) => DateTime(selectedDate.year, selectedDate.month, i + 1));

    // Fillers from next month
    final totalSlots = prefixDays.length + currentMonthDays.length;
    final suffixDays = List.generate(42 - totalSlots,
        (i) => DateTime(selectedDate.year, selectedDate.month + 1, i + 1));

    final allDays = [...prefixDays, ...currentMonthDays, ...suffixDays];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8), //.symmetric(vertical: 8),
          child: Text(
            DateFormat.yMMMM().format(selectedDate),
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
              .map((d) => Expanded(
                    child: Center(
                      child: Text(d,
                          style: TextStyle(fontWeight: FontWeight.w500)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        // Sized by its 6 rows (shrinkWrap) so no dates are clipped; the
        // enclosing scroll view handles overflow on short screens.
        GridView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.all(8),
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemCount: allDays.length,
          itemBuilder: (_, i) {
            final day = allDays[i];
            final isCurrentMonth = day.month == selectedDate.month;
            final isToday = DateUtils.isSameDay(day, DateTime.now());

            return GestureDetector(
              onTap: () {
                final bool isFutureDate = day.isAfter(DateTime.now());

                if (isCurrentMonth && !isFutureDate) {
                  widget.onDateSelected(day);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: (widget.selectedDate?.day == day.day && isCurrentMonth)
                      ? UiUtils.getColorScheme(context).primary
                      : (isToday
                          ? UiUtils.getColorScheme(context)
                              .primary
                              .withValues(alpha: 0.1)
                          : null),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: isCurrentMonth ? null : Colors.grey,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
