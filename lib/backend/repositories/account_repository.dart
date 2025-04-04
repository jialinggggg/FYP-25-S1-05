import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/account.dart';

class AccountRepository {
  final SupabaseClient _supabase;

  AccountRepository(this._supabase);

  Future<void> insertAccount(Account account) async {
    try {
      await _supabase.from('accounts').insert(account.toMap());
    } catch (error) {
      throw Exception('Unable to insert account: $error');
    }
  }

  Future<Account?> fetchAccount(String uid) async {
    try {
      final response = await _supabase
          .from('accounts')
          .select()
          .eq('uid', uid)
          .single();
      return Account.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateAccount(Account account) async {
    try {
      await _supabase.from('accounts').update(account.toMap()).eq('uid', account.uid);
    } catch (e) {
      throw Exception('Failed to update account: $e');
    }
  }

  Future<void> deleteAccount(String uid) async {
    try {
      await _supabase.from('accounts').delete().eq('uid', uid);
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  Future<bool> isAdmin(String uid) async {
    try {
      final account = await fetchAccount(uid);
      return account?.type == 'admin';
    } catch (e) {
      throw Exception('Error checking admin status: $e');
    }
  }

  Future<List<Account>> fetchAllUserAccounts() async {
    try {
      final response = await _supabase
          .from('accounts')
          .select('*, user_profiles(*)!left(*)')
          .eq('type', 'user');
      return response.map<Account>((map) => Account.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error fetching user accounts: $e');
    }
  }

  Future<List<Account>> fetchAllBusinessAccounts() async {
    try {
      final response = await _supabase
          .from('accounts')
          .select('*, business_profiles!left(*)')
          .eq('type', 'business');
      return response.map<Account>((map) => Account.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error fetching business accounts: $e');
    }
  }
}