/// API Configuration
/// 
/// To use the Merriam-Webster Dictionary API:
/// 1. Go to https://dictionaryapi.com/register/index
/// 2. Sign up for a free account
/// 3. Get your "Collegiate Dictionary" API key
/// 4. Replace 'YOUR_API_KEY_HERE' below with your actual API key
///
/// Example: static const String merriamWebsterApiKey = 'abc123-def456-ghi789';
///
/// Note: The app will work without the API key by using the fallback dictionary,
/// but Merriam-Webster provides more accurate and detailed definitions.

class ApiConfig {
  /// 🔑 PUT YOUR MERRIAM-WEBSTER API KEY HERE
  /// Get it from: https://dictionaryapi.com/register/index
  static const String merriamWebsterApiKey = 'YOUR API KEY';
  
  // Check if API key is configured
  static bool get isMerriamWebsterConfigured => 
      merriamWebsterApiKey != 'YOUR_API_KEY_HERE' && 
      merriamWebsterApiKey.isNotEmpty;
}
