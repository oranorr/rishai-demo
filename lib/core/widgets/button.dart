// // ignore_for_file: public_member_api_docs, sort_constructors_first
// import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:rishai/core/extensions/build_context_extension.dart';

// import 'package:rishai/core/theme/theme_colors.dart';

// enum ButtonType { primary, secondary, teritary, disabled }

// enum ButtonSize { s, m, l }

// // class RishButton2 extends StatelessWidget {
// //   final VoidCallback action;
// //   final String label;
// //   final double? width;

// //   // final Color? fillColor;
// //   final Color? borderColor;
// //   final Color? textColor;
// //   final bool enabled;
// //   final bool isLoading;
// //   final ButtonType type;
// //   final ButtonSize size;

// //   const RishButton2({
// //     Key? key,
// //     required this.action,
// //     required this.label,
// //     this.width,
// //     // this.fillColor,
// //     this.borderColor,
// //     this.textColor,
// //     required this.enabled,
// //     required this.isLoading,
// //     required this.type,
// //     required this.size,
// //   }) : super(key: key);

// //   factory RishButton2.primary(
// //       {required String label,
// //       required bool isLoading,
// //       required ButtonSize size,
// //       required VoidCallback action}) {
// //     return RishButton2(
// //       action: action,
// //       label: label,
// //       enabled: true,
// //       isLoading: isLoading,
// //       type: ButtonType.primary,
// //       size: size,
// //     );
// //   }

// //   factory RishButton2.secondary(
// //       {required String label,
// //       required bool isLoading,
// //       required ButtonSize size,
// //       required VoidCallback action}) {
// //     return RishButton2(
// //       action: action,
// //       label: label,
// //       enabled: true,
// //       isLoading: isLoading,
// //       type: ButtonType.secondary,
// //       size: size,
// //     );
// //   }

// //   factory RishButton2.teritary(
// //       {required String label,
// //       required bool isLoading,
// //       required ButtonSize size,
// //       required VoidCallback action}) {
// //     return RishButton2(
// //       action: action,
// //       label: label,
// //       enabled: true,
// //       isLoading: isLoading,
// //       type: ButtonType.teritary,
// //       size: size,
// //     );
// //   }

// //   factory RishButton2.disabled({
// //     required String label,
// //     required ButtonSize size,
// //   }) {
// //     return RishButton2(
// //       action: () {},
// //       label: label,
// //       enabled: false,
// //       isLoading: false,
// //       type: ButtonType.disabled,
// //       size: size,
// //     );
// //   }

// //   BorderRadius _resolveRadious(ButtonSize size) {
// //     switch (size) {
// //       case ButtonSize.s:
// //         return BorderRadius.circular(16);
// //       case ButtonSize.m:
// //         return BorderRadius.circular(20);
// //       case ButtonSize.l:
// //         return BorderRadius.circular(24);
// //       default:
// //         return BorderRadius.circular(20);
// //     }
// //   }

// //   Color _resolveFillColor(ButtonType type, BuildContext context) {
// //     switch (type) {
// //       case ButtonType.primary:
// //         return context.theme.colorScheme.primary;
// //       case ButtonType.disabled:
// //         return RishColors.gray700;
// //       case ButtonType.secondary || ButtonType.teritary:
// //         return Colors.transparent;
// //       default:
// //         return Colors.red;
// //     }
// //   }

// //   double _resolveHeight(ButtonSize size) {
// //     switch (size) {
// //       case ButtonSize.s:
// //         return 38.0;
// //       case ButtonSize.m:
// //         return 48.0;
// //       case ButtonSize.l:
// //         return 58.0;
// //       default:
// //         return 48;
// //     }
// //   }

// //   TextStyle _resolveStyle(
// //       ButtonType type, ButtonSize size, BuildContext context) {
// //     TextStyle style = const TextStyle();
// //     Color color;
// //     switch (size) {
// //       case ButtonSize.s:
// //         style = context.styles.regularMedium;
// //         break;
// //       case ButtonSize.m:
// //         style = context.styles.regularLarge;
// //         break;
// //       case ButtonSize.l:
// //         style = context.styles.regularXtraLarge;
// //         break;
// //       default:
// //     }

