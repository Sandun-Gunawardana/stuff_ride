part of 'generated.dart';

class CreateListingVariablesBuilder {
  String title;
  String pickupLocation;
  String dropoffLocation;
  String status;
  Optional<double> _priceOffer = Optional.optional(nativeFromJson, nativeToJson);
  String creatorId;

  final FirebaseDataConnect _dataConnect;  CreateListingVariablesBuilder priceOffer(double? t) {
   _priceOffer.value = t;
   return this;
  }

  CreateListingVariablesBuilder(this._dataConnect, {required  this.title,required  this.pickupLocation,required  this.dropoffLocation,required  this.status,required  this.creatorId,});
  Deserializer<CreateListingData> dataDeserializer = (dynamic json)  => CreateListingData.fromJson(jsonDecode(json));
  Serializer<CreateListingVariables> varsSerializer = (CreateListingVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateListingData, CreateListingVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateListingData, CreateListingVariables> ref() {
    CreateListingVariables vars= CreateListingVariables(title: title,pickupLocation: pickupLocation,dropoffLocation: dropoffLocation,status: status,priceOffer: _priceOffer,creatorId: creatorId,);
    return _dataConnect.mutation("CreateListing", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateListingListingInsert {
  final String id;
  CreateListingListingInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateListingListingInsert otherTyped = other as CreateListingListingInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateListingListingInsert({
    required this.id,
  });
}

@immutable
class CreateListingData {
  final CreateListingListingInsert listing_insert;
  CreateListingData.fromJson(dynamic json):
  
  listing_insert = CreateListingListingInsert.fromJson(json['listing_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateListingData otherTyped = other as CreateListingData;
    return listing_insert == otherTyped.listing_insert;
    
  }
  @override
  int get hashCode => listing_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['listing_insert'] = listing_insert.toJson();
    return json;
  }

  CreateListingData({
    required this.listing_insert,
  });
}

@immutable
class CreateListingVariables {
  final String title;
  final String pickupLocation;
  final String dropoffLocation;
  final String status;
  late final Optional<double>priceOffer;
  final String creatorId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateListingVariables.fromJson(Map<String, dynamic> json):
  
  title = nativeFromJson<String>(json['title']),
  pickupLocation = nativeFromJson<String>(json['pickupLocation']),
  dropoffLocation = nativeFromJson<String>(json['dropoffLocation']),
  status = nativeFromJson<String>(json['status']),
  creatorId = nativeFromJson<String>(json['creatorId']) {
  
  
  
  
  
  
    priceOffer = Optional.optional(nativeFromJson, nativeToJson);
    priceOffer.value = json['priceOffer'] == null ? null : nativeFromJson<double>(json['priceOffer']);
  
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateListingVariables otherTyped = other as CreateListingVariables;
    return title == otherTyped.title && 
    pickupLocation == otherTyped.pickupLocation && 
    dropoffLocation == otherTyped.dropoffLocation && 
    status == otherTyped.status && 
    priceOffer == otherTyped.priceOffer && 
    creatorId == otherTyped.creatorId;
    
  }
  @override
  int get hashCode => Object.hashAll([title.hashCode, pickupLocation.hashCode, dropoffLocation.hashCode, status.hashCode, priceOffer.hashCode, creatorId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['title'] = nativeToJson<String>(title);
    json['pickupLocation'] = nativeToJson<String>(pickupLocation);
    json['dropoffLocation'] = nativeToJson<String>(dropoffLocation);
    json['status'] = nativeToJson<String>(status);
    if(priceOffer.state == OptionalState.set) {
      json['priceOffer'] = priceOffer.toJson();
    }
    json['creatorId'] = nativeToJson<String>(creatorId);
    return json;
  }

  CreateListingVariables({
    required this.title,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.status,
    required this.priceOffer,
    required this.creatorId,
  });
}

