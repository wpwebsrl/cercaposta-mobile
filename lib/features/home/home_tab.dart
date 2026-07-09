import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Active bottom-nav tab (0=search, 1=chat, 2=settings). Tabs live in an
/// IndexedStack (kept alive), so screens holding resources — e.g. the search
/// mic — watch this to release them when the user navigates away.
final homeTabProvider = StateProvider<int>((ref) => 0);
