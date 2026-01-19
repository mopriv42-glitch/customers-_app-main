class PriceCalculationService {
  /// حساب سعر الحجز وفقاً للقواعد المحددة
  ///
  /// [educationId] - معرف المرحلة التعليمية (1: ابتدائي، 2: متوسط، 3: ثانوي، 4: جامعي)
  /// [numberOfHours] - عدد الساعات (1.5 أو 2)
  /// [grade] - معرف الصف (مهم للمرحلة التطبيقية)
  ///
  /// Returns: السعر بالدينار الكويتي
  static int calculateOrderPrice(
      int educationId, double numberOfHours, int grade) {
    // التأكد من أن عدد الساعات صحيح
    if (numberOfHours < 1.5) {
      numberOfHours = 1.5;
    }

    // تقريب عدد الساعات إلى 1.5 أو 2
    if (numberOfHours > 1.5 && numberOfHours < 2) {
      numberOfHours = 2.0;
    } else if (numberOfHours <= 1.5) {
      numberOfHours = 1.5;
    }

    double price = 0;

    // المرحلة الابتدائية (الصفوف 1 - 5)
    if (grade >= 1 && grade <= 5) {
      price = (numberOfHours == 1.5) ? 15.0 : 18.0;
    }
    // المرحلة المتوسطة (الصفوف 6 - 9)
    else if (grade >= 6 && grade <= 9) {
      price = (numberOfHours == 1.5) ? 18.0 : 20.0;
    }
    // المرحلة الثانوية (الصفوف 10 - 11)
    else if (grade >= 10 && grade <= 11) {
      price = (numberOfHours == 1.5) ? 22.0 : 27.0;
    }
    // المرحلة الثانوية (الصف 12)
    else if (grade == 12) {
      price = (numberOfHours == 1.5) ? 25.0 : 30.0;
    }
    // المرحلة التطبيقية (الصف 27)
    else if (grade == 27) {
      price = (numberOfHours == 1.5) ? 20.0 : 25.0;
    }
    // المرحلة الجامعية (educationId == 4)
    else if (educationId == 4) {
      price = (numberOfHours == 1.5) ? 30.0 : 40.0;
    }

    return price.toInt();
  }

  /// تنسيق عرض السعر
  static String formatPrice(int price) {
    return '$price د.ك';
  }

  /// الحصول على نص عدد الساعات
  static String getHoursText(double hours) {
    if (hours == 1.5) {
      return 'ساعة ونصف';
    } else if (hours == 2.0) {
      return 'ساعتين';
    } else {
      return '$hours ساعة';
    }
  }
}
