import 'package:comira/src/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the shell, tabs, and camera entry', (tester) async {
    await tester.pumpWidget(const ComiraApp());
    await tester.pumpAndSettle();

    expect(find.text('Comira'), findsOneWidget);
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('素材库'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);

    await tester.tap(find.text('素材库'));
    await tester.pumpAndSettle();

    expect(find.text('角色文档即将上线'), findsOneWidget);
  });
}
