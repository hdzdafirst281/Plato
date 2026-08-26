import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@module
abstract class SupabaseModule {
  // Dùng @preResolve vì Supabase cần khởi tạo bất đồng bộ (await) trước khi app chạy
  @preResolve
  @singleton
  Future<SupabaseClient> get supabaseClient async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!, 
      publishableKey: dotenv.env['SUPABASE_ANON_KEY']!
    );
    return Supabase.instance.client;
  }
}