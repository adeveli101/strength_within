library firebase_default;
import 'package:firebase_data_connect/firebase_data_connect.dart';




class DefaultConnector {
  

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'us-central1',
    'firebase_default',
    'workout',
  );

  DefaultConnector({required this.dataConnect});
  static DefaultConnector get instance {
    return DefaultConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
            connectorConfig: connectorConfig,
            sdkType: CallerSDKType.generated));
  }

  FirebaseDataConnect dataConnect;
}

