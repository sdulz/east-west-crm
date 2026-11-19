import 'package:flutter/material.dart';

import 'package:field_crm/common/model/unique_checker.dart';
import 'package:field_crm/common/utils/uppercase.dart';

typedef ValidatorType = String? Function(String?);

class CustomValidator {
  static final int? fullNameMaxLength = null;
  static final int accountMaxLength = 20;
  static final int homeOfficeNumber = 9;
  static final int mobileMaxLength = 10;
  static final int? passwordMaxLength = null;
  static final int passwordMinLength = 8;

  static int maxLengthComparedTo(num max) {
    return max.toInt().abs().toString().length;
  }

  static ValidatorType validateEmpty(String messageOnEmpty) {
    return (value) {
      value ??= "";
      if (value.trim().isEmpty) {
        return messageOnEmpty;
      }
      return null;
    };
  }

  static ValidatorType validateNumeric([String? heading]) {
    return (value) {
      value ??= "";
      if (value.trim().isEmpty) {
        return "Please enter ${heading ?? "Amount"}";
      } else if (double.tryParse(value.trim()) != null) {
        return null;
      } else {
        return "Please enter valid ${heading ?? "Amount"}";
      }
    };
  }

  static ValidatorType validateMobile(
      [String? heading, List<String>? oldPhones, bool isRequired = true]) {
    heading = heading ?? "Mobile number";
    return (value) {
      String pattern = r'(^[0-9]*$)';
      RegExp regExp = RegExp(pattern);
      value ??= "";
      final isEmpty = value.trim().isEmpty;
      if (isEmpty && !isRequired) {
        return null;
      } else if (isEmpty) {
        return "Please enter $heading";
      } else if (!regExp.hasMatch(value.trim())) {
        return "${heading!.capitalizeFirstLetter} is not valid";
      } else if (value.trim().length != mobileMaxLength) {
        return "${heading!.capitalizeFirstLetter} length must be of $mobileMaxLength digits";
      } else if (!value.trim().startsWith('98') &&
          !value.trim().startsWith('97') &&
          !value.trim().startsWith('96')) {
        return "${heading!.capitalizeFirstLetter} is not valid";
      }
      if (oldPhones != null && oldPhones.contains(value)) {
        return "Contact number must be unique";
      }
      return null;
    };
  }

  static ValidatorType validateMobileNew({
    String? heading,
    UniqueChecker? uniqueChecker,
    bool isRequired = true,
  }) {
    heading = heading ?? "Mobile number";
    return (value) {
      String pattern = r'(^[0-9]*$)';
      RegExp regExp = RegExp(pattern);
      value ??= "";
      final isEmpty = value.trim().isEmpty;
      if (isEmpty && !isRequired) {
        return null;
      } else if (isEmpty) {
        return "Please enter $heading";
      } else if (!regExp.hasMatch(value.trim())) {
        return "${heading!.capitalizeFirstLetter} is not valid";
      } else if (value.trim().length != mobileMaxLength) {
        return "${heading!.capitalizeFirstLetter} length must be of $mobileMaxLength digits";
      } else if (!value.trim().startsWith('98') &&
          !value.trim().startsWith('97') &&
          !value.trim().startsWith('96')) {
        return "${heading!.capitalizeFirstLetter} is not valid";
      }
      if (uniqueChecker?.isRedundant(value) ?? false) {
        return "Contact number must be unique";
      }
      return null;
    };
  }

  static ValidatorType validateHomeNumber() {
    return (value) {
      value ??= "";
      if (value.trim().isEmpty) {
        return "Please enter home/office number";
      } else if (value.trim().isEmpty) {
        return null;
      } else if (value.trim().length != homeOfficeNumber) {
        return "Home/Office number must be $homeOfficeNumber digits long.";
      }
      return null;
    };
  }

  static ValidatorType validatePassword({
    TextEditingController? newPasswordCheckWithOldPassword,
    TextEditingController? confirmPasswordParent,
    required bool isNewPassword,
  }) {
    return (value) {
      value ??= "";
      if (value.trim().isEmpty) {
        return "Please enter password";
      }

      if (confirmPasswordParent != null) {
        if (value != confirmPasswordParent.text) {
          return "Confirm password does not match";
        }
      }

      if (newPasswordCheckWithOldPassword != null) {
        if (newPasswordCheckWithOldPassword.text == value) {
          return "New password cannot be same as old password";
        }
      }

      if (isNewPassword) {
        if (value.length < passwordMinLength) {
          return "Password must be at least $passwordMinLength characters.";
        } else if (!passwordHaveNumberOrSymbol(value)) {
          return "Password must have at least one number or symbol";
        } else if (!passwordHaveLowerCase(value)) {
          return "Password must have at least one lowercase letter";
        } else if (!passwordHaveUpperCase(value)) {
          return "Password must have at least one uppercase letter";
        }
      }

      return null;
    };
  }

  static bool passwordHaveNumberOrSymbol(String value) {
    RegExp regex = RegExp(r'(?=.*[0-9])|(?=.*[!@#\$%^&*()+,.?":{}|<>])');
    return regex.hasMatch(value);
  }

  static bool passwordHaveLowerCase(String value) {
    RegExp regex = RegExp(r'[a-z]');
    return regex.hasMatch(value);
  }

  static bool passwordHaveUpperCase(String value) {
    RegExp regex = RegExp(r'[A-Z]');
    return regex.hasMatch(value);
  }

  static ValidatorType validateFullName([String? alternativeValue]) {
    return (value) {
      value ??= "";
      value = value.trim();
      if (value.isEmpty) {
        if (alternativeValue == null) {
          return "Please enter full name";
        } else {
          return "Please enter $alternativeValue";
        }
      } else if (value.split(" ").length < 2) {
        if (alternativeValue == null) {
          return "Invalid full name";
        } else {
          return "$alternativeValue is not valid";
        }
      }
      return null;
    };
  }

  static ValidatorType validateEmail([bool isRequired = true]) {
    return (value) {
      value ??= "";
      final isEmpty = value.trim().isEmpty;
      if (!isRequired && isEmpty) return null;
      if (isEmpty) {
        return "Please enter email";
      }
      if (value.trim().isEmpty) return null;
      if (!RegExp(
              r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
          .hasMatch(value)) {
        return "Provided email is not valid";
      }
      return null;
    };
  }
}