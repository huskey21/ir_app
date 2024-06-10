import 'package:mysql1/mysql1.dart';

class SQL
{
  MySqlConnection? conn;
  void Function()? onConnection;
  void Function(Results result)? onResult;

  Future<void> connectToDB(String host, int port, String user, String password, String dbName) async
  {
    ConnectionSettings settings = new ConnectionSettings(
        host: host,
        port: port,
        user: user,
        password: password,
        db: dbName
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