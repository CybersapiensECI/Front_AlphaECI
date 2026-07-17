import 'package:dio/dio.dart';

import '../../domain/entities/registration_data.dart';
import '../models/auth_models.dart';

/// Llamadas HTTP crudas a identity-service. Sin lógica de negocio,
/// sin manejo de errores (eso es del repository).
class AuthApiService {
  const AuthApiService(this._dio);

  final Dio _dio;

  static const _base = '/api/v1/auth';

  Future<LoginResponseModel> login(String email, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/login',
      data: {'email': email, 'password': password},
    );
    return LoginResponseModel.fromJson(response.data!);
  }

  Future<MessageResponseModel> initVerification(
    String email,
    String password,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/init-verification',
      data: {'email': email, 'password': password},
    );
    return MessageResponseModel.fromJson(response.data ?? const {});
  }

  Future<LoginResponseModel> verifyOtp(String email, String code) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/verify-otp',
      data: {'email': email, 'code': code},
    );
    return LoginResponseModel.fromJson(response.data!);
  }

  Future<MessageResponseModel> resendOtp(String email, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/resend-otp',
      data: {'email': email, 'password': password},
    );
    return MessageResponseModel.fromJson(response.data ?? const {});
  }

  Future<MessageResponseModel> completeRegistration(
    RegistrationData data,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/complete-registration',
      data: registrationDataToJson(data),
    );
    return MessageResponseModel.fromJson(response.data ?? const {});
  }

  Future<MessageResponseModel> forgotPassword(String email) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/forgot-password',
      data: {'email': email},
    );
    return MessageResponseModel.fromJson(response.data ?? const {});
  }

  Future<MessageResponseModel> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/reset-password',
      data: {'email': email, 'code': code, 'newPassword': newPassword},
    );
    return MessageResponseModel.fromJson(response.data ?? const {});
  }

  Future<MessageResponseModel> changePassword(
    String userId,
    String currentPassword,
    String newPassword,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/change-password',
      data: {
        'userId': userId,
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
    return MessageResponseModel.fromJson(response.data ?? const {});
  }

  Future<void> logout(String refreshToken) async {
    await _dio.post<void>(
      '$_base/logout',
      data: {'refreshToken': refreshToken},
    );
  }
}
