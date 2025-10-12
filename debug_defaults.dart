import 'lib/models/dataset_configuration.dart';
import 'lib/models/dataset_type.dart';
import 'lib/models/auto_advance_mode.dart';

void main() {
  print('Dataset Type Auto-Advance Defaults:');
  for (final type in DatasetType.values) {
    final config = DatasetConfiguration.getDefaultFor(type);
    print('${type.value}: ${config.autoAdvanceMode}');
  }
}