part of 'business_profile_cubit.dart';

class BusinessProfileState extends Equatable {
  const BusinessProfileState({this.loading = false, this.saving = false, this.profile});

  factory BusinessProfileState.initial() => const BusinessProfileState();

  final bool loading;
  final bool saving;
  final BusinessProfile? profile;

  BusinessProfileState copyWith({bool? loading, bool? saving, BusinessProfile? profile}) =>
      BusinessProfileState(
        loading: loading ?? this.loading,
        saving: saving ?? this.saving,
        profile: profile ?? this.profile,
      );

  @override
  List<Object?> get props => [loading, saving, profile];
}
