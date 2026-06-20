import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:invoice_kit/features/business_profile/data/repositories/business_profile_repository.dart';
import 'package:invoice_kit/features/business_profile/domain/entities/business_profile.dart';

part 'business_profile_event.dart';
part 'business_profile_state.dart';

class BusinessProfileCubit extends Cubit<BusinessProfileState> {
  BusinessProfileCubit({required this.repo})
    : super(BusinessProfileState.initial());

  final BusinessProfileRepository repo;

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    final profile = await repo.load();
    emit(state.copyWith(loading: false, profile: profile));
  }

  Future<void> save(BusinessProfile profile) async {
    emit(state.copyWith(saving: true));
    await repo.save(profile);
    emit(state.copyWith(saving: false, profile: profile));
  }
}
