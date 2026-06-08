# Code Reference Guide: Ephemeral vs. App State

## Quick Reference

### Project Structure
```
lib/
├── main.dart          # Complete implementation with both state types
```

### pubspec.yaml - Dependencies Added
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  provider: ^6.0.0     # ← Added for app state management
```

---

## App State Management (Theme Provider)

### Define the Provider Class
```dart
import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();  // Rebuilds all Consumer widgets listening to this provider
  }
}
```

### Wrap App with Provider
```dart
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}
```

### Use Consumer to Listen to Provider Changes
```dart
Consumer<ThemeProvider>(
  builder: (context, themeProvider, child) {
    return MaterialApp(
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: const MyHomePage(title: 'State Management Example'),
    );
  },
)
```

### Access and Modify App State
```dart
// Read current state
Consumer<ThemeProvider>(
  builder: (context, themeProvider, _) {
    Text('Current Theme: ${themeProvider.isDarkMode ? "Dark" : "Light"}'),
  },
)

// Modify state
ElevatedButton(
  onPressed: () => Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
  child: const Text('Switch Theme'),
)
```

---

## Ephemeral State Management (setState)

### Define StatefulWidget
```dart
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}
```

### Define State Class with Local Variables
```dart
class _MyHomePageState extends State<MyHomePage> {
  // Ephemeral state variables
  int _counter = 0;
  String _userInput = '';

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _decrementCounter() {
    setState(() {
      _counter--;
    });
  }

  void _resetCounter() {
    setState(() {
      _counter = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Build UI using ephemeral state
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Text('Counter: $_counter'),
          ElevatedButton(
            onPressed: _incrementCounter,
            child: const Text('Increment'),
          ),
        ],
      ),
    );
  }
}
```

### Text Input Example (Ephemeral State)
```dart
String _userInput = '';

TextField(
  onChanged: (value) {
    setState(() {
      _userInput = value;  // Update ephemeral state
    });
  },
  decoration: InputDecoration(
    hintText: 'Type something...',
  ),
),
if (_userInput.isNotEmpty)
  Text('You typed: $_userInput'),
```

---

## Pattern Comparison

### When to Use setState() (Ephemeral)
```dart
// ✅ GOOD: Local counter for a single widget
class _CounterWidgetState extends State<CounterWidget> {
  int _count = 0;
  
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => setState(() => _count++),
      child: Text('$_count'),
    );
  }
}

// ❌ AVOID: Using setState() for global app state
// This requires passing data through many widgets and is inefficient
```

### When to Use Provider (App State)
```dart
// ✅ GOOD: Theme accessible from entire app
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();  // All Consumer widgets update
  }
}

// ✅ GOOD: User authentication status shared across app
class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  
  Future<void> login(String email, String password) async {
    // Auth logic
    _currentUser = user;
    notifyListeners();
  }
}
```

---

## Helper Widgets (from main.dart)

### Section Builder Helper
```dart
Widget _buildSection({
  required String title,
  required String description,
  required Widget child,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 4),
      Text(
        description,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 12),
      child,
    ],
  );
}
```

### Difference Card Builder
```dart
Widget _buildDifference(String type, String details) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          type,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(details),
      ],
    ),
  );
}
```

---

## Common Patterns

### Multiple Providers
```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
```

### Accessing Multiple Providers in Widget
```dart
@override
Widget build(BuildContext context) {
  return Consumer2<ThemeProvider, AuthProvider>(
    builder: (context, theme, auth, _) {
      return MaterialApp(
        themeMode: theme.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: auth.isAuthenticated ? HomePage() : LoginPage(),
      );
    },
  );
}
```

### Read Without Listening
```dart
// Use when you need current value but don't want to rebuild on changes
final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

// Or use for methods:
Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
```

---

## Testing

### Test Ephemeral State
```dart
testWidgets('Counter increments', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  
  expect(find.text('0'), findsOneWidget);
  await tester.tap(find.byIcon(Icons.add));
  await tester.pump();
  
  expect(find.text('1'), findsOneWidget);
});
```

### Test App State with Provider
```dart
testWidgets('Theme toggles globally', (WidgetTester tester) async {
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
  
  expect(find.byIcon(Icons.dark_mode), findsOneWidget);
  await tester.tap(find.byIcon(Icons.dark_mode));
  await tester.pump();
  
  expect(find.byIcon(Icons.light_mode), findsOneWidget);
});
```

---

## Troubleshooting

### Issue: State not updating with setState()
**Solution**: Make sure you're calling `setState()` and not just modifying the variable
```dart
// ❌ Wrong
_counter++;  // This won't trigger rebuild

// ✅ Correct
setState(() {
  _counter++;  // This triggers rebuild
});
```

### Issue: Provider changes not reflected
**Solution**: Make sure you're calling `notifyListeners()`
```dart
class MyProvider extends ChangeNotifier {
  void updateValue() {
    _value = newValue;
    notifyListeners();  // Required!
  }
}
```

### Issue: Provider not accessible in widget
**Solution**: Make sure provider is wrapped higher in widget tree
```dart
// ❌ Wrong: Provider below the widget trying to access it
ChangeNotifierProvider(
  create: (_) => MyProvider(),
  child: MyApp(),  // MyApp tries to use Consumer, but it's too high
)

// ✅ Correct: Wrap entire app with provider
runApp(
  ChangeNotifierProvider(
    create: (_) => MyProvider(),
    child: const MyApp(),
  ),
)
```

---

## References

- **Flutter State Management**: https://docs.flutter.dev/data-and-backend/state-mgmt/intro
- **Provider Package**: https://pub.dev/packages/provider
- **Official Architecture Patterns**: https://docs.flutter.dev/data-and-backend/state-mgmt/options
