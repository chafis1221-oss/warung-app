import 'package:fuzzy/fuzzy.dart';
import '../models/product.dart';

class SearchService {
  static String normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static List<Product> fuzzySearch(String query, List<Product> products) {
    if (query.isEmpty) return List.from(products);
    if (query.length < 2) {
      final q = normalize(query);
      return products.where((p) => normalize(p.nama).contains(q)).toList();
    }

    final normalizedQuery = normalize(query);
    final queryWords = normalizedQuery.split(' ');

    // Siapkan list string untuk Fuse
    final namaList = products.map((p) => normalize(p.nama)).toList();

    final fuse = Fuzzy(
      namaList,
      options: FuzzyOptions(
        threshold: 0.35,
        distance: 100,
      ),
    );

    Set<int> matchedIds = {};

    for (final word in queryWords) {
      if (word.length < 2) continue;
      final results = fuse.search(word);
      for (final r in results) {
        final idx = r.index;
        if (idx < products.length) {
          matchedIds.add(products[idx].id);
        }
      }
    }

    // Fallback: contains
    if (matchedIds.length < 2) {
      for (final p in products) {
        final nama = normalize(p.nama);
        if (nama.contains(normalizedQuery)) {
          matchedIds.add(p.id);
        }
        for (final nWord in nama.split(' ')) {
          for (final qWord in queryWords) {
            if (qWord.length >= 2 && nWord.contains(qWord)) {
              matchedIds.add(p.id);
            }
          }
        }
      }
    }

    return products.where((p) => matchedIds.contains(p.id)).toList();
  }
}
