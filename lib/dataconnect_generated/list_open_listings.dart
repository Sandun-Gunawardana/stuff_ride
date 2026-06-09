part of 'generated.dart';

class ListOpenListingsVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListOpenListingsVariablesBuilder(this._dataConnect, );
  Deserializer<ListOpenListingsData> dataDeserializer = (dynamic json)  => ListOpenListingsData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListOpenListingsData, void>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<ListOpenListingsData, void> ref() {
    
    return _dataConnect.query("ListOpenListings", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListOpenListingsListings {
  final String id;
  final String title;
  final String pickupLocation;
  final String dropoffLocation;
  final double? priceOffer;
  final ListOpenListingsListingsCreator creator;
  ListOpenListingsListings.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  title = nativeFromJson<String>(json['title']),
  pickupLocation = nativeFromJson<String>(json['pickupLocation']),
  dropoffLocation = nativeFromJson<String>(json['dropoffLocation']),
  priceOffer = json['priceOffer'] == null ? null : nativeFromJson<double>(json['priceOffer']),
  creator = ListOpenListingsListingsCreator.fromJson(json['creator']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListOpenListingsListings otherTyped = other as ListOpenListingsListings;
    return id == otherTyped.id && 
    title == otherTyped.title && 
    pickupLocation == otherTyped.pickupLocation && 
    dropoffLocation == otherTyped.dropoffLocation && 
    priceOffer == otherTyped.priceOffer && 
    creator == otherTyped.creator;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, title.hashCode, pickupLocation.hashCode, dropoffLocation.hashCode, priceOffer.hashCode, creator.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['title'] = nativeToJson<String>(title);
    json['pickupLocation'] = nativeToJson<String>(pickupLocation);
    json['dropoffLocation'] = nativeToJson<String>(dropoffLocation);
    if (priceOffer != null) {
      json['priceOffer'] = nativeToJson<double?>(priceOffer);
    }
    json['creator'] = creator.toJson();
    return json;
  }

  ListOpenListingsListings({
    required this.id,
    required this.title,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.priceOffer,
    required this.creator,
  });
}

@immutable
class ListOpenListingsListingsCreator {
  final String displayName;
  ListOpenListingsListingsCreator.fromJson(dynamic json):
  
  displayName = nativeFromJson<String>(json['displayName']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListOpenListingsListingsCreator otherTyped = other as ListOpenListingsListingsCreator;
    return displayName == otherTyped.displayName;
    
  }
  @override
  int get hashCode => displayName.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['displayName'] = nativeToJson<String>(displayName);
    return json;
  }

  ListOpenListingsListingsCreator({
    required this.displayName,
  });
}

@immutable
class ListOpenListingsData {
  final List<ListOpenListingsListings> listings;
  ListOpenListingsData.fromJson(dynamic json):
  
  listings = (json['listings'] as List<dynamic>)
        .map((e) => ListOpenListingsListings.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListOpenListingsData otherTyped = other as ListOpenListingsData;
    return listings == otherTyped.listings;
    
  }
  @override
  int get hashCode => listings.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['listings'] = listings.map((e) => e.toJson()).toList();
    return json;
  }

  ListOpenListingsData({
    required this.listings,
  });
}

