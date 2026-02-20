import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_application/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sign_application/features/auth/presentation/bloc/auth_event.dart';

Future<T> handleDioRequest<T>(BuildContext context, Future<T> Function() request) async {
  try {
    return await request();
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      if (context.mounted) {
        context.read<AuthBloc>().add(LogoutRequested());
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
      throw Exception('Session expirée, veuillez vous reconnecter');
    }
    rethrow;
  }
}