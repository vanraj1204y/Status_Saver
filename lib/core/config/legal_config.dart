/// Local Flutter ASSET paths for the legal documents — NOT runtime URLs.
/// The HTML is fetched once per release build by tool/fetch_legal_documents.dart
/// and bundled into the app; LegalDocumentScreen loads them via
/// `loadFlutterAsset` with JavaScript disabled, so the app never makes a
/// network request to show these screens.
const String kPrivacyPolicyAsset = 'assets/legal/privacy-policy.html';
const String kTermsOfUseAsset = 'assets/legal/terms.html';
