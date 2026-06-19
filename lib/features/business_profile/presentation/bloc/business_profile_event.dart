part of 'business_profile_cubit.dart';

abstract class BusinessProfileEvent extends Equatable {
  const BusinessProfileEvent();
  @override
  List<Object?> get props => const [];
}

class BusinessProfileLoadRequested extends BusinessProfileEvent {
  const BusinessProfileLoadRequested();
}

class BusinessProfileSaveRequested extends BusinessProfileEvent {
  const BusinessProfileSaveRequested(this.profile);
  final BusinessProfile profile;
  @override
  List<Object?> get props => [profile];
}
