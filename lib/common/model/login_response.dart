class LoginResponse {
  final String token;
  final String refreshToken;
  final String message;
  final DateTime expiresAt;
  final Map<String, dynamic>? user;

  LoginResponse({
    required this.token,
    required this.refreshToken,
    required this.message,
    required this.expiresAt,
    this.user,
  });

  factory LoginResponse.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? fallbackUser,
  }) {
    final data = json["data"] is Map
        ? Map<String, dynamic>.from(json["data"] as Map)
        : json;
    final rawUser = data["user"] ?? json["user"];
    return LoginResponse(
      token: (data["token"] ?? json["token"] ?? "").toString(),
      refreshToken:
          (data["refresh_token"] ??
                  data["refreshToken"] ??
                  json["refresh_token"] ??
                  json["refreshToken"] ??
                  "")
              .toString(),
      message: (json["message"] ?? "Success").toString(),
      expiresAt:
          DateTime.tryParse(
            (data["expires_at"] ??
                    data["expiresAt"] ??
                    json["expires_at"] ??
                    json["expiresAt"] ??
                    "")
                .toString(),
          ) ??
          DateTime.now().add(const Duration(hours: 24)),
      user: rawUser is Map
          ? Map<String, dynamic>.from(rawUser)
          : fallbackUser,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "message": message,
      "data": {
        "token": token,
        "refresh_token": refreshToken,
        "refreshToken": refreshToken,
        "expires_at": expiresAt.toIso8601String(),
        "expiresAt": expiresAt.toIso8601String(),
        if (user != null) "user": user,
      },
      "token": token,
      "refresh_token": refreshToken,
      "refreshToken": refreshToken,
      "expires_at": expiresAt.toIso8601String(),
      "expiresAt": expiresAt.toIso8601String(),
      if (user != null) "user": user,
    };
  }

  Map<String, dynamic> toRefreshJson() {
    return {"token": refreshToken};
  }

  bool get isNotExpired => expiresAt.isAfter(DateTime.now());

  Duration get durationRemainingToExpire {
    final duration = expiresAt.difference(DateTime.now());
    return duration.isNegative ? Duration.zero : duration;
  }
}
