import 'package:mongo_dart/mongo_dart.dart';

class DatabaseService {
  static const String CONNECTION_STRING =
      'mongodb+srv://caoman26:qCDssznMeLo7omGH@cluster0.cfmbjpd.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0';
  static const String DB_NAME = 'xangdau_db';
  static final DatabaseService _instance = DatabaseService._internal();
  Db? _db;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<void> connect() async {
    if (_db == null || !_db!.isConnected) {
      try {
        // Sử dụng chuỗi kết nối đơn giản hơn
        print('Đang cố gắng kết nối đến MongoDB...');
        _db = await Db.create(CONNECTION_STRING);
        await _db!.open();
        print('Kết nối MongoDB thành công!');
        
        // Kiểm tra kết nối bằng cách lấy danh sách collection
        final collections = await _db!.getCollectionNames();
        print('Danh sách collection: $collections');
      } catch (e) {
        print('Lỗi kết nối MongoDB: $e');
        rethrow;
      }
    }
  }

  Future<void> close() async {
    if (_db != null && _db!.isConnected) {
      await _db!.close();
    }
  }

  DbCollection collection(String name) {
    if (_db == null || !_db!.isConnected) {
      throw Exception('Database chưa được kết nối');
    }
    return _db!.collection(name);
  }

  // Các collection trong MongoDB
  DbCollection get usersCollection => collection('users');
  DbCollection get gasStationsCollection => collection('gas_stations');
  DbCollection get productsCollection => collection('products');
  DbCollection get ordersCollection => collection('orders');
  DbCollection get reviewsCollection => collection('reviews');
}