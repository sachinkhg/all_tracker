// List<T> sortListByDate<T>(
//   List<T> list,
//   DateTime? Function(T) getDate,
// ) {
//   final sortedList = List<T>.from(list);
//   sortedList.sort((a, b) {
//     final dateA = getDate(a);
//     final dateB = getDate(b);

//     if (dateA == null && dateB == null) return 0;
//     if (dateA == null) return 1;   // a after b
//     if (dateB == null) return -1;  // b after a
//     return dateA.compareTo(dateB);
//   });
//   return sortedList;
// }

//     // Format datetime to string
// String formatDate(DateTime date) {
//   return "${date.year.toString().padLeft(4, '0')}-"
//           "${date.month.toString().padLeft(2, '0')}-"
//           "${date.day.toString().padLeft(2, '0')}";
// }

// /// Groups a generic list by the year extracted from a date property
// Map<int, List<T>> groupByYear<T>(List<T> items, DateTime? Function(T) getDate) {
//   final map = <int, List<T>>{};

//   for (var item in items) {
//     final date = getDate(item);
//     if (date != null) {
//       final year = date.year;
//       map.putIfAbsent(year, () => []).add(item);
//     }
//   }

//   return map;
// }

// /// Groups a generic list by year and then by month extracted from a date property
// Map<int, Map<int, List<T>>> groupByYearAndMonth<T>(
//     List<T> items, DateTime? Function(T) getDate) {
//   final map = <int, Map<int, List<T>>>{};

//   for (var item in items) {
//     final date = getDate(item);
//     if (date != null) {
//       final year = date.year;
//       final month = date.month;

//       map.putIfAbsent(year, () => <int, List<T>>{});
//       map[year]!.putIfAbsent(month, () => <T>[]);
//       map[year]![month]!.add(item);
//     }
//   }

//   return map;
// }

// /// Groups a generic list by month *and year* extracted from a date property
// Map<String, List<T>> groupByMonthYear<T>(
//   List<T> items,
//   DateTime? Function(T) getDate,
// ) {
//   final map = <String, List<T>>{};

//   for (var item in items) {
//     final date = getDate(item);
//     if (date != null) {
//       final key = "${date.year}-${date.month.toString().padLeft(2, '0')}"; 
//       // Example: "2025-08"

//       map.putIfAbsent(key, () => <T>[]);
//       map[key]!.add(item);
//     }
//   }

//   return map;
// }



// /// Returns a list of items where the date property (extracted via getDate) is null
// List<T> filterItemsWithNullDate<T>(List<T> items, DateTime? Function(T) getDate) {
//   return items.where((item) => getDate(item) == null).toList();
// }


