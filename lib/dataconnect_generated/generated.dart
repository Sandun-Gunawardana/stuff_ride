library dataconnect_generated;
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

part 'create_user.dart';

part 'create_listing.dart';

part 'list_open_listings.dart';

part 'delete_bid.dart';







class ExampleConnector {
  
  
  CreateUserVariablesBuilder createUser ({required String displayName, required String email, required double rating, }) {
    return CreateUserVariablesBuilder(dataConnect, displayName: displayName,email: email,rating: rating,);
  }
  
  
  CreateListingVariablesBuilder createListing ({required String title, required String pickupLocation, required String dropoffLocation, required String status, required String creatorId, }) {
    return CreateListingVariablesBuilder(dataConnect, title: title,pickupLocation: pickupLocation,dropoffLocation: dropoffLocation,status: status,creatorId: creatorId,);
  }
  
  
  ListOpenListingsVariablesBuilder listOpenListings () {
    return ListOpenListingsVariablesBuilder(dataConnect, );
  }
  
  
  DeleteBidVariablesBuilder deleteBid ({required String id, }) {
    return DeleteBidVariablesBuilder(dataConnect, id: id,);
  }
  

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'asia-east1',
    'example',
    'stuffride',
  );

  ExampleConnector({required this.dataConnect});
  static ExampleConnector get instance {
    
    CacheSettings cacheSettings = CacheSettings(
      maxAge: Duration(milliseconds:0),
      storage: CacheStorage.persistent,
    );
    
    return ExampleConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
            connectorConfig: connectorConfig,
            
            cacheSettings: cacheSettings,
            
            sdkType: CallerSDKType.generated));
  }

  FirebaseDataConnect dataConnect;
}
