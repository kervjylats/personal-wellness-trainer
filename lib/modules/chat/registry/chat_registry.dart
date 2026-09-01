// lib/modules/chat/registry/chat_registry.dart
//
// Registers chat module's shareable widgets into the WidgetRegistry.
//
// Currently empty — ChatsSlot (the only widget this ever registered) was
// removed once NetworkScreen's "Chats" tab was replaced by a dedicated
// chat icon that opens ConversationsListScreen directly, which made
// ChatsSlot's rendering logic fully redundant with that screen. This
// class stays as the extension point for the next shareable chat widget,
// matching every other module's registry in main.dart's
// _registerModuleWidgets().

abstract final class ChatRegistry {
  static void register() {
    // No shareable widgets registered yet.
  }
}