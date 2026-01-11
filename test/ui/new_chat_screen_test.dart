import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:shopple/screens/chat/new_chat_screen.dart';
import 'package:shopple/controllers/chat/chat_management_controller.dart';
import 'package:shopple/models/chat/chat_user_model.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:shopple/services/presence/i_presence_service.dart';
import 'package:shopple/models/user_presence_status.dart';
import 'package:shopple/services/presence/presence_service.dart';

import '../firebase_test_helper.dart';
import '../mocks/mock_classes.mocks.dart';
import 'chat_conversation_screen_test.mocks.dart' show MockClientState;

class FakeInternalFinalCallback extends Fake
    implements InternalFinalCallback<void> {
  @override
  void call() {}
}

class FakeChatManagementController extends MockChatManagementController {
  final RxBool _isSearching = false.obs;
  final RxList<ChatUserModel> _searchResults = <ChatUserModel>[].obs;

  @override
  bool get isSearching => _isSearching.value;

  @override
  List<ChatUserModel> get searchResults => _searchResults;

  // Setters for test control
  set testIsSearching(bool val) => _isSearching.value = val;
  set testSearchResults(List<ChatUserModel> val) =>
      _searchResults.assignAll(val);

  @override
  InternalFinalCallback<void> get onStart =>
      InternalFinalCallback<void>(callback: () {});
  @override
  InternalFinalCallback<void> get onDelete =>
      InternalFinalCallback<void>(callback: () {});
  @override
  void onInit() {}
  @override
  void onReady() {}
  @override
  void onClose() {}
}

class FakePresenceService extends Fake implements IPresenceService {
  @override
  Stream<UserPresenceStatus> getUserPresenceStream(String userId) {
    return Stream.value(UserPresenceStatus.offline());
  }
}

class FakeChannelState extends Fake implements ChannelState {}

class FakeQueryMembersResponse extends Fake implements QueryMembersResponse {
  @override
  List<Member> get members => [];
}

class FakeEmptyResponse extends Fake implements EmptyResponse {}

class FakeHttpClientResponse extends Fake implements HttpClientResponse {
  final List<int> _body;

  FakeHttpClientResponse(this._body);

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _body.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream.value(_body).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class FakeHttpClientRequest extends Fake implements HttpClientRequest {
  final List<int> _body;

  FakeHttpClientRequest(this._body);

  @override
  Future<HttpClientResponse> close() async {
    return FakeHttpClientResponse(_body);
  }
}

class FakeHttpClient extends Fake implements HttpClient {
  final List<int> fontBytes;

  FakeHttpClient(this.fontBytes);

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    if (url.path.endsWith('.ttf')) {
      return FakeHttpClientRequest(fontBytes);
    } else {
      // Return transparent 1x1 GIF for images
      return FakeHttpClientRequest([
        0x47,
        0x49,
        0x46,
        0x38,
        0x39,
        0x61,
        0x01,
        0x00,
        0x01,
        0x00,
        0x80,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x21,
        0xf9,
        0x04,
        0x01,
        0x00,
        0x00,
        0x00,
        0x00,
        0x2c,
        0x00,
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x01,
        0x00,
        0x00,
        0x02,
        0x02,
        0x44,
        0x01,
        0x00,
        0x3b,
      ]);
    }
  }
}

class TestHttpOverrides extends HttpOverrides {
  final List<int> fontBytes;

  TestHttpOverrides(this.fontBytes);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return FakeHttpClient(fontBytes);
  }
}

