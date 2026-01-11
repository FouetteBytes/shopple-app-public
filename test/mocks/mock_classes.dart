import 'package:mockito/annotations.dart';
import 'package:shopple/services/auth/auth_service.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shopple/services/friends/i_friend_service.dart';
import 'package:shopple/controllers/chat/chat_session_controller.dart';
import 'package:shopple/controllers/chat/chat_management_controller.dart';

@GenerateMocks([
  AuthService,
  StreamChatClient,
  FirebaseFunctions,
  HttpsCallable,
  HttpsCallableResult,
  IFriendService,
  Channel,
  User,
  ChannelClientState,
  ChatSessionController,
  ChatManagementController,
])
void main() {}
