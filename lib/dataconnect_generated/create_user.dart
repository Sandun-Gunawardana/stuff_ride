part of 'generated.dart';

class CreateUserVariablesBuilder {
  String displayName;
  String email;
  double rating;
  Optional<String> _phoneNumber = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _vehicleDescription = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  CreateUserVariablesBuilder phoneNumber(String? t) {
   _phoneNumber.value = t;
   return this;
  }
  CreateUserVariablesBuilder vehicleDescription(String? t) {
   _vehicleDescription.value = t;
   return this;
  }

  CreateUserVariablesBuilder(this._dataConnect, {required  this.displayName,required  this.email,required  this.rating,});
  Deserializer<CreateUserData> dataDeserializer = (dynamic json)  => CreateUserData.fromJson(jsonDecode(json));
  Serializer<CreateUserVariables> varsSerializer = (CreateUserVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateUserData, CreateUserVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateUserData, CreateUserVariables> ref() {
    CreateUserVariables vars= CreateUserVariables(displayName: displayName,email: email,rating: rating,phoneNumber: _phoneNumber,vehicleDescription: _vehicleDescription,);
    return _dataConnect.mutation("CreateUser", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateUserUserInsert {
  final String id;
  CreateUserUserInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateUserUserInsert otherTyped = other as CreateUserUserInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateUserUserInsert({
    required this.id,
  });
}

@immutable
class CreateUserData {
  final CreateUserUserInsert user_insert;
  CreateUserData.fromJson(dynamic json):
  
  user_insert = CreateUserUserInsert.fromJson(json['user_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateUserData otherTyped = other as CreateUserData;
    return user_insert == otherTyped.user_insert;
    
  }
  @override
  int get hashCode => user_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['user_insert'] = user_insert.toJson();
    return json;
  }

  CreateUserData({
    required this.user_insert,
  });
}

@immutable
class CreateUserVariables {
  final String displayName;
  final String email;
  final double rating;
  late final Optional<String>phoneNumber;
  late final Optional<String>vehicleDescription;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateUserVariables.fromJson(Map<String, dynamic> json):
  
  displayName = nativeFromJson<String>(json['displayName']),
  email = nativeFromJson<String>(json['email']),
  rating = nativeFromJson<double>(json['rating']) {
  
  
  
  
  
    phoneNumber = Optional.optional(nativeFromJson, nativeToJson);
    phoneNumber.value = json['phoneNumber'] == null ? null : nativeFromJson<String>(json['phoneNumber']);
  
  
    vehicleDescription = Optional.optional(nativeFromJson, nativeToJson);
    vehicleDescription.value = json['vehicleDescription'] == null ? null : nativeFromJson<String>(json['vehicleDescription']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateUserVariables otherTyped = other as CreateUserVariables;
    return displayName == otherTyped.displayName && 
    email == otherTyped.email && 
    rating == otherTyped.rating && 
    phoneNumber == otherTyped.phoneNumber && 
    vehicleDescription == otherTyped.vehicleDescription;
    
  }
  @override
  int get hashCode => Object.hashAll([displayName.hashCode, email.hashCode, rating.hashCode, phoneNumber.hashCode, vehicleDescription.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['displayName'] = nativeToJson<String>(displayName);
    json['email'] = nativeToJson<String>(email);
    json['rating'] = nativeToJson<double>(rating);
    if(phoneNumber.state == OptionalState.set) {
      json['phoneNumber'] = phoneNumber.toJson();
    }
    if(vehicleDescription.state == OptionalState.set) {
      json['vehicleDescription'] = vehicleDescription.toJson();
    }
    return json;
  }

  CreateUserVariables({
    required this.displayName,
    required this.email,
    required this.rating,
    required this.phoneNumber,
    required this.vehicleDescription,
  });
}

