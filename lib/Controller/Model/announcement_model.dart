// Reuse EmergencyAnnouncement model structure since they have the same fields
import 'package:deepinheart/Controller/Model/emergency_announcement_model.dart';

// Re-export for convenience
export 'package:deepinheart/Controller/Model/emergency_announcement_model.dart'
    show EmergencyAnnouncement, EmergencyAnnouncementModel, PriorityLevel;

// Alias for clarity
typedef Announcement = EmergencyAnnouncement;
typedef AnnouncementModel = EmergencyAnnouncementModel;
