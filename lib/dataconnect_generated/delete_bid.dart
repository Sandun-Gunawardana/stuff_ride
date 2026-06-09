part of 'generated.dart';

class DeleteBidVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  DeleteBidVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<DeleteBidData> dataDeserializer = (dynamic json)  => DeleteBidData.fromJson(jsonDecode(json));
  Serializer<DeleteBidVariables> varsSerializer = (DeleteBidVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteBidData, DeleteBidVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteBidData, DeleteBidVariables> ref() {
    DeleteBidVariables vars= DeleteBidVariables(id: id,);
    return _dataConnect.mutation("DeleteBid", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteBidBidDelete {
  final String id;
  DeleteBidBidDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteBidBidDelete otherTyped = other as DeleteBidBidDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteBidBidDelete({
    required this.id,
  });
}

@immutable
class DeleteBidData {
  final DeleteBidBidDelete? bid_delete;
  DeleteBidData.fromJson(dynamic json):
  
  bid_delete = json['bid_delete'] == null ? null : DeleteBidBidDelete.fromJson(json['bid_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteBidData otherTyped = other as DeleteBidData;
    return bid_delete == otherTyped.bid_delete;
    
  }
  @override
  int get hashCode => bid_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (bid_delete != null) {
      json['bid_delete'] = bid_delete!.toJson();
    }
    return json;
  }

  DeleteBidData({
    this.bid_delete,
  });
}

@immutable
class DeleteBidVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteBidVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteBidVariables otherTyped = other as DeleteBidVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteBidVariables({
    required this.id,
  });
}

