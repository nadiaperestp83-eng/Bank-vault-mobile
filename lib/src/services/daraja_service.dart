import 'package:flutter_dotenv/flutter_dotenv.dart';

class DarajaService {
  final String consumerKey = dotenv.env['VITE_DARAJA_CONSUMER_KEY']!;
  final String consumerSecret = dotenv.env['VITE_DARAJA_CONSUMER_SECRET']!;
  final String env = dotenv.env['VITE_DARAJA_ENV']!;

  // Placeholder for Daraja API logic (STK Push, etc.)
  Future<void> initiateStkPush(String phoneNumber, double amount) async {
    // Logic to get access token and send STK push
  }
}
