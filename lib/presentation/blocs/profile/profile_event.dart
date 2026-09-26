/// ============================================================================
/// ফাইল: lib/presentation/blocs/profile/profile_event.dart
/// স্তর: Presentation BLoC | মডিউল: ERP Common
/// উদ্দেশ্য: ERP Common screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: ProfileEvent, SaveProfile
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'package:equatable/equatable.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class SaveProfile extends ProfileEvent {
  const SaveProfile(this.displayName);

  final String displayName;

  @override
  List<Object?> get props => [displayName];
}
