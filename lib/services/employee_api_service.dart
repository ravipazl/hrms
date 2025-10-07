import 'package:dio/dio.dart';
import '../widgets/dialogs/node_edit_dialog.dart';

class EmployeeApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  final Dio _dio = Dio();

  /// Load employees list from API
  Future<List<Employee>> loadEmployees() async {
    try {
      final response = await _dio.get('$baseUrl/employees-list/');
      
      if (response.statusCode == 200) {
        final List<dynamic> employeesData = response.data['employees'] ?? [];
        
        return employeesData.map((json) => Employee.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load employees: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading employees: $e');
      throw Exception('Failed to load employees: $e');
    }
  }
}
