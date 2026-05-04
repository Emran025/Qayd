import 'package:flutter/material.dart';
import 'package:qayd/data/messaging/messaging_intent_launcher.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


enum ShareMethod { system, whatsappStandard, whatsappBusiness }

class ShareMethodPicker {
  static Future<ShareMethod?> show(BuildContext context) async {
    final hasStandard =
        await MessagingIntentLauncher.isPackageInstalled(WhatsAppFlavor.standard);
    final hasBusiness =
        await MessagingIntentLauncher.isPackageInstalled(WhatsAppFlavor.business);

    if (!context.mounted) return null;
    return showModalBottomSheet<ShareMethod>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                AppStrings.chooseHowToShare,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: Icon(Icons.share, color: Colors.blue),
              title:  Text(AppStrings.sharingAcrossTheSystem),
              onTap: () => Navigator.of(ctx).pop(ShareMethod.system),
            ),
            if (hasStandard)
              ListTile(
                leading: Icon(Icons.chat, color: Colors.green),
                title: Text(WhatsAppFlavor.standard.displayName),
                onTap: () => Navigator.of(ctx).pop(ShareMethod.whatsappStandard),
              ),
            if (hasBusiness)
              ListTile(
                leading: Icon(Icons.store, color: Colors.teal),
                title: Text(WhatsAppFlavor.business.displayName),
                onTap: () => Navigator.of(ctx).pop(ShareMethod.whatsappBusiness),
              ),
          ],
        ),
      ),
    );
  }
}

class WhatsAppFlavorPicker {
  static Future<WhatsAppFlavor?> show(BuildContext context) async {
    final hasStandard =
        await MessagingIntentLauncher.isPackageInstalled(WhatsAppFlavor.standard);
    final hasBusiness =
        await MessagingIntentLauncher.isPackageInstalled(WhatsAppFlavor.business);

    if (!hasStandard && !hasBusiness) {
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(AppStrings.whatsappIsNotInstalled)),
      );
      return null;
    }

    if (hasStandard && !hasBusiness) return WhatsAppFlavor.standard;
    if (!hasStandard && hasBusiness) return WhatsAppFlavor.business;

    if (!context.mounted) return null;
    return showModalBottomSheet<WhatsAppFlavor>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                AppStrings.chooseTheAppTo,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: Icon(Icons.chat, color: Colors.green),
              title: Text(WhatsAppFlavor.standard.displayName),
              onTap: () => Navigator.of(ctx).pop(WhatsAppFlavor.standard),
            ),
            ListTile(
              leading: Icon(Icons.store, color: Colors.teal),
              title: Text(WhatsAppFlavor.business.displayName),
              onTap: () => Navigator.of(ctx).pop(WhatsAppFlavor.business),
            ),
          ],
        ),
      ),
    );
  }
}
