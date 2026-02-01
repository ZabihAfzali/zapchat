enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  otpSent,
  otpVerified,
  error,
}

extension AuthStatusExtension on AuthStatus {
  bool get isInitial => this == AuthStatus.initial;
  bool get isLoading => this == AuthStatus.loading;
  bool get isAuthenticated => this == AuthStatus.authenticated;
  bool get isUnauthenticated => this == AuthStatus.unauthenticated;
  bool get isOtpSent => this == AuthStatus.otpSent;
  bool get isOtpVerified => this == AuthStatus.otpVerified;
  bool get isError => this == AuthStatus.error;
}