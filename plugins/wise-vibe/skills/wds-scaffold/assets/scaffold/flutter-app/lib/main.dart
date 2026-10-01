// {{PROJECT_NAME}} — Flutter entrypoint (정적 템플릿 / static scaffold)
import 'package:flutter/material.dart';
import 'core/env.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: '{{PROJECT_NAME}}',
        home: Scaffold(
          body: Center(
            child: Text('Hello, {{PROJECT_NAME}} (${Env.flavor})',
                style: const TextStyle(fontSize: 24)),
          ),
        ),
      );
}
