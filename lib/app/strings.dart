/// All user-visible copy lives here so it can be localized later.
abstract final class AppStrings {
  static const appName = 'Status Saver';
  static const appVersion = '1.0.0';

  // Navigation
  static const navStatuses = 'Statuses';
  static const navDownloads = 'Downloads';
  static const navHowTo = 'How to Use';
  static const navSettings = 'Settings';

  // Home
  static const recentStatuses = 'Recent Statuses';
  static const tabPhotos = 'Photos';
  static const tabVideos = 'Videos';
  static const tabAll = 'All';
  static const refresh = 'Refresh';
  static const download = 'Download';
  static const saved = 'Saved';

  // States
  static const loadingStatuses = 'Looking for statuses…';
  static const emptyStatusesTitle = 'No statuses found';
  static const emptyStatusesBody =
      'View a few statuses in WhatsApp, then come back and refresh. Only statuses still available on your device can appear here.';
  static const emptyPhotosTitle = 'No photo statuses';
  static const emptyVideosTitle = 'No video statuses';
  static const emptyDownloadsTitle = 'Nothing saved yet';
  static const emptyDownloadsBody =
      'Statuses you download will appear here, and stay even after they disappear from WhatsApp.';
  static const openStatuses = 'Go to Statuses';
  static const errorTitle = 'Something went wrong';
  static const tryAgain = 'Try again';

  // Permissions
  static const permissionTitle = 'Allow access to statuses';
  static const permissionBody =
      'Status Saver needs permission to read the status media that WhatsApp keeps on this device. Nothing is uploaded anywhere.';
  static const permissionButton = 'Allow access';
  static const permissionDeniedTitle = 'Permission needed';
  static const permissionDeniedBody =
      'Access was denied, so statuses can\'t be shown. You can grant the permission from the app settings.';
  static const openAppSettings = 'Open app settings';
  static const safTitle = 'Select the status folder';
  static const safBody =
      'On this Android version, the system asks you to confirm access to WhatsApp\'s status folder. On the next screen, simply tap "Use this folder".';
  static const safButton = 'Select folder';
  static const safDenied = 'Folder access was not granted. Please try again and tap "Use this folder".';

  // Actions & results
  static const savedSuccessfully = 'Saved successfully';
  static const alreadySaved = 'Already saved';
  static const share = 'Share';
  static const sendToWhatsApp = 'WhatsApp';
  static const save = 'Save';
  static const delete = 'Delete';
  static const open = 'Open';
  static const cancel = 'Cancel';
  static const deleteTitle = 'Delete this file?';
  static const deleteBody =
      'The file will be removed from your saved statuses and from your gallery.';
  static const deleted = 'File deleted';
  static const deleteFailed = 'The file could not be deleted';
  static const whatsappMissing = 'WhatsApp is not installed — opening the share sheet instead';
  static const shareFailed = 'Sharing failed. Please try again.';
  static const noAppToOpen = 'No app on this device can open this file';
  static const saveFailed = 'Could not save this status. Please try again.';
  static const fileGone = 'This status is no longer available on the device';
  static const videoError = 'This video can\'t be played';

  // Video
  static const mute = 'Mute';
  static const unmute = 'Unmute';
  static const play = 'Play';
  static const pause = 'Pause';

  // How to use
  static const howToTitle = 'How to Save a Status';
  static const howToStep1Title = 'Open WhatsApp';
  static const howToStep1Body = 'Open WhatsApp and go to the Updates tab.';
  static const howToStep2Title = 'View a status';
  static const howToStep2Body =
      'Watch the photo or video statuses you want to keep.';
  static const howToStep3Title = 'Return to Status Saver';
  static const howToStep3Body =
      'Come back here and pull to refresh — the statuses you viewed will appear.';
  static const howToStep4Title = 'Download or share';
  static const howToStep4Body =
      'Tap a status to preview it, then download it or share it with one tap.';
  static const howToNote =
      'Status Saver can only display statuses that have already been viewed and are still available on your device. It is not affiliated with WhatsApp.';

  // Settings
  static const settingsGeneral = 'General';
  static const settingsAppearance = 'Appearance';
  static const settingsMedia = 'Media';
  static const settingsAbout = 'About';
  static const autoSave = 'Auto Save';
  static const autoSaveSub = 'Automatically save every new status when refreshing';
  static const downloadQuality = 'Download Quality';
  static const downloadQualitySub =
      'Original — statuses are always saved exactly as WhatsApp stores them';
  static const downloadFolder = 'Download Folder';
  static const downloadFolderSub = 'Pictures/Status Saver and Movies/Status Saver';
  static const notifications = 'Save confirmations';
  static const notificationsSub = 'Show a message when a status is saved';
  static const theme = 'Theme';
  static const themeSystem = 'System Default';
  static const themeLight = 'Light';
  static const themeDark = 'Dark';
  static const autoplay = 'Video autoplay';
  static const autoplaySub = 'Start playing videos as soon as they open';
  static const muteByDefault = 'Mute videos by default';
  static const muteByDefaultSub = 'Videos open silently, tap to unmute';
  static const confirmDelete = 'Confirm before delete';
  static const confirmDeleteSub = 'Ask before removing a saved status';
  static const privacy = 'Privacy Policy';
  static const terms = 'Terms of Use';
  static const about = 'About';
  static const appVersionLabel = 'App version';

  static const privacyText =
      'Status Saver runs entirely on your device. It reads status media that WhatsApp already stores on your phone, and saves copies only to your own gallery. No data is collected, tracked, or uploaded anywhere.';
  static const termsText =
      'Status Saver is provided as-is, for personal use. Please respect the privacy of others: always ask before saving or re-sharing someone else\'s status. This app is not affiliated with, endorsed by, or connected to WhatsApp LLC.';
  static const aboutText =
      'Status Saver lets you keep and share the WhatsApp status photos and videos that are already on your device — with a fast gallery, a built-in video player, and one-tap sharing.';
}
