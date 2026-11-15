import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vms_frontend/app/app.dart';
import 'package:vms_frontend/core/theme/app_theme.dart';
import 'package:vms_frontend/features/vehicles/vehicle.dart';
import 'package:vms_frontend/features/vehicles/vehicle_form_screen.dart';
import 'package:vms_frontend/features/vehicles/vehicle_list_screen.dart';

void main() {
  testWidgets('Login validates required credentials before sending', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const VmsApp());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your work email.'), findsOneWidget);
    expect(find.text('Enter a password to continue.'), findsOneWidget);
  });

  testWidgets('VehicleListScreen renders table on desktop matching guideline', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final testVehicles = [
      const Vehicle(
        id: '1',
        vehicleNumber: '00000001',
        company: 'Stark Logistics',
        type: 'Truck',
        brand: 'Brand 1',
        model: 'Model X',
        status: 'Active',
      ),
      const Vehicle(
        id: '2',
        vehicleNumber: '00000002',
        company: 'Apex Transport',
        type: 'Van',
        brand: 'Brand 2',
        model: 'Model S',
        status: 'In maintenance',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: VehicleListScreen(
            vehicles: testVehicles,
            onCreate: () {},
            onEdit: (_) {},
            onDelete: (_) {},
            onRefresh: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Check Header and Action Button
    expect(find.text('Vehicle List'), findsOneWidget);
    expect(find.text('+ New List'), findsOneWidget);

    // Check Filter Bar
    expect(find.text('Filter...'), findsOneWidget);
    expect(find.text('Filter list'), findsOneWidget);

    // Check Table Content
    expect(find.text('00000001'), findsOneWidget);
    expect(find.text('00000002'), findsOneWidget);
    expect(find.text('Brand 1'), findsOneWidget);
    expect(find.text('Brand 2'), findsOneWidget);
    expect(find.text('Model X'), findsOneWidget);
    expect(find.text('Model S'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('In maintenance'), findsOneWidget);
  });

  testWidgets('VehicleListScreen search filters correctly', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final testVehicles = [
      const Vehicle(
        id: '1',
        vehicleNumber: 'DHAKA-METRO-GA-11-4821',
        company: 'Stark Logistics',
        type: 'Truck',
        brand: 'Toyota',
        model: 'Hiace 2022',
        status: 'Active',
      ),
      const Vehicle(
        id: '2',
        vehicleNumber: 'CHATTOGRAM-BA-01-3322',
        company: 'Apex Transport',
        type: 'Van',
        brand: 'Nissan',
        model: 'Urvan 2021',
        status: 'In maintenance',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: VehicleListScreen(
            vehicles: testVehicles,
            onCreate: () {},
            onEdit: (_) {},
            onDelete: (_) {},
            onRefresh: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Enter search text
    await tester.enterText(find.byType(TextField), 'chattogram');
    await tester.pumpAndSettle();

    expect(find.text('CHATTOGRAM-BA-01-3322'), findsOneWidget);
    expect(find.text('DHAKA-METRO-GA-11-4821'), findsNothing);
  });

  testWidgets('VehicleFormScreen renders and validates inputs matching guideline', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: VehicleFormScreen(
          onSave: (v) async => v,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Register / Update Vehicle'), findsOneWidget);
    expect(find.text('Vehicle Number'), findsOneWidget);
    expect(find.text('Type'), findsOneWidget);
    expect(find.text('Brand'), findsOneWidget);
    expect(find.text('Model'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);

    // Tap Save button to trigger validation
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Enter the vehicle number.'), findsOneWidget);
    expect(find.text('Enter the company.'), findsOneWidget);
    expect(find.text('Enter the vehicle type.'), findsOneWidget);
    expect(find.text('Enter the brand.'), findsOneWidget);
    expect(find.text('Enter the model.'), findsOneWidget);
  });
}
