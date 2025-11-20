import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/photo_cubit.dart';
import '../bloc/photo_state.dart';
import '../../core/injection.dart';
import '../../../../widgets/primary_app_bar.dart';
import '../../../../widgets/loading_view.dart';
import '../../../../widgets/error_view.dart';
import '../widgets/photo_gallery_widget.dart';

/// Page displaying all media for a trip.
class TripMediaGalleryPage extends StatelessWidget {
  final String tripId;

  const TripMediaGalleryPage({
    super.key,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = createPhotoCubit();
        cubit.loadPhotosForTrip(tripId);
        return cubit;
      },
      child: Scaffold(
        appBar: PrimaryAppBar(
          title: 'Media Gallery',
        ),
        body: BlocBuilder<PhotoCubit, PhotoState>(
          builder: (context, state) {
            if (state is PhotosLoading) {
              return const LoadingView();
            }

            if (state is PhotosLoaded) {
              return PhotoGalleryWidget(
                photos: state.photos,
                onPhotoTap: (photo) {
                  // TODO: Show full-screen photo viewer
                },
                onPhotoDelete: (photo) {
                  final cubit = context.read<PhotoCubit>();
                  cubit.deletePhotoById(photo.id, photo.journalEntryId);
                },
              );
            }

            if (state is PhotosError) {
              return ErrorView(
                message: state.message,
                onRetry: () {
                  final cubit = context.read<PhotoCubit>();
                  cubit.loadPhotosForTrip(tripId);
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

