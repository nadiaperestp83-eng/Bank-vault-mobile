import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';

class KycService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextRecognizer _textRecognizer = TextRecognizer();

  // 1. Check if user is verified
  Future<bool> isUserVerified() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('profiles')
        .select('kyc_status')
        .eq('id', userId)
        .single();

    return response['kyc_status'] == 'verified';
  }

  // 2. Scan Document (ML Kit)
  Future<String> scanDocument(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    
    // For now, return the raw text for validation against profile
    return recognizedText.text;
  }

  // 3. Update KYC status
  Future<void> updateKycStatus(String status, {String? idNumber}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final Map<String, dynamic> updates = {'kyc_status': status};
    if (idNumber != null) {
      updates['id_number'] = idNumber;
    }

    await _supabase
        .from('profiles')
        .update(updates)
        .eq('id', userId);
  }

  void dispose() {
    _textRecognizer.close();
  }
}