void main() {
  late FakeChatManagementController mockChatController;
  late MockStreamChatClient mockStreamChatClient;
  late FakePresenceService mockPresenceService;

  late List<int> fontBytes;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = true;

    // Load font bytes
    final fontData = await rootBundle.load(
      'assets/fonts/Open-Sans/OpenSans-Regular.ttf',
    );
    fontBytes = fontData.buffer.asUint8List();
  });

  setUp(() async {
    await FirebaseTestHelper.setup();
    Get.reset();

    mockPresenceService = FakePresenceService();
    PresenceService.instance = mockPresenceService;

    mockChatController = FakeChatManagementController();
    Get.put<ChatManagementController>(mockChatController);

    mockStreamChatClient = MockStreamChatClient();

    // Default mock behavior for controller methods (not getters)
    when(
      mockChatController.searchFriendsForChat(any),
    ).thenAnswer((_) async => []);
  });

  testWidgets('NewChatScreen renders correctly', (WidgetTester tester) async {
    await HttpOverrides.runZoned(() async {
      await tester.pumpWidget(GetMaterialApp(home: const NewChatScreen()));
      await tester.pump(); // Allow font loading
      await tester.pump();

      expect(find.text('New Chat'), findsOneWidget);
      expect(find.text('Friends'), findsOneWidget);
      expect(find.text('All Users'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget); // Search bar
    }, createHttpClient: (_) => FakeHttpClient(fontBytes));
  });

  testWidgets('NewChatScreen shows empty state when no friends found', (
    WidgetTester tester,
  ) async {
    when(
      mockChatController.searchFriendsForChat(''),
    ).thenAnswer((_) async => []);

    await HttpOverrides.runZoned(() async {
      await tester.pumpWidget(GetMaterialApp(home: const NewChatScreen()));
      await tester.pump();
      await tester.pump(
        const Duration(milliseconds: 100),
      ); // Wait for FutureBuilder

      expect(find.text('No friends yet'), findsOneWidget);
      expect(find.text('Add friends to start chatting'), findsOneWidget);
    }, createHttpClient: (_) => FakeHttpClient(fontBytes));
  });

  testWidgets('NewChatScreen shows friends list', (WidgetTester tester) async {
    final friends = [
      ChatUserModel(
        userId: 'user1',
        displayName: 'Friend 1',
        photoUrl: 'https://example.com/photo1.jpg',
        createdAt: DateTime.now().toIso8601String(),
        isUserBanned: false,
      ),
      ChatUserModel(
        userId: 'user2',
        displayName: 'Friend 2',
        photoUrl: 'https://example.com/photo2.jpg',
        createdAt: DateTime.now().toIso8601String(),
        isUserBanned: false,
      ),
    ];

    when(
      mockChatController.searchFriendsForChat(''),
    ).thenAnswer((_) async => friends);

    await HttpOverrides.runZoned(() async {
      await tester.pumpWidget(GetMaterialApp(home: const NewChatScreen()));
      await tester.pump();
      await tester.pump(
        const Duration(milliseconds: 100),
      ); // Wait for FutureBuilder

      expect(find.text('Friend 1'), findsOneWidget);
      expect(find.text('Friend 2'), findsOneWidget);
    }, createHttpClient: (_) => FakeHttpClient(fontBytes));
  });

  testWidgets('NewChatScreen shows friends list', (WidgetTester tester) async {
    await tester.runAsync(() async {
      final friends = [
        ChatUserModel(
          userId: 'user1',
          displayName: 'Friend 1',
          photoUrl: 'https://example.com/photo1.jpg',
          createdAt: DateTime.now().toIso8601String(),
          isUserBanned: false,
        ),
        ChatUserModel(
          userId: 'user2',
          displayName: 'Friend 2',
          photoUrl: 'https://example.com/photo2.jpg',
          createdAt: DateTime.now().toIso8601String(),
          isUserBanned: false,
        ),
      ];

      when(
        mockChatController.searchFriendsForChat(''),
      ).thenAnswer((_) async => friends);

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(GetMaterialApp(home: const NewChatScreen()));
        await tester.pump();
        await tester.pump(
          const Duration(milliseconds: 100),
        ); // Wait for FutureBuilder

        expect(find.text('Friend 1'), findsOneWidget);
        expect(find.text('Friend 2'), findsOneWidget);
        expect(find.byIcon(Icons.chat_bubble_outline), findsNWidgets(2));
      });
    });
  });

  testWidgets('NewChatScreen starts chat on tap', (WidgetTester tester) async {
    final friend = ChatUserModel(
      userId: 'user1',
      displayName: 'Friend 1',
      photoUrl: 'https://example.com/photo1.jpg',
      createdAt: DateTime.now().toIso8601String(),
      isUserBanned: false,
    );

    when(
      mockChatController.searchFriendsForChat(''),
    ).thenAnswer((_) async => [friend]);

    final mockChannel = MockChannel();
    when(mockChannel.id).thenReturn('channel_id');
    when(mockChannel.cid).thenReturn('messaging:channel_id');
    when(mockChannel.type).thenReturn('messaging');
    when(mockChannel.config).thenReturn(ChannelConfig());
    when(mockChannel.ownCapabilities).thenReturn([]);
    when(mockChannel.initialized).thenAnswer((_) async => true);
    when(mockChannel.state).thenReturn(null);
    when(mockChannel.name).thenReturn('Test Channel');
    when(mockChannel.image).thenReturn('https://example.com/channel.jpg');
    when(
      mockChannel.markRead(messageId: anyNamed('messageId')),
    ).thenAnswer((_) async => FakeEmptyResponse());
    when(mockChannel.memberCount).thenReturn(2);
    when(mockChannel.watch()).thenAnswer((_) async => FakeChannelState());

    // Mock queryMembers for ChatConversationScreen
    when(
      mockChannel.queryMembers(
        filter: anyNamed('filter'),
        sort: anyNamed('sort'),
        pagination: anyNamed('pagination'),
      ),
    ).thenAnswer((_) async => FakeQueryMembersResponse());

    // Mock ChatConversationScreen dependencies
    final mockClientState = MockClientState();
    when(mockStreamChatClient.state).thenReturn(mockClientState);
    when(mockClientState.currentUser).thenReturn(OwnUser(id: 'current_user'));

    when(
      mockChatController.getOrCreateDirectChannel('user1'),
    ).thenAnswer((_) async => mockChannel);

    await HttpOverrides.runZoned(() async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: StreamChat(
            client: mockStreamChatClient,
            child: const NewChatScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap on the friend
      await tester.tap(find.text('Friend 1'));
      await tester.pump();

      verify(mockChatController.getOrCreateDirectChannel('user1')).called(1);
    }, createHttpClient: (_) => FakeHttpClient(fontBytes));
  });
}
