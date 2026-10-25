import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';

class UploadBox extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const UploadBox({
    super.key,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
        onTap: onTap,
        child: DottedBorder(
          // dashPattern: const [6, 3],
          // radius: const Radius.circular(12),
          // borderType: BorderType.RRect,
          child: SizedBox(
            height: 130,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.image_outlined,
                    color: colors.primaryContainer,
                  ),
                  const SizedBox(height: 8),
                  Text(title),
                ],
              ),
            ),
          ),
        ));
  }
}
