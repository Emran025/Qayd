import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:qayd/application/vouchers/dtos/get_voucher_details_output.dart';
import 'package:qayd/data/services/attachment_storage_service.dart';
import 'package:qayd/domain/entities/voucher_attachment.dart';
import 'package:qayd/domain/repositories/attachment_repository.dart';
import 'package:qayd/domain/value_objects/attachment_id.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


/// Opens an encrypted attachment file by decrypting it to a temporary
/// directory and sharing/opening it via the OS intent system.
abstract final class AttachmentFileOpener {
  /// Decrypts [summary] and opens it using the OS file handler.
  ///
  /// Returns an error message string if the operation fails,
  /// or null on success.
  static Future<String?> open({
    required VoucherAttachmentSummary summary,
    required AttachmentRepository attachmentRepository,
    required AttachmentStorageService attachmentStorage,
    required String voucherId,
  }) async {
    try {
      // 1. Fetch the full attachment entity (has storagePath + crypto metadata)
      final attachR = await attachmentRepository.getByVoucherId(
        VoucherId(voucherId),
      );
      if (attachR.isFailure) {
        return AppStrings.couldNotLoadAttachment(
          attachR.failureOrNull?.messageAr ?? '',
        );
      }

      final attachments = attachR.valueOrNull ?? [];
      final VoucherAttachment? match = attachments
          .where((a) => a.id == AttachmentId(summary.id))
          .firstOrNull;

      if (match == null) {
        return AppStrings.theAttachmentDoesNot;
      }

      // 2. Guard: if the blob has not been downloaded yet, show a clear message.
      if (match.storagePath.isEmpty) {
        return AppStrings.attachmentNotDownloadedYet;
      }

      // 3. Decrypt to bytes
      final bytes = await attachmentStorage.decrypt(match);

      // 3. Write to a temp file
      final tempDir = await getTemporaryDirectory();
      final tempPath = p.join(tempDir.path, summary.fileName);
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(bytes);

      // 4. Open/share via OS (share_plus v12 API)
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempPath, mimeType: summary.mimeType)],
          subject: summary.fileName,
        ),
      );

      return null; // success
    } catch (e) {
      return AppStrings.errorOpeningFile(e.toString());
    }
  }
}

/// Small stateful widget that wraps a single attachment list tile and manages
/// its own loading state while the file is being decrypted and opened.
class AttachmentFileTile extends StatefulWidget {
  const AttachmentFileTile({
    super.key,
    required this.summary,
    required this.attachmentRepository,
    required this.attachmentStorage,
    required this.voucherId,
    required this.child,
  });

  final VoucherAttachmentSummary summary;
  final AttachmentRepository attachmentRepository;
  final AttachmentStorageService attachmentStorage;
  final String voucherId;

  /// The tile content — wrapped in an InkWell that triggers opening.
  final Widget child;

  @override
  State<AttachmentFileTile> createState() => _AttachmentFileTileState();
}

class _AttachmentFileTileState extends State<AttachmentFileTile> {
  bool _opening = false;

  Future<void> _open() async {
    if (_opening) return;
    setState(() => _opening = true);

    final err = await AttachmentFileOpener.open(
      summary: widget.summary,
      attachmentRepository: widget.attachmentRepository,
      attachmentStorage: widget.attachmentStorage,
      voucherId: widget.voucherId,
    );

    if (!mounted) return;
    setState(() => _opening = false);

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _opening ? null : _open,
          child: widget.child,
        ),
        if (_opening)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surface
                    .withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
