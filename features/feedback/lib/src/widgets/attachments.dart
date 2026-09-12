import 'dart:io';

import 'package:core/core.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../bloc/feedback_bloc.dart';

class Attachments extends StatefulWidget {
  final List<String> attachmentPaths;

  const Attachments({super.key, required this.attachmentPaths});

  @override
  State<StatefulWidget> createState() => _Attachments();
}

class _Attachments extends State<Attachments> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(LocaleKeys.attachments_max.tr(), style: AppFonts.normal14),
            const Spacer(),
            if (widget.attachmentPaths.length < 3)
              IconButton(
                icon: const Icon(Icons.add_a_photo),
                onPressed: () async {
                  final XFile? file = await _picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (file != null && context.mounted) {
                    context.read<FeedbackBloc>().add(
                      AddAttachments([file.path]),
                    );
                  }
                },
              ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: widget.attachmentPaths.map((path) {
            return Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.accentLight),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(path), fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  top: -10,
                  right: -10,
                  child: IconButton(
                    icon: Icon(Icons.cancel, color: colors.redAccent, size: 20),
                    onPressed: () => context.read<FeedbackBloc>().add(
                      RemoveAttachment(path),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
