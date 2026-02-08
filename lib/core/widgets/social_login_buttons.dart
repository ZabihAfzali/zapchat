// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_svg/flutter_svg.dart';
//
// class SocialLoginButton extends StatelessWidget {
//   final String text;
//   final String image;
//   final VoidCallback onTap;
//
//   const SocialLoginButton({
//     super.key,
//     required this.text,
//     required this.image,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         height: 48,
//         width: double.infinity,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(6),
//           border: Border.all(color: Colors.black),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             SvgPicture.asset(
//               image,
//               height: 20.h,
//               width: 20.w,
//             ),
//             const SizedBox(width: 8),
//             Text(
//               text,
//               style: const TextStyle(fontWeight: FontWeight.w600),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DefaultButton extends StatelessWidget {
  final String title;
  final String? image;
  final Color buttonColor;
  final Color buttonTextColor;
  final VoidCallback onPressed;
  const DefaultButton({
    Key? key,
    required this.title,
    required this.onPressed,
    required this.buttonColor,
    required this.buttonTextColor,
    this.image,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:onPressed,
      child: Container(
        width: double.infinity,
        height:45.h,
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child:Padding(
          padding:  EdgeInsets.only(left:10.r,right: 10.r),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                image.toString(),
                height:40.h,
                width:40.w ,
              ),
              SizedBox(width: 20.w,),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16.sp,
                  fontFamily: 'Inter',
                  color: buttonTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
