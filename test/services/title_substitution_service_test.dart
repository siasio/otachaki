import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:otachaki/services/title_substitution_service.dart';
import 'package:otachaki/models/custom_dataset.dart';
import 'package:otachaki/models/dataset_type.dart';
import 'package:otachaki/models/dataset_configuration.dart';

void main() {
  group('TitleSubstitutionService', () {
    test('should have correct help text with only supported placeholders', () {
      const expectedHelpText = 'Available placeholders:\n'
          '%d - Current dataset name\n'
          '%n - Problems solved today\n'
          '%a - Today\'s accuracy percentage';

      expect(TitleSubstitutionService.helpText, expectedHelpText);
    });
  });
}