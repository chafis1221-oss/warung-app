import 'dart:math';
import '../models/product.dart';

class SearchService {
  static String normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static double jaroWinkler(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    final s1 = a.length <= b.length ? a : b;
    final s2 = a.length <= b.length ? b : a;
    final matchDistance = (s2.length ~/ 2) - 1;
    final s1Matches = List<bool>.filled(s1.length, false);
    final s2Matches = List<bool>.filled(s2.length, false);
    int matches = 0;
    for (int i = 0; i < s1.length; i++) {
      final start = i - matchDistance > 0 ? i - matchDistance : 0;
      final end = i + matchDistance + 1 < s2.length ? i + matchDistance + 1 : s2.length;
      for (int j = start; j < end; j++) {
        if (!s2Matches[j] && s1[i] == s2[j]) {
          s1Matches[i] = true; s2Matches[j] = true; matches++; break;
        }
      }
    }
    if (matches == 0) return 0.0;
    int transpositions = 0, k = 0;
    for (int i = 0; i < s1.length; i++) {
      if (s1Matches[i]) { while (!s2Matches[k]) k++; if (s1[i] != s2[k]) transpositions++; k++; }
    }
    final jaro = (matches / s1.length + matches / s2.length + (matches - transpositions / 2) / matches) / 3.0;
    int prefix = 0;
    for (int i = 0; i < min(4, s1.length); i++) { if (s1[i] == s2[i]) prefix++; else break; }
    return jaro + (prefix * 0.1 * (1 - jaro));
  }

  static int levenshtein(String a, String b) {
    final costs = List.generate(a.length + 1, (i) => List.filled(b.length + 1, 0));
    for (int i = 0; i <= a.length; i++) costs[i][0] = i;
    for (int j = 0; j <= b.length; j++) costs[0][j] = j;
    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        costs[i][j] = a[i - 1] == b[j - 1] ? costs[i - 1][j - 1] : 1 + min(costs[i - 1][j], min(costs[i][j - 1], costs[i - 1][j - 1]));
      }
    }
    return costs[a.length][b.length];
  }

  static List<Product> fuzzySearch(String query, List<Product> products) {
    if (query.isEmpty) return List.from(products);
    final normalizedQuery = normalize(query);
    final queryWords = normalizedQuery.split(' ');
    Set<int> matchedIds = {};
    for (final p in products) {
      final normalizedNama = normalize(p.nama);
      final namaWords = normalizedNama.split(' ');
      bool allWordsMatch = true;
      for (final qWord in queryWords) {
        bool wordMatched = false;
        for (final nWord in namaWords) {
          if (nWord.contains(qWord) || qWord.contains(nWord)) { wordMatched = true; break; }
          if (jaroWinkler(qWord, nWord) >= 0.80) { wordMatched = true; break; }
          if (qWord.length >= 3 && levenshtein(qWord, nWord) <= 2) { wordMatched = true; break; }
        }
        if (!wordMatched) { allWordsMatch = false; break; }
      }
      if (allWordsMatch) { matchedIds.add(p.id); continue; }
      if (queryWords.length == 1 && jaroWinkler(normalizedQuery, normalizedNama) >= 0.75) matchedIds.add(p.id);
    }
    return products.where((p) => matchedIds.contains(p.id)).toList();
  }
}
