// Test fixtures and sample data for the test suite.

class TestFixtures {
  TestFixtures._();

  static Map<String, dynamic> get userJson => {
        'id': 'user_1',
        'email': 'jane@example.com',
        'name': 'Jane Doe',
        'avatar': null,
        'phone': null,
        'emailVerified': true,
      };

  static Map<String, dynamic> get sessionJson => {
        'accessToken': 'access-abc',
        'refreshToken': 'refresh-abc',
        'user': userJson,
      };

  static Map<String, dynamic> get apiErrorJson => {
        'message': 'Invalid credentials',
        'errors': {
          'email': ['Email is invalid'],
        },
      };
}
