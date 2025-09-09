import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../common/providers/toast_provider.dart';
import '../common/widgets/glass_card.dart';
import '../common/widgets/gradient_button.dart';
import '../common/widgets/loading_widget.dart';
import '../services/events_service.dart';

class EventsViewComponent extends ConsumerStatefulWidget {
  const EventsViewComponent({super.key});

  @override
  ConsumerState<EventsViewComponent> createState() => _EventsViewComponentState();
}

class _EventsViewComponentState extends ConsumerState<EventsViewComponent> {
  final EventsService _eventsService = EventsService();
  
  List<dynamic> _events = [];
  bool _loading = true;
  Map<String, dynamic>? _selectedEvent;
  bool _showEventDetails = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final response = await _eventsService.getApprovedEvents();
      
      setState(() {
        _events = response;
        _loading = false;
      });
    } catch (error) {
      setState(() => _loading = false);
      if (!error.toString().contains('404')) {
        ref.read(toastProvider.notifier).showToast(
          'Failed to load events. Please try again.',
          ToastType.error,
        );
      }
    }
  }

  Future<void> _updateAttendance(String eventId, bool attending) async {
    try {
      await _eventsService.updateAttendance(eventId, attending);
      await _loadEvents();
      
      ref.read(toastProvider.notifier).showToast(
        attending ? 'Attendance confirmed successfully!' : 'Attendance cancelled successfully!',
        ToastType.success,
      );
    } catch (error) {
      ref.read(toastProvider.notifier).showToast(
        'Failed to update attendance',
        ToastType.error,
      );
    }
  }

  Color _getEventTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'workshop':
        return Colors.blue;
      case 'seminar':
        return Colors.green;
      case 'networking':
        return Colors.purple;
      case 'career':
        return Colors.orange;
      case 'social':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  bool _isEventUpcoming(Map<String, dynamic> event) {
    try {
      final eventStart = DateTime.parse(event['startDateTime']);
      return eventStart.isAfter(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  bool _isEventInProgress(Map<String, dynamic> event) {
    try {
      final now = DateTime.now();
      final eventStart = DateTime.parse(event['startDateTime']);
      final eventEnd = event['endDateTime'] != null 
          ? DateTime.parse(event['endDateTime'])
          : eventStart.add(const Duration(hours: 2));
      return now.isAfter(eventStart) && now.isBefore(eventEnd);
    } catch (e) {
      return false;
    }
  }

  bool _isEventCompleted(Map<String, dynamic> event) {
    try {
      final eventEnd = event['endDateTime'] != null 
          ? DateTime.parse(event['endDateTime'])
          : DateTime.parse(event['startDateTime']).add(const Duration(hours: 2));
      return DateTime.now().isAfter(eventEnd);
    } catch (e) {
      return false;
    }
  }

  Map<String, dynamic> _getEventStatus(Map<String, dynamic> event) {
    if (_isEventCompleted(event)) {
      return {'label': 'Completed', 'color': Colors.grey};
    } else if (_isEventInProgress(event)) {
      return {'label': 'In Progress', 'color': AppTheme.successColor};
    } else if (_isEventUpcoming(event)) {
      return {'label': 'Upcoming', 'color': AppTheme.primaryColor};
    }
    return {'label': 'Scheduled', 'color': AppTheme.warningColor};
  }

  void _showEventDetailsModal(Map<String, dynamic> event) {
    setState(() {
      _selectedEvent = event;
      _showEventDetails = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: LoadingWidget(message: 'Loading events...'),
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.event,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Events',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Events list
            Expanded(
              child: _events.isEmpty
                  ? GlassCard(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.event,
                            size: 64,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Events Available',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No events are currently scheduled.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _events.length,
                      itemBuilder: (context, index) {
                        final event = _events[index];
                        return _buildEventCard(event);
                      },
                    ),
            ),
          ],
        ),
        
        // Event details modal
        if (_showEventDetails && _selectedEvent != null)
          _buildEventDetailsModal(),
      ],
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final status = _getEventStatus(event);
    final eventType = event['type'] ?? 'General';
    final typeColor = _getEventTypeColor(eventType);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showEventDetailsModal(event),
                    child: Text(
                      event['title'] ?? 'Untitled Event',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: typeColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        eventType,
                        style: TextStyle(
                          color: typeColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (status['color'] as Color).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: (status['color'] as Color).withOpacity(0.3)),
                      ),
                      child: Text(
                        status['label'],
                        style: TextStyle(
                          color: status['color'],
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Text(
              event['description'] ?? 'No description available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 16),
            
            // Event details
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildEventDetail(
                  Icons.calendar_today,
                  event['startDateTime'] != null 
                      ? DateTime.parse(event['startDateTime']).toLocal().toString().split(' ')[0]
                      : 'No date',
                ),
                _buildEventDetail(
                  Icons.access_time,
                  event['startDateTime'] != null 
                      ? DateTime.parse(event['startDateTime']).toLocal().toString().split(' ')[1].substring(0, 5)
                      : 'No time',
                ),
                _buildEventDetail(
                  Icons.location_on,
                  event['location'] ?? 'Location not specified',
                ),
                _buildEventDetail(
                  Icons.person,
                  event['organizerName'] ?? 'Unknown Organizer',
                ),
                _buildEventDetail(
                  Icons.people,
                  '${(event['attendees'] as List?)?.length ?? 0}/${event['maxAttendees'] ?? 'Unlimited'} attendees',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: GradientButton(
                    onPressed: () => _showEventDetailsModal(event),
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 12),
                if (_isEventUpcoming(event))
                  Expanded(
                    child: GradientButton(
                      onPressed: () {
                        final attendees = event['attendees'] as List? ?? [];
                        final isAttending = attendees.contains('current_user_id'); // You'd get this from auth
                        _updateAttendance(event['id'], !isAttending);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            (event['attendees'] as List?)?.contains('current_user_id') == true
                                ? Icons.check
                                : Icons.people,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (event['attendees'] as List?)?.contains('current_user_id') == true
                                ? 'Attending'
                                : 'Join Event',
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.textMuted.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _isEventCompleted(event) ? 'Event Completed' : 'Registration Closed',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDetail(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.textMuted, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEventDetailsModal() {
    final event = _selectedEvent!;
    final status = _getEventStatus(event);
    
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxHeight: 600),
          decoration: BoxDecoration(
            color: AppTheme.darkBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.glassBorder),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event['title'] ?? 'Untitled Event',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getEventTypeColor(event['type'] ?? 'General').withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  event['type'] ?? 'General',
                                  style: TextStyle(
                                    color: _getEventTypeColor(event['type'] ?? 'General'),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (status['color'] as Color).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  status['label'],
                                  style: TextStyle(
                                    color: status['color'],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showEventDetails = false;
                          _selectedEvent = null;
                        });
                      },
                      icon: const Icon(
                        Icons.close,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      Text(
                        'About This Event',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event['description'] ?? 'No description available',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Event details
                      Text(
                        'Event Details',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      _buildDetailRow(
                        Icons.calendar_today,
                        'Date',
                        event['startDateTime'] != null 
                            ? DateTime.parse(event['startDateTime']).toLocal().toString().split(' ')[0]
                            : 'Not specified',
                      ),
                      _buildDetailRow(
                        Icons.access_time,
                        'Time',
                        event['startDateTime'] != null 
                            ? '${DateTime.parse(event['startDateTime']).toLocal().toString().split(' ')[1].substring(0, 5)}${event['endDateTime'] != null ? ' - ${DateTime.parse(event['endDateTime']).toLocal().toString().split(' ')[1].substring(0, 5)}' : ''}'
                            : 'Not specified',
                      ),
                      _buildDetailRow(
                        Icons.location_on,
                        'Location',
                        event['location'] ?? 'Not specified',
                      ),
                      _buildDetailRow(
                        Icons.person,
                        'Organizer',
                        event['organizerName'] ?? 'Unknown',
                      ),
                      _buildDetailRow(
                        Icons.people,
                        'Attendees',
                        '${(event['attendees'] as List?)?.length ?? 0}/${event['maxAttendees'] ?? 'Unlimited'}',
                      ),
                      
                      if (event['specialRequirements'] != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Special Requirements',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event['specialRequirements'],
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Action buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppTheme.glassBorder),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GradientButton(
                        onPressed: () {
                          setState(() {
                            _showEventDetails = false;
                            _selectedEvent = null;
                          });
                        },
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_isEventUpcoming(event))
                      Expanded(
                        child: GradientButton(
                          onPressed: () {
                            final attendees = event['attendees'] as List? ?? [];
                            final isAttending = attendees.contains('current_user_id');
                            _updateAttendance(event['id'], !isAttending);
                            setState(() {
                              _showEventDetails = false;
                              _selectedEvent = null;
                            });
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                (event['attendees'] as List?)?.contains('current_user_id') == true
                                    ? Icons.check
                                    : Icons.people,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (event['attendees'] as List?)?.contains('current_user_id') == true
                                    ? 'You\'re Attending - Click to Cancel'
                                    : 'Join This Event',
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (event['organizerEmail'] != null)
                      Expanded(
                        child: GradientButton(
                          onPressed: () async {
                            final uri = Uri(
                              scheme: 'mailto',
                              path: event['organizerEmail'],
                              query: 'subject=Event Inquiry: ${event['title']}',
                            );
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.email, size: 16),
                              const SizedBox(width: 4),
                              const Text('Contact'),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 16),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}