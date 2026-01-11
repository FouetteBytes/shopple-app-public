import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DateRangeResult {
  final DateTime? start;
  final DateTime? end;
  const DateRangeResult({this.start, this.end});
}

Future<DateRangeResult?> showModernDateRangePickerSheet(
  BuildContext context, {
  required Color themeColor,
  DateTime? initialStart,
  DateTime? initialEnd,
}) {
  DateTime visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? tempStart = initialStart;
  DateTime? tempEnd = initialEnd;

  return showModalBottomSheet<DateRangeResult>(
    context: context,
    isScrollControlled: false,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) {
        List<String> labels = const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
        DateTime firstOfMonth = DateTime(
          visibleMonth.year,
          visibleMonth.month,
          1,
        );
        int weekdayOffset = firstOfMonth.weekday % 7; // Sunday => 0
        int daysInMonth = DateTime(
          visibleMonth.year,
          visibleMonth.month + 1,
          0,
        ).day;
        int totalCells = weekdayOffset + daysInMonth;
        int rows = (totalCells / 7).ceil();
        int gridCount = rows * 7;

        bool isSameDay(DateTime a, DateTime b) =>
            a.year == b.year && a.month == b.month && a.day == b.day;
        bool isInRange(DateTime d) {
          if (tempStart == null || tempEnd == null) return false;
          return !d.isBefore(tempStart!) && !d.isAfter(tempEnd!);
        }

        List<Widget> dayCells = [];
        for (int i = 0; i < gridCount; i++) {
          final dayNum = i - weekdayOffset + 1;
          DateTime? date;
          if (dayNum > 0 && dayNum <= daysInMonth) {
            date = DateTime(visibleMonth.year, visibleMonth.month, dayNum);
          }
          final isDisabled = date == null;
          final bool isStart =
              date != null && tempStart != null && isSameDay(date, tempStart!);
          final bool isEnd =
              date != null && tempEnd != null && isSameDay(date, tempEnd!);
          final bool inRange = date != null && isInRange(date);

          BorderRadius radius = BorderRadius.circular(10);
          if (inRange && !isStart && !isEnd) {
            // middle segment becomes a pill connector (no rounding so they connect visually)
            radius = BorderRadius.zero;
          } else if (isStart && tempEnd != null && !isEnd) {
            radius = const BorderRadius.horizontal(
              left: Radius.circular(14),
              right: Radius.circular(4),
            );
          } else if (isEnd && tempStart != null && !isStart) {
            radius = const BorderRadius.horizontal(
              right: Radius.circular(14),
              left: Radius.circular(4),
            );
          } else if (isStart && isEnd) {
            radius = BorderRadius.circular(14); // single day selection
          }

          Color bgColor = Colors.transparent;
          if (isStart || isEnd) {
            bgColor = themeColor;
          } else if (inRange) {
            bgColor = themeColor.withValues(alpha: .30);
          }

          final textColor = isStart || isEnd
              ? Colors.white
              : (isDisabled ? Colors.white24 : Colors.white70);

          dayCells.add(
            GestureDetector(
              onTap: isDisabled
                  ? null
                  : () {
                      setSheetState(() {
                        if (tempStart == null ||
                            (tempStart != null && tempEnd != null)) {
                          tempStart = date;
                          tempEnd = null;
                        } else {
                          if (date!.isBefore(tempStart!)) {
                            tempStart = date;
                          } else if (isSameDay(date, tempStart!)) {
                            tempEnd = date; // single day stays single
                          } else {
                            tempEnd = date;
                          }
                        }
                      });
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                margin: EdgeInsets.symmetric(
                  horizontal: inRange && !isStart && !isEnd ? 0 : 4,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: radius,
                  border: (isStart || isEnd)
                      ? Border.all(
                          color: Colors.white.withValues(alpha: .7),
                          width: 1,
                        )
                      : null,
                ),
                child: Center(
                  child: Text(
                    date == null ? '' : '${date.day}',
                    style: GoogleFonts.lato(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1F2128),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => setSheetState(() {
                        visibleMonth = DateTime(
                          visibleMonth.year,
                          visibleMonth.month - 1,
                        );
                      }),
                      icon: const Icon(
                        Icons.chevron_left,
                        color: Colors.white70,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '${_monthAbbr(visibleMonth.month)} ${visibleMonth.year}',
                          style: GoogleFonts.lato(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setSheetState(() {
                        visibleMonth = DateTime(
                          visibleMonth.year,
                          visibleMonth.month + 1,
                        );
                      }),
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: labels
                      .map(
                        (l) => Expanded(
                          child: Center(
                            child: Text(
                              l,
                              style: GoogleFonts.lato(
                                color: Colors.white54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                    children: dayCells,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tempStart == null ? 'No start' : _formatShort(tempStart!),
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white54,
                      size: 16,
                    ),
                    Text(
                      tempEnd == null ? 'No end' : _formatShort(tempEnd!),
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setSheetState(() {
                          tempStart = null;
                          tempEnd = null;
                        });
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        ctx,
                        DateRangeResult(start: tempStart, end: tempEnd),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Apply',
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

String _monthAbbr(int m) {
  const names = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return names[m - 1];
}

String _formatShort(DateTime d) {
  return '${d.day} ${_monthAbbr(d.month)}';
}
