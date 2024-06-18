class LoginModel {
  String? status;
  String? firstTimeUser;
  String? message;
  Result? result;

  LoginModel({this.status, this.firstTimeUser, this.message, this.result});

  LoginModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    firstTimeUser = json['first_time_user'];
    message = json['message'];
    result =
    json['result'] != null ? new Result.fromJson(json['result']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['first_time_user'] = this.firstTimeUser;
    data['message'] = this.message;
    if (this.result != null) {
      data['result'] = this.result!.toJson();
    }
    return data;
  }
}

class Result {
  String? token;
  Employeedetails? employeedetails;
  List<String>? permissions;
  int? remark;

  Result({this.token, this.employeedetails, this.permissions, this.remark});

  Result.fromJson(Map<String, dynamic> json) {
    token = json['token'];
    employeedetails = json['employeedetails'] != null
        ? new Employeedetails.fromJson(json['employeedetails'])
        : null;
    permissions = json['permissions'].cast<String>();
    remark = json['remark'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['token'] = this.token;
    if (this.employeedetails != null) {
      data['employeedetails'] = this.employeedetails!.toJson();
    }
    data['permissions'] = this.permissions;
    data['remark'] = this.remark;
    return data;
  }
}

class Employeedetails {
  int? userId;
  String? email;
  String? empCode;
  int? companyId;
  int? clientId;
  int? projectId;
  int? locationId;
  String? firstName;
  String? lastName;
  String? phoneNo;
  String? desgCode;
  String? empDoj;

  Employeedetails(
      {this.userId,
        this.email,
        this.empCode,
        this.companyId,
        this.clientId,
        this.projectId,
        this.locationId,
        this.firstName,
        this.lastName,
        this.phoneNo,
        this.desgCode,
        this.empDoj});

  Employeedetails.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
    email = json['email'];
    empCode = json['emp_code'];
    companyId = json['company_id'];
    clientId = json['client_id'];
    projectId = json['project_id'];
    locationId = json['location_id'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    phoneNo = json['phone_no'];
    desgCode = json['desg_code'];
    empDoj = json['emp_doj'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['user_id'] = this.userId;
    data['email'] = this.email;
    data['emp_code'] = this.empCode;
    data['company_id'] = this.companyId;
    data['client_id'] = this.clientId;
    data['project_id'] = this.projectId;
    data['location_id'] = this.locationId;
    data['first_name'] = this.firstName;
    data['last_name'] = this.lastName;
    data['phone_no'] = this.phoneNo;
    data['desg_code'] = this.desgCode;
    data['emp_doj'] = this.empDoj;
    return data;
  }
}
