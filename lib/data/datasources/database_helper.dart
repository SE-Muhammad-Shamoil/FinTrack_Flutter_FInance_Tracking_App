import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finguard.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4, // Upgraded to V4 for seeded Investments
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      // Drop all existing tables to refresh schema
      await db.execute('DROP TABLE IF EXISTS health_scores');
      await db.execute('DROP TABLE IF EXISTS insights');
      await db.execute('DROP TABLE IF EXISTS goals');
      await db.execute('DROP TABLE IF EXISTS budgets');
      await db.execute('DROP TABLE IF EXISTS transactions');
      await db.execute('DROP TABLE IF EXISTS categories');
      await db.execute('DROP TABLE IF EXISTS profiles');
      await db.execute('DROP TABLE IF EXISTS investments');
      await db.execute('DROP TABLE IF EXISTS portfolio_history');
      await _createDB(db, newVersion);
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE profiles (
  id $idType,
  name $textType,
  icon $textType,
  color $textType,
  is_active $intType DEFAULT 0
)
''');

    await db.execute('''
CREATE TABLE categories (
  id $idType,
  profile_id $intType,
  name $textType,
  icon $textType,
  color $textType,
  type $textType,
  keyword_mappings $textType,
  FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE transactions (
  id $idType,
  profile_id $intType,
  sms_body $textType,
  amount $realType,
  merchant $textType,
  category_id $intType,
  date $textType,
  type $textType,
  account_name $textType,
  FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE,
  FOREIGN KEY (category_id) REFERENCES categories (id)
)
''');

    await db.execute('''
CREATE TABLE budgets (
  id $idType,
  profile_id $intType,
  category_id $intType,
  amount $realType,
  month $intType,
  year $intType,
  FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE,
  FOREIGN KEY (category_id) REFERENCES categories (id)
)
''');

    await db.execute('''
CREATE TABLE goals (
  id $idType,
  profile_id $intType,
  name $textType,
  target_amount $realType,
  current_amount $realType,
  target_date $textType,
  color $textType,
  FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE insights (
  id $idType,
  profile_id $intType,
  title $textType,
  description $textType,
  type $textType,
  date_generated $textType,
  FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE health_scores (
  id $idType,
  profile_id $intType,
  score $intType,
  date $textType,
  breakdown_json $textType,
  FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE investments (
  id $idType,
  profile_id $intType,
  ticker $textType,
  name $textType,
  shares $realType,
  current_price $realType,
  asset_class $textType,
  FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE portfolio_history (
  id $idType,
  profile_id $intType,
  date $textType,
  total_value $realType,
  FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE
)
''');

    // Seed default Profile
    await db.execute('''
      INSERT INTO profiles (name, icon, color, is_active) VALUES
      ('Personal', 'person', '#2196F3', 1)
    ''');

    // Seed default Categories (assigned to Profile 1)
    await db.execute('''
      INSERT INTO categories (profile_id, name, icon, color, type, keyword_mappings) VALUES
      (1, 'Food', 'restaurant', '#FF5722', 'expense', '["kfc", "mcdonalds", "foodpanda", "cheezious", "hardees", "dominos", "optp"]'),
      (1, 'Transport', 'directions_car', '#2196F3', 'expense', '["careem", "indrive", "uber", "pso", "shell", "total parco", "byco"]'),
      (1, 'Shopping', 'shopping_bag', '#E91E63', 'expense', '["daraz", "alkaram", "outfitters", "khaadi", "sapphire", "junaid jamshed", "imiaz"]'),
      (1, 'Entertainment', 'movie', '#9C27B0', 'expense', '["netflix", "spotify", "cinema", "cinepax", "joyland"]'),
      (1, 'Bills & Utilities', 'receipt', '#607D8B', 'expense', '["k-electric", "sui gas", "nayatel", "ptcl", "lesco", "kelectric", "ssgc", "sngpl"]'),
      (1, 'Health', 'favorite', '#F44336', 'expense', '["chughtai lab", "shaukat khanum", "agha khan", "pharmacy", "medical"]'),
      (1, 'Income', 'account_balance_wallet', '#4CAF50', 'income', '["salary", "deposit", "credited", "transfer received"]');
    ''');
    // Seed Investments
    await db.execute('''
      INSERT INTO investments (profile_id, ticker, name, shares, current_price, asset_class) VALUES
      (1, 'VTI', 'Vanguard Total Stock Market ETF', 6.25, 162.34, 'US Stocks'),
      (1, 'AAPL', 'Apple Inc.', 2.5, 184.20, 'US Stocks'),
      (1, 'BTC', 'Bitcoin', 0.05, 42000.0, 'Crypto');
    ''');

    // Seed Portfolio History
    await db.execute('''
      INSERT INTO portfolio_history (profile_id, date, total_value) VALUES
      (1, '2023-12-01T00:00:00Z', 1750.0),
      (1, '2024-01-01T00:00:00Z', 1770.0),
      (1, '2024-02-01T00:00:00Z', 1760.0),
      (1, '2024-03-01T00:00:00Z', 1800.0),
      (1, '2024-04-01T00:00:00Z', 1820.0),
      (1, '2024-05-01T00:00:00Z', 1845.56);
    ''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
