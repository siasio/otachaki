#!/usr/bin/env dart

import 'dart:io';

/// Comprehensive test runner for Go Training App
/// Provides organized test execution by category with parallel support
class TestRunner {
  static const Map<String, List<String>> testCategories = {
    'models': [
      'test/models/dataset_configuration_test.dart',
      'test/models/training_state_test.dart',
      'test/models/global_configuration_test.dart',
      'test/models/training_position_position_type_test.dart',
      'test/models/training_position_ownership_test.dart',
      'test/models/auto_advance_mode_test.dart',
      'test/models/button_state_manager_test.dart',
      'test/models/daily_statistics_test.dart',
      'test/models/problem_attempt_test.dart',
      'test/models/custom_dataset_test.dart',
      'test/models/board_view_mode_test.dart',
      'test/models/ownership_display_mode_test.dart',
      'test/models/territory_display_test.dart',
    ],
    'services': [
      'test/services/training_state_manager_test.dart',
      'test/services/statistics_manager_test.dart',
      'test/services/training_timer_manager_test.dart',
      'test/services/position_loader_test.dart',
      'test/services/unified_dataset_manager_test.dart',
      'test/services/custom_dataset_manager_test.dart',
    ],
    'core': [
      'test/core/go_logic_test.dart',
      'test/core/game_result_parser_test.dart',
      'test/core/dataset_parser_test.dart',
      'test/core/go_logic_ownership_test.dart',
      'test/core/position_scoring_test.dart',
    ],
    'widgets': [
      'test/widgets/adaptive_layout_test.dart',
      'test/widgets/pause_button_test.dart',
      'test/widgets/score_display_buttons_test.dart',
      'test/widgets/adaptive_result_buttons_test.dart',
      'test/widgets/timer_bar_test.dart',
    ],
    'themes': [
      'test/themes/element_registry_test.dart',
      'test/themes/unified_theme_provider_test.dart',
      'test/themes/app_theme_test.dart',
      'test/themes/style_definitions_test.dart',
    ],
    'integration': [
      'test/integration/auto_advance_dataset_independence_test.dart',
      'test/integration/configuration_independence_test.dart',
      'test/integration/custom_dataset_ui_test.dart',
      'test/integration/race_condition_fix_test.dart',
      'test/integration/app_integration_test.dart',
      'test/integration/training_screen_configuration_test.dart',
      'test/integration/app_basic_test.dart',
    ],
  };

  static void printUsage() {
    print('Flutter Test Runner for Go Training App');
    print('');
    print('Usage: dart scripts/test_runner.dart [options] [category]');
    print('');
    print('Categories:');
    for (final category in testCategories.keys) {
      final count = testCategories[category]!.length;
      print('  $category ($count files)');
    }
    print('');
    print('Options:');
    print('  --all              Run all tests');
    print('  --parallel         Run categories in parallel');
    print('  --coverage         Generate coverage report');
    print('  --help             Show this help message');
    print('');
    print('Examples:');
    print('  dart scripts/test_runner.dart models');
    print('  dart scripts/test_runner.dart --all');
    print('  dart scripts/test_runner.dart --parallel');
    print('  dart scripts/test_runner.dart --coverage models');
  }

  static Future<void> runCategory(String category, {bool coverage = false}) async {
    final tests = testCategories[category];
    if (tests == null) {
      print('❌ Unknown category: $category');
      return;
    }

    print('🧪 Running $category tests (${tests.length} files)...');

    final args = ['test'];
    if (coverage) {
      args.add('--coverage');
    }
    args.addAll(tests);

    final result = await Process.run('flutter', args);

    if (result.exitCode == 0) {
      print('✅ $category tests passed');
    } else {
      print('❌ $category tests failed');
      print(result.stdout);
      print(result.stderr);
    }
  }

  static Future<void> runAllTests({bool parallel = false, bool coverage = false}) async {
    if (parallel) {
      print('🚀 Running all test categories in parallel...');
      final futures = testCategories.keys.map(
        (category) => runCategory(category, coverage: coverage)
      );
      await Future.wait(futures);
    } else {
      print('🧪 Running all test categories sequentially...');
      for (final category in testCategories.keys) {
        await runCategory(category, coverage: coverage);
      }
    }
  }

  static Future<void> main(List<String> args) async {
    if (args.isEmpty || args.contains('--help')) {
      printUsage();
      return;
    }

    final parallel = args.contains('--parallel');
    final coverage = args.contains('--coverage');
    final runAll = args.contains('--all');

    if (runAll) {
      await runAllTests(parallel: parallel, coverage: coverage);
    } else {
      // Find non-flag arguments
      final categories = args.where((arg) => !arg.startsWith('--')).toList();

      if (categories.isEmpty) {
        print('❌ No category specified');
        printUsage();
        return;
      }

      for (final category in categories) {
        await runCategory(category, coverage: coverage);
      }
    }
  }
}

void main(List<String> args) async {
  await TestRunner.main(args);
}