import 'package:flutter/material.dart';

/// A reusable, safe-area-aware modal bottom sheet layout for AiFinancify.
///
/// Ensures bottom action buttons (like "Save Transaction") remain fully visible
/// and accessible above the Android system navigation bar (3-button navigation
/// or gesture pill) and the virtual keyboard across all device sizes.
class AppModalSheetLayout extends StatelessWidget {
  final String? title;
  final Widget? header;
  final Widget child;
  final Widget? bottomAction;
  final double maxHeightFactor;
  final EdgeInsetsGeometry padding;

  const AppModalSheetLayout({
    super.key,
    this.title,
    this.header,
    required this.child,
    this.bottomAction,
    this.maxHeightFactor = 0.88,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = mediaQuery.viewInsets.bottom;

    Widget? effectiveHeader = header;
    if (effectiveHeader == null && title != null) {
      effectiveHeader = Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white54, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: mediaQuery.size.height * maxHeightFactor,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (effectiveHeader != null) effectiveHeader,
              Flexible(
                child: SingleChildScrollView(
                  padding: padding,
                  child: child,
                ),
              ),
              if (bottomAction != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: bottomAction!,
                )
              else
                const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper function to open an [AppModalSheetLayout] bottom sheet with
/// consistent theme, radius, and safe-area constraints.
Future<T?> showAppModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color backgroundColor = const Color(0xFF1E293B),
  ShapeBorder shape = const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  ),
  bool isScrollControlled = true,
  bool useSafeArea = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    backgroundColor: backgroundColor,
    shape: shape,
    builder: builder,
  );
}
