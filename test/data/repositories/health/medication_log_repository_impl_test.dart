import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vitalsync/core/enums/medication_frequency.dart';
import 'package:vitalsync/core/enums/medication_log_status.dart';
import 'package:vitalsync/domain/entities/health/medication.dart';
import 'package:vitalsync/domain/repositories/health/medication_log_repository.dart';
import 'package:vitalsync/domain/repositories/health/medication_repository.dart';

class MockMedicationRepository extends Mock implements MedicationRepository {}

class MockMedicationLogRepository extends Mock
    implements MedicationLogRepository {}

void main() {
  late MockMedicationRepository mockMedRepo;
  late MockMedicationLogRepository mockLogRepo;

  final now = DateTime.now();

  final testMedication = Medication(
    id: 1,
    name: 'Aspirin',
    dosage: '100mg',
    frequency: MedicationFrequency.daily,
    times: ['08:00', '20:00'],
    startDate: DateTime(2024, 1, 1),
    color: 0xFF4CAF50,
    isActive: true,
    lastModifiedAt: now,
    createdAt: now,
    updatedAt: now,
  );

  setUpAll(() {
    registerFallbackValue(Medication(
      id: 0,
      name: '',
      dosage: '',
      frequency: MedicationFrequency.daily,
      times: [],
      startDate: DateTime(2024),
      color: 0,
      isActive: false,
      lastModifiedAt: DateTime(2024),
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    ));
  });

  setUp(() {
    mockMedRepo = MockMedicationRepository();
    mockLogRepo = MockMedicationLogRepository();
  });

  group('Medication CRUD', () {
    test('getAll returns list of medications', () async {
      when(
        () => mockMedRepo.getAll(),
      ).thenAnswer((_) async => [testMedication]);

      final result = await mockMedRepo.getAll();

      expect(result.length, 1);
      expect(result.first.name, 'Aspirin');
    });

    test('getById returns medication when found', () async {
      when(
        () => mockMedRepo.getById(1),
      ).thenAnswer((_) async => testMedication);

      final result = await mockMedRepo.getById(1);

      expect(result, isNotNull);
      expect(result!.id, 1);
      expect(result.dosage, '100mg');
    });

    test('getById returns null when not found', () async {
      when(() => mockMedRepo.getById(99)).thenAnswer((_) async => null);

      final result = await mockMedRepo.getById(99);

      expect(result, isNull);
    });

    test('insert returns new id', () async {
      when(() => mockMedRepo.insert(any())).thenAnswer((_) async => 5);

      final id = await mockMedRepo.insert(testMedication);

      expect(id, 5);
      verify(() => mockMedRepo.insert(testMedication)).called(1);
    });

    test('toggleActive calls repository', () async {
      when(() => mockMedRepo.toggleActive(1)).thenAnswer((_) async {});

      await mockMedRepo.toggleActive(1);

      verify(() => mockMedRepo.toggleActive(1)).called(1);
    });

    test('getActive returns only active medications', () async {
      when(
        () => mockMedRepo.getActive(),
      ).thenAnswer((_) async => [testMedication]);

      final result = await mockMedRepo.getActive();

      expect(result.length, 1);
      expect(result.first.isActive, true);
    });
  });

  group('Medication Compliance', () {
    test('getComplianceRate returns 0 for no logs', () async {
      when(() => mockLogRepo.getComplianceRate(1)).thenAnswer((_) async => 0.0);

      final rate = await mockLogRepo.getComplianceRate(1);

      expect(rate, 0.0);
    });

    test('getComplianceRate returns 1.0 for perfect compliance', () async {
      when(() => mockLogRepo.getComplianceRate(1)).thenAnswer((_) async => 1.0);

      final rate = await mockLogRepo.getComplianceRate(1);

      expect(rate, 1.0);
    });

    test('getOverallComplianceRate aggregates across medications', () async {
      when(
        () => mockLogRepo.getOverallComplianceRate(days: 7),
      ).thenAnswer((_) async => 0.75);

      final rate = await mockLogRepo.getOverallComplianceRate(days: 7);

      expect(rate, 0.75);
    });

    test('getWeekdayComplianceMap returns 7-day map', () async {
      final expectedMap = {
        1: 1.0,
        2: 0.5,
        3: 0.0,
        4: 1.0,
        5: 0.75,
        6: 0.0,
        7: 0.0,
      };
      when(
        () => mockLogRepo.getWeekdayComplianceMap(),
      ).thenAnswer((_) async => expectedMap);

      final map = await mockLogRepo.getWeekdayComplianceMap();

      expect(map.length, 7);
      expect(map[1], 1.0); // Monday 100%
      expect(map[2], 0.5); // Tuesday 50%
      expect(map[3], 0.0); // Wednesday 0%
    });

    test('logMedication creates a taken log', () async {
      when(
        () => mockLogRepo.logMedication(1, MedicationLogStatus.taken),
      ).thenAnswer((_) async {});

      await mockLogRepo.logMedication(1, MedicationLogStatus.taken);

      verify(
        () => mockLogRepo.logMedication(1, MedicationLogStatus.taken),
      ).called(1);
    });

    test('logMedication creates a missed log', () async {
      when(
        () => mockLogRepo.logMedication(1, MedicationLogStatus.missed),
      ).thenAnswer((_) async {});

      await mockLogRepo.logMedication(1, MedicationLogStatus.missed);

      verify(
        () => mockLogRepo.logMedication(1, MedicationLogStatus.missed),
      ).called(1);
    });
  });

  group('Medication entity', () {
    test('copyWith preserves unchanged fields', () {
      final updated = testMedication.copyWith(name: 'Ibuprofen');

      expect(updated.name, 'Ibuprofen');
      expect(updated.dosage, '100mg'); // Unchanged
      expect(updated.id, 1); // Unchanged
      expect(updated.isActive, true); // Unchanged
    });

    test('equality works correctly', () {
      final copy = testMedication.copyWith();

      expect(copy, equals(testMedication));
    });

    test('equality fails on different id', () {
      final different = testMedication.copyWith(id: 999);

      expect(different, isNot(equals(testMedication)));
    });
  });
}
