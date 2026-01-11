import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:shopple/screens/chat/chat_conversation_screen.dart';
import 'package:shopple/controllers/chat/chat_management_controller.dart';
import 'package:shopple/services/presence/i_presence_service.dart';
import 'package:shopple/services/presence/presence_service.dart';
import 'package:shopple/services/user/user_profile_stream_service.dart';
import 'package:shopple/models/user_presence_status.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:mockito/annotations.dart';
import 'chat_conversation_screen_test.mocks.dart';
import '../fake_asset_bundle.dart';

import '../firebase_test_helper.dart';

@GenerateMocks([
  Channel,
  StreamChatClient,
  ChannelClientState,
  ClientState,
  ChatPersistenceClient,
])
// Mocks
class MockChatManagementController extends GetxController
    with Mock
    implements ChatManagementController {
  @override
  Future<void> markChannelAsRead(String channelId) async {}
}

class MockPresenceService extends Mock implements IPresenceService {
  @override
  Stream<UserPresenceStatus> getUserPresenceStream(String userId) {
    return Stream.value(UserPresenceStatus(isOnline: true));
  }
}

class FakeSendMessageResponse extends Fake implements SendMessageResponse {
  @override
  final Message message;
  FakeSendMessageResponse(this.message);
}

class FakeChannelClientState extends Fake
    implements ChannelClientState, ChannelState {
  FakeChannelClientState();

  @override
  List<Message> get messages => [
    Message(
      id: 'msg1',
      text: 'Hello',
      user: User(id: 'other_user_id', name: 'Other User'),
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    Message(
      id: 'msg2',
      text: 'Hi there',
      user: User(id: 'current_user_id', name: 'Current User'),
      createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
    ),
  ];

  @override
  ChannelModel? get channel {
    return ChannelModel(
      id: 'test_channel_id',
      type: 'messaging',
      cid: 'messaging:test_channel_id',
      ownCapabilities: [
        ChannelCapability.sendMessage,
        ChannelCapability.sendReaction,
        ChannelCapability.sendReply,
        ChannelCapability.uploadFile,
      ],
      config: ChannelConfig(
        maxMessageLength: 5000,
        automod: 'disabled',
        commands: [],
      ),
      extraData: {},
      memberCount: 2,
    );
  }

  @override
  Stream<List<Message>> get messagesStream => Stream.value(messages);

  @override
  List<Member> get members => [
    Member(
      user: User(id: 'current_user_id', name: 'Current User'),
      userId: 'current_user_id',
    ),
    Member(
      user: User(id: 'other_user_id', name: 'Other User'),
      userId: 'other_user_id',
    ),
  ];
  @override
  Stream<List<Member>> get membersStream => Stream.value(members);

  @override
  List<Read> get read => [
    Read(
      user: User(id: 'current_user_id'),
      lastRead: DateTime.now(),
      unreadMessages: 0,
    ),
    Read(
      user: User(id: 'other_user_id'),
      lastRead: DateTime.now(),
      unreadMessages: 0,
    ),
  ];
  @override
  Stream<List<Read>> get readStream => Stream.value(read);

  @override
  List<User> get watchers => [];
  @override
  Stream<List<User>> get watchersStream => Stream.value([]);

  @override
  int get watcherCount => 0;
  @override
  Stream<int?> get watcherCountStream => Stream.value(0);

  @override
  List<Message> get pinnedMessages => [];
  @override
  Stream<List<Message>> get pinnedMessagesStream => Stream.value([]);

  @override
  Map<String, List<Message>> get threads => {};
  @override
  Stream<Map<String, List<Message>>> get threadsStream => Stream.value({});

  @override
  Map<User, Event> get typingEvents => {};
  @override
  Stream<Map<User, Event>> get typingEventsStream => Stream.empty();

  @override
  int get unreadCount => 0;
  @override
  Stream<int> get unreadCountStream => Stream.value(0);

  @override
  bool get isUpToDate => true;
  @override
  Stream<bool> get isUpToDateStream => Stream.value(true);

  @override
  Read? get currentUserRead => read.first;
  @override
  Stream<Read?> get currentUserReadStream => Stream.value(read.first);

  @override
  Message? get lastMessage => messages.first;
  @override
  Stream<Message?> get lastMessageStream => Stream.value(messages.first);

  @override
  Draft? get draft => null;
  @override
  Stream<Draft?> get draftStream => Stream.value(null);

  @override
  ChannelState get channelState => this;
  @override
  Stream<ChannelState> get channelStateStream => Stream.value(this);

  // Try to implement channel if it exists in ChannelState
  // @override
  // Channel get channel => MockChannel();
}

void main() {
  late MockChatManagementController mockChatController;
  late MockPresenceService mockPresenceService;
  late MockChannel mockChannel;
  late MockStreamChatClient mockStreamChatClient;
  late FakeChannelClientState fakeChannelState;
  late MockChatPersistenceClient mockChatPersistenceClient;
  late ByteData fontData;

  setUpAll(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;

    fontData = await rootBundle.load(
      'assets/fonts/Open-Sans/OpenSans-Regular.ttf',
    );
    setupFakeAssetManifest(binding, fontData);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.llfbandit.record/messages'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'create') {
              return null;
            }
            return null;
          },
        );
  });

  setUp(() async {
    await FirebaseTestHelper.setup();
    Get.reset();

    mockChatController = MockChatManagementController();
    Get.put<ChatManagementController>(mockChatController);

    mockPresenceService = MockPresenceService();
    PresenceService.instance = mockPresenceService;

    mockChannel = MockChannel();
    mockStreamChatClient = MockStreamChatClient();
    fakeChannelState = FakeChannelClientState();
    mockChatPersistenceClient = MockChatPersistenceClient();

    // Setup Channel mock
    when(mockChannel.client).thenReturn(mockStreamChatClient);
    when(mockChannel.state).thenReturn(fakeChannelState);
    when(mockChannel.id).thenReturn('test_channel_id');
    when(mockChannel.cid).thenReturn('messaging:test_channel_id');
    when(mockChannel.name).thenReturn('Test Channel');
    when(mockChannel.memberCount).thenReturn(2);
    when(mockChannel.extraData).thenReturn({});
    when(mockChannel.createdBy).thenReturn(User(id: 'creator_id'));
    when(mockChannel.isMuted).thenReturn(false);
    when(mockChannel.markRead()).thenAnswer((_) async => EmptyResponse());
    when(mockChannel.initialized).thenAnswer((_) async => true);
    when(mockChannel.ownCapabilities).thenReturn([
      ChannelCapability.sendMessage,
      ChannelCapability.sendReaction,
      ChannelCapability.sendReply,
      ChannelCapability.uploadFile,
    ]);
    when(mockChannel.ownCapabilitiesStream).thenAnswer(
      (_) => Stream.value([
        ChannelCapability.sendMessage,
        ChannelCapability.sendReaction,
        ChannelCapability.sendReply,
        ChannelCapability.uploadFile,
      ]),
    );
    when(mockChannel.on(any, any, any)).thenAnswer((_) => Stream.empty());
    when(mockChannel.config).thenReturn(
      ChannelConfig(maxMessageLength: 5000, automod: 'disabled', commands: []),
    );
    when(mockChannel.getRemainingCooldown()).thenReturn(0);
    when(
      mockChannel.watch(presence: anyNamed('presence')),
    ).thenAnswer((_) async => fakeChannelState);
    when(
      mockStreamChatClient.queryChannel(
        any,
        state: anyNamed('state'),
        watch: anyNamed('watch'),
        presence: anyNamed('presence'),
        channelId: anyNamed('channelId'),
        channelData: anyNamed('channelData'),
        messagesPagination: anyNamed('messagesPagination'),
        membersPagination: anyNamed('membersPagination'),
        watchersPagination: anyNamed('watchersPagination'),
      ),
    ).thenAnswer((_) async => fakeChannelState);

    // Add missing streams that might be causing Null check operator error
    when(mockChannel.cooldown).thenReturn(0);
    when(mockChannel.isDistinct).thenReturn(false);
    when(mockChannel.id).thenReturn('test_channel_id');
    when(mockChannel.cid).thenReturn('messaging:test_channel_id');
    when(mockChannel.type).thenReturn('messaging');
    when(mockChannel.image).thenReturn(null);
    when(mockChannel.truncatedAt).thenReturn(null);
    when(mockChannel.cooldown).thenReturn(0);
    when(mockChannel.lastMessageAt).thenReturn(DateTime.now());
    when(mockChannel.createdAt).thenReturn(DateTime.now());
    when(mockChannel.updatedAt).thenReturn(DateTime.now());
    when(mockChannel.deletedAt).thenReturn(null);
    when(mockChannel.team).thenReturn(null);

    when(
      mockChannel.watch(
        messagesPagination: anyNamed('messagesPagination'),
        membersPagination: anyNamed('membersPagination'),
        watchersPagination: anyNamed('watchersPagination'),
      ),
    ).thenAnswer((_) async => fakeChannelState);

    // Setup Channel mock streams
    when(
      mockChannel.nameStream,
    ).thenAnswer((_) => Stream.value('Test Channel'));
    when(mockChannel.imageStream).thenAnswer((_) => Stream.value(null));
    when(mockChannel.extraDataStream).thenAnswer((_) => Stream.value({}));
    when(mockChannel.memberCountStream).thenAnswer((_) => Stream.value(0));
    when(
      mockChannel.configStream,
    ).thenAnswer((_) => Stream.value(ChannelConfig()));
    when(mockChannel.config).thenReturn(ChannelConfig());
    when(mockChannel.hiddenStream).thenAnswer((_) => Stream.value(false));
    when(mockChannel.isMutedStream).thenAnswer((_) => Stream.value(false));
    when(mockChannel.isArchivedStream).thenAnswer((_) => Stream.value(false));
    when(
      mockChannel.createdByStream,
    ).thenAnswer((_) => Stream.value(User(id: 'creator_id')));
    when(mockChannel.frozenStream).thenAnswer((_) => Stream.value(false));
    when(mockChannel.frozen).thenReturn(false);
    when(
      mockChannel.lastMessageAtStream,
    ).thenAnswer((_) => Stream.value(DateTime.now()));
    when(
      mockChannel.createdAtStream,
    ).thenAnswer((_) => Stream.value(DateTime.now()));
    when(
      mockChannel.updatedAtStream,
    ).thenAnswer((_) => Stream.value(DateTime.now()));
    when(mockChannel.deletedAtStream).thenAnswer((_) => Stream.value(null));
    when(mockChannel.hiddenStream).thenAnswer((_) => Stream.value(false));
    when(mockChannel.hidden).thenReturn(false);
    when(mockChannel.ownCapabilitiesStream).thenAnswer(
      (_) => Stream.value([
        ChannelCapability.sendMessage,
        ChannelCapability.uploadFile,
        ChannelCapability.sendReaction,
        ChannelCapability.sendReply,
        ChannelCapability.readEvents,
        ChannelCapability.typingEvents,
      ]),
    );
    when(mockChannel.ownCapabilities).thenReturn([
      ChannelCapability.sendMessage,
      ChannelCapability.uploadFile,
      ChannelCapability.sendReaction,
      ChannelCapability.sendReply,
      ChannelCapability.readEvents,
      ChannelCapability.typingEvents,
    ]);
    when(mockChannel.initialized).thenAnswer((_) => Future.value(true));
    when(mockChannel.truncatedAtStream).thenAnswer((_) => Stream.value(null));
    when(mockChannel.membershipStream).thenAnswer((_) => Stream.value(null));
    when(mockChannel.disabledStream).thenAnswer((_) => Stream.value(false));
    when(mockChannel.isPinnedStream).thenAnswer((_) => Stream.value(false));
    when(
      mockChannel.currentUserLastMessageAtStream,
    ).thenAnswer((_) => Stream.value(null));
    when(
      mockChannel.query(
        messagesPagination: anyNamed('messagesPagination'),
        membersPagination: anyNamed('membersPagination'),
        watchersPagination: anyNamed('watchersPagination'),
      ),
    ).thenAnswer((_) async => fakeChannelState);

    // Setup Client mock
    final mockClientState = MockClientState();
    when(
      mockClientState.currentUser,
    ).thenReturn(OwnUser(id: 'current_user_id'));
    when(
      mockClientState.currentUserStream,
    ).thenAnswer((_) => Stream.value(OwnUser(id: 'current_user_id')));
    when(mockClientState.users).thenReturn({});
    when(mockClientState.usersStream).thenAnswer((_) => Stream.value({}));
    when(mockClientState.unreadChannels).thenReturn(0);
    when(
      mockClientState.unreadChannelsStream,
    ).thenAnswer((_) => Stream.value(0));
    when(mockClientState.totalUnreadCount).thenReturn(0);
    when(
      mockClientState.totalUnreadCountStream,
    ).thenAnswer((_) => Stream.value(0));
    when(
      mockClientState.channels,
    ).thenReturn({'messaging:test_channel_id': mockChannel});
    when(mockClientState.channelsStream).thenAnswer(
      (_) => Stream.value({'messaging:test_channel_id': mockChannel}),
    );
    when(mockStreamChatClient.state).thenReturn(mockClientState);
    when(
      mockStreamChatClient.chatPersistenceClient,
    ).thenReturn(mockChatPersistenceClient);
    when(
      mockStreamChatClient.wsConnectionStatusStream,
    ).thenAnswer((_) => Stream.value(ConnectionStatus.connected));
    when(
      mockStreamChatClient.wsConnectionStatus,
    ).thenReturn(ConnectionStatus.connected);
    when(
      mockStreamChatClient.on(any, any, any, any),
    ).thenAnswer((_) => Stream.value(Event(type: 'test')));

    // Mock UserProfileStreamService
    UserProfileStreamService.instance.firestore = FirebaseTestHelper.firestore;
  });

  testWidgets('ChatConversationScreen renders correctly', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() async {
      // Arrange
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        GetMaterialApp(
          home: StreamChat(
            client: mockStreamChatClient,
            streamChatThemeData: StreamChatThemeData(),
            child: ChatConversationScreen(channel: mockChannel),
          ),
        ),
      );
      await tester.pump(); // Initial build
      await tester.pump(
        const Duration(milliseconds: 100),
      ); // Allow streams to emit

      // Assert
      expect(find.byType(ChatConversationScreen), findsOneWidget);
      expect(find.text('Other User'), findsNWidgets(2)); // Header and Message
      expect(find.text('Hello'), findsOneWidget);
      expect(find.byType(StreamMessageInput), findsOneWidget);
    });
  });

  testWidgets('ChatConversationScreen sends message', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() async {
      // Arrange
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(mockChannel.sendMessage(any)).thenAnswer(
        (_) async => FakeSendMessageResponse(
          Message(id: 'new_msg', text: 'New Message'),
        ),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: StreamChat(
            client: mockStreamChatClient,
            streamChatThemeData: StreamChatThemeData(),
            child: ChatConversationScreen(channel: mockChannel),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find input and enter text
      final inputFinder = find.byType(TextField);
      await tester.enterText(inputFinder, 'New Message');
      await tester.pump();

      // Tap send button
      // Try sending via keyboard action
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();

      // Also try tapping the last IconButton just in case
      final iconButtons = find.byType(IconButton);
      if (iconButtons.evaluate().isNotEmpty) {
        await tester.tap(iconButtons.last);
        await tester.pump();
      }

      // Assert
      verify(mockChannel.sendMessage(any)).called(1);
    });
  });
}
