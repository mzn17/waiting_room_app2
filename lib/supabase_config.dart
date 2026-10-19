import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseUrl = 'https://jtarpifqpspdamldizyf.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp0YXJwaWZxcHNwZGFtbGRpenlmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE4OTY1OTYsImV4cCI6MjEwNzQ3MjU5Nn0.Beg19IB0aAuSOdoBw4rh6mubl80_p4PGun-8c0CrUDs';

SupabaseClient get supabase => Supabase.instance.client;
