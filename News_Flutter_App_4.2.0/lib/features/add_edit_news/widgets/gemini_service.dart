import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';
import 'package:news/utils/ui_utils.dart';

/// AI Service Module using Google Gemini API
/// This module contains all AI-related API calls for the application

class GeminiService {
  // static const String _geminiApiKey = "set decripted Key here"; //String.fromEnvironment("GEMINI_API_KEY");
  // static const String _geminiApiUrl = "https://generativelanguage.googleapis.com/v1beta/models";
  static const String _geminiModel = "gemini-3.1-flash-lite";
  // Or gemini-1.5-pro

  /// Key fetched from the backend (author-only endpoint), kept for the session.
  static String? _cachedApiKey;

  /// Fetches the Gemini API key from `get_gemini_api_key`, which is authorised
  /// with the logged-in user's JWT. Failures are not cached, so a later call
  /// (e.g. after the user becomes an author) retries.
  static Future<String> _getApiKey() async {
    final cached = _cachedApiKey;
    if (cached != null && cached.isNotEmpty) return cached;

    final result =
        await Api.sendApiRequest(body: {}, url: Api.getGeminiApiKeyApi);

    // The API sends `error` as a bool, which sendApiRequest's check misses.
    if (result['error'] == true || result['error'] == 'true') {
      throw ApiException(result['message']?.toString() ?? '');
    }

    final data = result['data'];
    final raw = (data is Map
            ? (data[GEMINI_API_KEY] ??
                data['gemini_api_key'] ??
                data['api_key'] ??
                data['key'])
            : data)
        ?.toString()
        .trim();
    if (raw == null || raw.isEmpty) {
      throw ApiException('Gemini API key not returned');
    }

    // Google keys start with "AIza"; otherwise treat it as the base64 form the
    // old system-settings value used.
    final key = raw.startsWith('AIza')
        ? raw
        : UiUtils.decryptKey(geminiKey: raw).trim();
    return _cachedApiKey = key;
  }

  /// Helper function to call Gemini API
  static Future<Map<String, dynamic>> _callGeminiAPI(String prompt) async {
    try {
      final apiKey = await _getApiKey();
      final requestBody = {
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      };

      // Api.dio carries the curl logger, so this request prints in the console.
      final response = await Api.dio.post(
        "${Api.geminiMetaInfoApi}$_geminiModel:generateContent",
        queryParameters: {"key": apiKey},
        data: requestBody,
        options: Options(
          headers: {"Content-Type": "application/json"},
          // Keep the status handling below instead of letting dio throw.
          validateStatus: (_) => true,
        ),
      );

      final data = response.data is String
          ? jsonDecode(response.data)
          : response.data;

      if (response.statusCode != 200) {
        throw Exception(
            data?["error"]?["message"] ?? "Failed to generate content");
      }

      return Map<String, dynamic>.from(data);
    } catch (e) {
      print("Gemini API error: $e");
      rethrow;
    }
  }

  /// Generate meta info
  static Future<Map<String, dynamic>> generateMetaInfo(
      {required String title,
      required BuildContext context,
      String? language,
      String? languageCode,
      bool slugOnly = false}) async {
    try {
      String languageInstruction = "";
      if (language != null && languageCode != null) {
        languageInstruction =
            "\n\nIMPORTANT: Generate all content in $language language ($languageCode). The response MUST be in same language as title.";
      }

      final prompt = """
You are an SEO expert. Generate meta title, description, keywords, and a slug for this news article titled: "$title".$languageInstruction

Return ONLY a JSON object with these fields:
- meta_title
- meta_description
- meta_keywords
- slug

Response must be valid JSON.
""";

      final response = await _callGeminiAPI(prompt);
      final responseText =
          response["candidates"][0]["content"]["parts"][0]["text"].trim();

      try {
        return jsonDecode(responseText);
      } catch (_) {
        final match = RegExp(r"\{[\s\S]*\}").firstMatch(responseText);
        if (match != null) {
          return jsonDecode(match.group(0)!);
        }
        return {
          "meta_title": title,
          "meta_description": "Read about $title in our latest news article.",
          "meta_keywords": title.toLowerCase().split(" ").join(","),
          "slug": title
              .toLowerCase()
              .replaceAll(RegExp(r'[^a-z0-9]+'), "-")
              .replaceAll(RegExp(r'^-|-$'), ""),
        };
      }
    } catch (e) {
      print("AI meta generation error: $e");
      // showSnackBar("Error generating meta information.\n$e", context);
      rethrow;
    }
  }

  /// Summarize description
  static Future<String> summarizeDescription(String description,
      {String language = "English", String languageCode = "en"}) async {
    try {
      if (description.trim().isEmpty) return "";

      final cleanContent =
          description.replaceAll(RegExp(r"<[^>]*>"), "").trim();
      if (cleanContent.isEmpty) return "";

      final prompt = """
You are a skilled content summarizer. Summarize the following news content:

Content: "$cleanContent"

Instructions:
- 200-250 words
- Maintain key facts
- Professional news style
- No explanations, only summary
- IMPORTANT: Generate in $language ($languageCode).

Summary:""";

      final response = await _callGeminiAPI(prompt);
      final summary =
          response["candidates"][0]["content"]["parts"][0]["text"].trim();

      String finalSummary =
          summary.replaceAll(RegExp(r"^['\']+|['\']+$"), '').trim();
      return finalSummary;
    } catch (e) {
      print("Summarization error: $e");
      return description.replaceAll(RegExp(r"<[^>]*>"), "").substring(0, 150) +
          "...";
    }
  }
}
