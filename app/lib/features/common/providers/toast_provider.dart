import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ToastType { success, error, warning, info }

class ToastModel {
  final String id;
  final String message;
  final ToastType type;
  final DateTime timestamp;

  ToastModel({
    required this.id,
    required this.message,
    required this.type,
    required this.timestamp,
  });
}

class ToastNotifier extends StateNotifier<List<ToastModel>> {
  ToastNotifier() : super([]);

  void showToast(String message, ToastType type) {
    final toast = ToastModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      type: type,
      timestamp: DateTime.now(),
    );
    
    state = [...state, toast];
    
    // Auto remove after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      removeToast(toast.id);
    });
  }

  void removeToast(String id) {
    state = state.where((toast) => toast.id != id).toList();
  }

  void clearAll() {
    state = [];
  }
}

final toastProvider = StateNotifierProvider<ToastNotifier, List<ToastModel>>((ref) {
  return ToastNotifier();
});