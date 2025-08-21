import 'package:flutter/material.dart';
import 'shared_button.dart';

class SharedCard extends StatelessWidget {
  final IconData icon;
  final Color? iconBackgroundColor;
  final String title;
  final String? subtitle1;
  final IconData? subtitle2Icon; // Optional
  final String? subtitle2; // Optional
  final String? actionButtonText; // Optional
  final List<String>? actionListItems; // New optional list below button
  final Color? textColor;
  final Color? inactiveTextColor;
  final Color? backgroundColor;
  final VoidCallback? onActionPressed; // Optional if button is not shown
  final VoidCallback? onCardTap;

  const SharedCard({
    super.key,
    required this.icon,
    this.iconBackgroundColor,
    required this.title,
    this.subtitle1,
    this.subtitle2Icon,
    this.subtitle2,
    this.actionButtonText,
    this.actionListItems,
    this.textColor,
    this.inactiveTextColor,
    this.backgroundColor,
    this.onActionPressed,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    final iconContainerSize = screenWidth * 0.12;
    final iconSize = iconContainerSize * 0.58;

    final iconBackgroundColor = this.iconBackgroundColor ?? Theme.of(context).colorScheme.primary;
    final textColor = this.textColor ?? Theme.of(context).colorScheme.primary;
    final inactiveTextColor = this.inactiveTextColor ?? Theme.of(context).colorScheme.primary;
    final backgroundColor = this.backgroundColor ?? Theme.of(context).colorScheme.onPrimary;

    return GestureDetector(
      onTap: onCardTap,  
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 4),
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // align list left
          children: [
            // First Row → Icon + Details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    borderRadius: BorderRadius.circular(iconContainerSize * 0.25),
                  ),
                  child: Icon(icon, color: backgroundColor, size: iconSize),
                ),
                SizedBox(width: screenWidth * 0.03),

                // Text Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          fontSize: screenWidth * 0.032,
                        ),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis, // move here, outside TextStyle
                      ),
                      const SizedBox(height: 2),
                      if (subtitle1 != null)                      
                        Text(
                          subtitle1!,
                          style: theme.textTheme.bodySmall?.copyWith(
                                color: inactiveTextColor,
                                fontSize: screenWidth * 0.032,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),

                      if (subtitle2 != null && subtitle2!.isNotEmpty)
                        
                        Row(
                          children: [
                            if (subtitle2Icon != null)
                              Icon(
                                subtitle2Icon,
                                size: screenWidth * 0.037,
                                color: inactiveTextColor,
                              ),
                            if (subtitle2Icon != null) const SizedBox(width: 4),
                            Text(
                              subtitle2!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                    color: inactiveTextColor,
                                    fontSize: screenWidth * 0.032,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // Second Row → Button below Icon
            if (actionButtonText != null && actionButtonText!.isNotEmpty) ...[            
              const SizedBox(height: 8),
              const Divider(height: 2),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 0), // Same alignment as icon
                  child: SharedButton(
                    label: actionButtonText!,
                    onPressed: onActionPressed ?? () {},
                    backgroundColor: backgroundColor,
                    textColor: theme.colorScheme.onSurface,
                    icon: null,
                    styleType: 2,
                  ),
                ),
              ),
            ],

            // New: Dynamic indented list below button with same indentation
            if (actionListItems != null && actionListItems!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Padding(
                padding: EdgeInsets.only(left: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: actionListItems!.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4), // space between items
                      child: Text(
                        "• $item",
                        style: theme.textTheme.bodySmall?.copyWith(
                              color: inactiveTextColor,
                              fontSize: screenWidth * 0.03,
                            ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}



// import 'package:flutter/material.dart';
// import 'shared_button.dart';

// class SharedCard extends StatelessWidget {
  
//   final IconData icon;
//   final Color? iconBackgroundColor;
//   final String title;
//   final String subtitle1;
//   final IconData? subtitle2Icon; // Optional
//   final String? subtitle2; // Optional
//   final String? actionButtonText; // Optional
//   final Color? textColor;
//   final Color? inactiveTextColor;
//   final Color? backgroundColor;
//   final VoidCallback? onActionPressed; // Optional if button is not shown

//   const SharedCard({
//     super.key,
//     required this.icon,
//     this.iconBackgroundColor,
//     required this.title,
//     required this.subtitle1,
//     this.subtitle2Icon,
//     this.subtitle2,
//     this.actionButtonText,
//     this.textColor,
//     this.inactiveTextColor,
//     this.backgroundColor,
//     this.onActionPressed,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final screenWidth = MediaQuery.of(context).size.width;

//     final iconContainerSize = screenWidth * 0.12;
//     final iconSize = iconContainerSize * 0.58;
    
//     final iconBackgroundColor = Theme.of(context).colorScheme.primary;
//     final textColor = Theme.of(context).colorScheme.primary;
//     final inactiveTextColor = Theme.of(context).colorScheme.primary;
//     final backgroundColor = Theme.of(context).colorScheme.onPrimary;

//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 4),
//       padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: 12),
//       decoration: BoxDecoration(
//         color: backgroundColor,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black12,
//             blurRadius: 6,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           // First Row → Icon + Details
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Icon
//               Container(
//                 width: iconContainerSize,
//                 height: iconContainerSize,
//                 decoration: BoxDecoration(
//                   color: iconBackgroundColor,
//                   borderRadius: BorderRadius.circular(iconContainerSize * 0.25),
//                 ),
//                 child: Icon(icon, color: backgroundColor, size: iconSize),
//               ),
//               SizedBox(width: screenWidth * 0.03),

//               // Text Details
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title,
//                       style: theme.textTheme.bodyLarge?.copyWith(
//                             fontWeight: FontWeight.w600,
//                             color: textColor,
//                             overflow: TextOverflow.ellipsis,
//                             fontSize: screenWidth * 0.032,
//                           ),
//                       maxLines: 1,
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       subtitle1,
//                       style: theme.textTheme.bodySmall?.copyWith(
//                             color: inactiveTextColor,
//                             fontSize: screenWidth * 0.032,
//                           ),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 2),

//                     if (subtitle2 != null && subtitle2!.isNotEmpty)
//                       Row(
//                         children: [
//                           if (subtitle2Icon != null)
//                             Icon(
//                               subtitle2Icon,
//                               size: screenWidth * 0.037,
//                               color: inactiveTextColor,
//                             ),
//                           if (subtitle2Icon != null) SizedBox(width: 4),
//                           Text(
//                             subtitle2!,
//                             style: theme.textTheme.bodyMedium?.copyWith(
//                                   color: inactiveTextColor,
//                                   fontSize: screenWidth * 0.032,
//                                 ),
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ],
//                       ),
//                   ],
//                 ),
//               ),
//             ],
//           ),

//           // Second Row → Button below Icon
//           if (actionButtonText != null && actionButtonText!.isNotEmpty) ...[
//             const SizedBox(height: 8),
//             Align(
//               alignment: Alignment.centerLeft,
//               child: Padding(
//                 padding: EdgeInsets.only(left: 0), // Same alignment as icon
//                 child: SharedButton(
//                   label: actionButtonText!,
//                   onPressed: onActionPressed ?? () {},
//                   backgroundColor: backgroundColor,
//                   textColor: theme.colorScheme.onSurface,
//                   icon: null,
//                   styleType: 2,
//                 ),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }