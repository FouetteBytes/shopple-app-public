import 'package:flutter/material.dart';
import '../../models/friends/friend_request.dart';
import '../../services/friends/friend_service.dart';
import '../../widgets/unified_profile_avatar.dart';
import 'package:shopple/widgets/common/liquid_glass_button.dart';

class FriendRequestTile extends StatefulWidget {
  final FriendRequest request;
  final VoidCallback? onRequestHandled;

  const FriendRequestTile({
    super.key,
    required this.request,
    this.onRequestHandled,
  });

  @override
  State<FriendRequestTile> createState() => _FriendRequestTileState();
}

class _FriendRequestTileState extends State<FriendRequestTile> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UnifiedProfileAvatar(
                  userId: widget.request.fromUserId,
                  radius: 30,
                  enableCache: true,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.request.fromUserName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        widget.request.fromUserEmail,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Sent ${_getTimeAgo(widget.request.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (widget.request.message != null) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.request.message!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],

            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LiquidGlassGradientButton(
                    onTap: _isLoading ? null : () => _acceptRequest(),
                    gradientColors: [Colors.green, Colors.green.shade700],
                    customChild: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Accept',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: LiquidGlassButton.text(
                    onTap: _isLoading ? null : () => _declineRequest(),
                    text: 'Decline',
                    isDestructive: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptRequest() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FriendService.acceptFriendRequest(widget.request.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request accepted!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onRequestHandled?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _declineRequest() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FriendService.declineFriendRequest(widget.request.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request declined'),
            backgroundColor: Colors.orange,
          ),
        );
        widget.onRequestHandled?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error declining request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
