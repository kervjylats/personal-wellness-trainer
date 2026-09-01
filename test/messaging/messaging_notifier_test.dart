import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/data/models/conversation_model.dart';
import 'package:personal_wellness_trainer/data/models/user_profile.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_notifier.dart';
import 'package:personal_wellness_trainer/engine/auth/auth_state.dart';
import 'package:personal_wellness_trainer/modules/chat/providers/chat_notifier.dart';
import 'package:personal_wellness_trainer/modules/chat/providers/message_notifier.dart';

void main() {
  ProviderContainer ownerContainer() {
    final profile = UserProfile(
      userId: 'usr_owner_001',
      businessId: 'biz_mock_001',
      role: 'owner',
      displayName: 'Test Owner',
      joinedAt: DateTime(2025),
      isActive: true,
    );
    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(() => _FakeAuthNotifier(profile)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('ChatNotifier — build', () {
    test('returns a list of ConversationModel', () async {
      final container = ownerContainer();
      final result = await container.read(chatNotifierProvider.future);
      expect(result, isA<List<ConversationModel>>());
    });

    test('unauthenticated user gets empty list', () async {
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(() => _UnauthenticatedFakeAuth()),
        ],
      );
      addTearDown(container.dispose);
      final result = await container.read(chatNotifierProvider.future);
      expect(result, isEmpty);
    });
  });

  group('ChatNotifier — createConversation', () {
    test('creates a direct conversation and returns a ConversationModel',
        () async {
      final container = ownerContainer();
      final conversation = await container
          .read(chatNotifierProvider.notifier)
          .createConversation(
            participantIds: const ['usr_staff_001'],
            participantNames: const ['Staff Member'],
          );
      expect(conversation, isA<ConversationModel>());
      expect(conversation!.participantIds, contains('usr_owner_001'));
      expect(conversation.participantIds, contains('usr_staff_001'));
    });

    test('owner is prepended to participant lists automatically', () async {
      final container = ownerContainer();
      final conversation = await container
          .read(chatNotifierProvider.notifier)
          .createConversation(
            participantIds: const ['usr_partner_999'],
            participantNames: const ['Partner One'],
          );
      expect(conversation, isNotNull);
      expect(conversation!.participantIds.first, equals('usr_owner_001'));
      expect(conversation.participantNames.first, equals('Test Owner'));
    });

    test('creating conversation grows the conversation list by one', () async {
      final container = ownerContainer();
      final before = await container.read(chatNotifierProvider.future);
      await container
          .read(chatNotifierProvider.notifier)
          .createConversation(
            participantIds: const ['usr_client_001'],
            participantNames: const ['Client One'],
          );
      final after = await container.read(chatNotifierProvider.future);
      expect(after.length, equals(before.length + 1));
    });

    test('creates a group conversation when groupName is provided', () async {
      final container = ownerContainer();
      final conversation = await container
          .read(chatNotifierProvider.notifier)
          .createConversation(
            participantIds: const ['usr_staff_001', 'usr_partner_001'],
            participantNames: const ['Staff Member', 'Partner One'],
            groupName: 'Team Group',
          );
      expect(conversation, isNotNull);
      expect(conversation!.isGroup, isTrue);
      expect(conversation.groupName, equals('Team Group'));
    });
  });

  group('MessageNotifier — sendMessage', () {
    test('sending a message grows the message list by one', () async {
      final container = ownerContainer();
      final conv = await container
          .read(chatNotifierProvider.notifier)
          .createConversation(
            participantIds: const ['usr_staff_001'],
            participantNames: const ['Staff Member'],
          );
      expect(conv, isNotNull);

      final before = await container
          .read(messageNotifierProvider(conv!.id).future);

      await container
          .read(messageNotifierProvider(conv.id).notifier)
          .sendMessage(content: 'Hello from test');

      final after = await container
          .read(messageNotifierProvider(conv.id).future);
      expect(after.length, equals(before.length + 1));
    });

    test('sent message has correct sender info and content', () async {
      final container = ownerContainer();
      final conv = await container
          .read(chatNotifierProvider.notifier)
          .createConversation(
            participantIds: const ['usr_staff_001'],
            participantNames: const ['Staff Member'],
          );
      await container
          .read(messageNotifierProvider(conv!.id).notifier)
          .sendMessage(content: 'Test message content');

      final messages = await container
          .read(messageNotifierProvider(conv.id).future);
      final sent = messages.last;

      expect(sent.senderId, equals('usr_owner_001'));
      expect(sent.senderName, equals('Test Owner'));
      expect(sent.content, equals('Test message content'));
    });
  });
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._profile);
  final UserProfile _profile;
  @override
  AuthState build() => AuthAuthenticated(profile: _profile);
}

class _UnauthenticatedFakeAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthUnauthenticated();
}