// config/constants.dart
class AppConstants {
  // Tên ứng dụng
  static const String appName = 'Xăng Dầu App';

  // Các loại xăng dầu
  static const List<String> fuelTypes = [
    'RON95-III',
    'RON95-II',
    'E5 RON92-II',
    'DO 0,001S-V', 
    'DO 0,05S-II'
  ];
  
  // Các loại dịch vụ
  static const List<String> serviceTypes = [
    'Rửa xe',
    'Thay nhớt',
    'Bơm lốp',
    'Cửa hàng tiện lợi',
    'Trạm sạc điện',
    'Bảo dưỡng xe',
    'Wifi miễn phí',
    'Nhà vệ sinh'
  ];

  static const List<String> gasStationServices = [
    'Rửa xe',
    'Sửa xe',
    'Cửa hàng tiện lợi',
    'Thay dầu',
    'Bơm khí',
    'Trạm sạc điện',
    'Bảo dưỡng xe',
    'Cafe',
    'Nhà vệ sinh',
  ];
  
  // Các thành phố
  static const List<String> citiesList = [
    'Hà Nội',
    'Hồ Chí Minh',
    'Đà Nẵng',
    'Hải Phòng',
    'Cần Thơ',
    'Biên Hòa',
    'Nha Trang',
    'Huế',
    'Buôn Ma Thuột',
    'Vinh',
    'Quy Nhơn',
    'Thái Nguyên',
    'Nam Định',
    'Vũng Tàu',
    'Hạ Long',
    'Thái Bình',
    'Thanh Hóa',
    'Hải Dương',
    'Long Xuyên',
    'Cà Mau'
  ];
  
  // Phương thức thanh toán
  static const List<String> paymentMethods = ['Tiền mặt', 'Thẻ ngân hàng', 'Ví điện tử'];
  
  // Trạng thái đơn hàng
  static const Map<String, String> orderStatus = {
    'pending': 'Chờ xử lý',
    'completed': 'Hoàn thành',
    'cancelled': 'Đã hủy'
  };
  
  // Định dạng tiền
  static const String currencySymbol = '₫';
  static const String currencyFormat = '#,###';
  
  // Tỷ lệ tích điểm
  static const int pointsThreshold = 100000; // 100.000 VND
  static const int pointsRate = 5; // 5 điểm cho mỗi 100.000 VND
  
  // Định dạng ngày giờ
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  
  // Assets
  static const String logoImage = 'assets/images/logo.png';
  static const String defaultStationImage = 'assets/images/default_station.png';
  static const String emptyImage = 'assets/images/emty.avif';
  
  // Shared Preferences Keys
  static const String userIdKey = 'userId';
  static const String userRoleKey = 'userRole';
  
  // API Error Messages
  static const String connectionError = 'Lỗi kết nối đến máy chủ. Vui lòng thử lại sau.';
  static const String authError = 'Tài khoản hoặc mật khẩu không chính xác.';
  static const String generalError = 'Có lỗi xảy ra. Vui lòng thử lại sau.';
}