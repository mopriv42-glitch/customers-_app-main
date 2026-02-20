// import 'dart:math';
//
// import 'package:flutter/material.dart';
// import 'package:flutter_upayments/flutter_upayments.dart';
// import 'package:private_4t_app/app_config/api_providers.dart';
// import 'package:private_4t_app/core/models/customer_booking_modal.dart';
// import 'package:riverpod_context/riverpod_context.dart';
//
// class UPaymentProvider extends ChangeNotifier {
//   Future<paymentDetails?> initPayment(
//       BuildContext context, CustomerBooking booking) async {
//     try {
//       final loggedUser = context.read(ApiProviders.loginProvider).loggedUser;
//       var totalPrice = (booking.price ?? 10) + 0.25;
//       final userData = paymentDetails(
//         apiKey: "a2180885d73c48fbc219092a6b3ea8b58ade6e4e",
//         totalPrice: totalPrice.toString(),
//         currencyCode: "KWD",
//         successUrl:
//             "https://new.private-4t.com/payment/knet/success/booking/${booking.id}",
//         errorUrl: "https://new.private-4t.com/payment/knet/success/booking",
//         testMode: "1",
//         customerFName: loggedUser?.name ?? '',
//         customerEmail: loggedUser?.email ?? '',
//         customerMobile: "+965${loggedUser?.phone}",
//         paymentGateway: "knet",
//         whitelabled: "true",
//         productTitle: "حجز حصة",
//         productName: "حصة ${booking.subject?.subject} ${booking.grade?.grade}",
//         productPrice: (totalPrice - 0.25).toString(),
//         productQty: "1",
//         reference: "mobile_${loggedUser?.id}_${DateTime.now().hashCode}",
//         notifyURL: "https://new.private-4t.com/payment/knet/notification",
//       );
//
//       return userData;
//     } catch (e) {
//       debugPrint("Error during init payment => $e");
//       return null;
//     }
//   }
// }
