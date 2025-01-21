import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://kwnxyklnacmstqaalsih.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt3bnh5a2xuYWNtc3RxYWFsc2loIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQ3NTM1MzksImV4cCI6MjA1MDMyOTUzOX0.SdR20VCJ3KbYOfa_rOsr_HFY-sSlLihFKilGeaEHLko';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}