// //     switch (type) {
// //       case ButtonType.secondary || ButtonType.teritary:
// //         color = context.theme.colorScheme.primary;
// //         break;
// //       case ButtonType.disabled:
// //         color = RishColors.gray400;
// //       case ButtonType.primary:
// //         color = RishColors.gray50;
// //       default:
// //         color = Colors.red;
// //     }
// //     return style.copyWith(color: color);
// //   }

// //   double _resolveLoadingWidth(ButtonSize size) {
// //     switch (size) {
// //       case ButtonSize.s:
// //         return 4.w;

// //       case ButtonSize.m:
// //         return 6.w;
// //       case ButtonSize.l:
// //         return 8.w;
// //       default:
// //         return 6.w;
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return GestureDetector(
// //       onTap: action,
// //       // onTap: enabled && !isLoading ? action : null,
// //       child: Container(
// //         height: _resolveHeight(size),
// //         width: width ?? double.infinity,
// //         decoration: BoxDecoration(
// //           color: _resolveFillColor(type, context),
// //           borderRadius: _resolveRadious(size),
// //           border: borderColor != null
// //               ? Border.all(width: 1, color: borderColor!)
// //               : null,
// //         ),
// //         child: Row(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: [
// //             Text(
// //               label,
// //               style: _resolveStyle(type, size, context),
// //             ),
// //             if (isLoading && type == ButtonType.primary) ...[
// //               SizedBox(
// //                 width: _resolveLoadingWidth(size),
// //               ),
// //               const CircularProgressIndicator(
// //                 strokeWidth: 4,
// //                 color: Colors.white,
// //               )
// //             ]
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

// class RishButton extends StatelessWidget {
//   final VoidCallback action;
//   final bool isLoading;
//   final Widget label;
//   final ButtonType type;
//   final double? width;
//   final double? height;
//   final Color? textColor;
//   // final ButtonSize size;
//   const RishButton({
//     Key? key,
//     required this.action,
//     required this.isLoading,
//     required this.label,
//     required this.type,
//     this.textColor,
//     // required this.size,
//     this.height,
//     this.width,
//   }) : super(key: key);

//   // (double height, double width) resolveSize(size, type) {
//   //   switch (type) {
//   //     case ButtonType.primary:
//   //       if (size == ButtonSize.s) {
//   //         return (0, 0);
//   //       }
//   //     case ButtonType.secondary:
//   //       break;
//   //     case ButtonType.teritary:
//   //       break;
//   //     default:
//   //   }
//   // }

//   @override
//   Widget build(BuildContext context) {
//     switch (type) {
//       case ButtonType.primary:
//         return SizedBox(
//           height: height ?? 40,
//           width: width ?? double.infinity,
//           child: ElevatedButton(
//             onPressed: action,
//             child: label,
//           ),
//         );
//       case ButtonType.secondary:
//         return SizedBox(
//           height: height ?? 40,
//           width: width ?? double.infinity,
//           child: OutlinedButton(
//             onPressed: action,
//             // style: ButtonStyle(
//             //     ),
//             child:
//                 label.runtimeType == Text ? Text((label as Text).data!) : label,
//           ),
//         );
//       case ButtonType.teritary:
//         return TextButton(
//           onPressed: action,
//           style: ButtonStyle(
//               tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//               padding: const WidgetStatePropertyAll(EdgeInsets.zero),
//               textStyle: label.runtimeType == Text
//                   ? WidgetStatePropertyAll((label as Text)
//                       .style!
//                       .copyWith(color: textColor ?? darkColorScheme.primary))
//                   : null),
//           child:
//               label.runtimeType == Text ? Text((label as Text).data!) : label,
//         );
//       case ButtonType.disabled:
//         return SizedBox(
//           height: height ?? 40,
//           width: width ?? double.infinity,
//           child: ElevatedButton(
//             onPressed: null,
//             style: ButtonStyle(
//               textStyle: label.runtimeType == Text
//                   ? WidgetStatePropertyAll((label as Text).style!)
//                   : null,
//               backgroundColor: const WidgetStatePropertyAll(RishColors.stroke),
//               side: const WidgetStatePropertyAll(BorderSide.none),
//               foregroundColor:
//                   const WidgetStatePropertyAll(RishColors.inputField),
//             ),
//             child:
//                 label.runtimeType == Text ? Text((label as Text).data!) : label,
//           ),
//         );
//       default:
//         return Container(
//           color: Colors.amber,
//         );
//     }
//   }
// }
