// lib/data/sources/supabase/supabase_marketplace_source.dart
//
// Real Supabase implementation of MarketplaceRepository.
//
// getDiscoverableListings() intentionally does NOT filter by platform_id
// — see schema.sql's marketplace_listings table comment for the full
// reasoning: MockMarketplaceSource never filters by it either (checked
// directly), and platform_id-based reseller isolation is flagged there as
// an open design question, not silently implemented here without it
// having been specified or tested anywhere in the app.
//
// DuplicateMarketplaceRequestException (defined in marketplace_repository.dart)
// is never actually thrown by MockMarketplaceSource's sendRequest() either
// — it's declared but unused in the whole codebase — so this doesn't
// throw it either, for the same "match tested behavior" reason.

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:personal_wellness_trainer/data/models/marketplace_listing.dart';
import 'package:personal_wellness_trainer/data/models/partnership_request.dart';
import 'package:personal_wellness_trainer/data/repositories/marketplace_repository.dart';

class SupabaseMarketplaceSource implements MarketplaceRepository {
  final SupabaseClient _db = Supabase.instance.client;

  @override
  Future<MarketplaceListing?> getMyListing(String ownerUserId) async {
    final rows = await _db
        .from('marketplace_listings')
        .select()
        .eq('owner_user_id', ownerUserId)
        .limit(1);
    final list = rows as List;
    if (list.isEmpty) return null;
    return MarketplaceListing.fromJson(list.first as Map<String, dynamic>);
  }

  @override
  Future<MarketplaceListing> upsertListing(MarketplaceListing listing) async {
    final row = await _db
        .from('marketplace_listings')
        .upsert(listing.toJson(), onConflict: 'owner_user_id')
        .select()
        .single();
    return MarketplaceListing.fromJson(row);
  }

  @override
  Future<List<MarketplaceListing>> getDiscoverableListings({
    required String viewerOwnerUserId,
    required String viewerCategoryId,
    required List<String> desiredCategories,
  }) async {
    if (desiredCategories.isEmpty) return [];

    final rows = await _db
        .from('marketplace_listings')
        .select()
        .eq('discoverable', true)
        .neq('owner_user_id', viewerOwnerUserId)
        .neq('owner_category_id', viewerCategoryId)
        .inFilter('owner_category_id', desiredCategories)
        .order('updated_at', ascending: false);

    return (rows as List)
        .map((r) => MarketplaceListing.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<PartnershipRequest>> getSentRequests(
    String senderOwnerUserId,
  ) async {
    final rows = await _db
        .from('partnership_requests')
        .select()
        .eq('sender_owner_user_id', senderOwnerUserId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => PartnershipRequest.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<PartnershipRequest>> getReceivedRequests(
    String receiverOwnerUserId,
  ) async {
    final rows = await _db
        .from('partnership_requests')
        .select()
        .eq('receiver_owner_user_id', receiverOwnerUserId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => PartnershipRequest.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PartnershipRequest> sendRequest({
    required String senderOwnerUserId,
    required String receiverOwnerUserId,
    required String senderBusinessId,
    required String senderBusinessName,
    required String senderCategoryId,
    required String receiverCategoryId,
    String? message,
  }) async {
    final row = await _db.from('partnership_requests').insert({
      'sender_owner_user_id': senderOwnerUserId,
      'receiver_owner_user_id': receiverOwnerUserId,
      'sender_business_id': senderBusinessId,
      'sender_business_name': senderBusinessName,
      'sender_category_id': senderCategoryId,
      'receiver_category_id': receiverCategoryId,
      'status': 'pending',
      if (message != null) 'message': message,
    }).select().single();

    return PartnershipRequest.fromJson(row);
  }

  @override
  Future<PartnershipRequest> respondToRequest({
    required String requestId,
    required String newStatus,
  }) async {
    final row = await _db
        .from('partnership_requests')
        .update({
          'status': newStatus,
          'responded_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId)
        .select()
        .single();
    return PartnershipRequest.fromJson(row);
  }
}
