import 'package:intl/intl.dart';

String formatPrice(num value) {
  final formatter = NumberFormat.decimalPattern('vi_VN');
  return '${formatter.format(value)} VND';
}
