import 'package:mysql1/mysql1.dart';

class SQL
{
  MySqlConnection? conn;
  void Function()? onConnection;
  void Function(Results result)? onResult;

  Future<void> connectToDB() async
  {
    ConnectionSettings settings = new ConnectionSettings(
        host: 'localhost',
        port: 3306,
        user: 'root',
        password: '123456',
        db: 'rc'
    );
    conn = await MySqlConnection.connect(settings);
    onConnection!();
  }

  Future<void> sendQuery(String query) async
  {
    Results result = await conn!.query(query);
    onResult!(result);
  }

}