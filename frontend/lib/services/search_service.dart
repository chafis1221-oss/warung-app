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
    
    final normalizedQuery = normalize(query);
    
    // Query pendek: exact contains only
    if (normalizedQuery.length < 3) {
      return products.where((p) => normalize(p.nama).contains(normalizedQuery)).toList();
    }

    final queryWords = normalizedQuery.split(' ').where((w) => w.length >= 2).toList();
    if (queryWords.isEmpty) return List.from(products);

    final namaList = products.map((p) => normalize(p.nama)).toList();

    final fuse = Fuzzy(
      namaList,
      options: FuzzyOptions(
        threshold: 0.45,  // Lebih strict
        distance: 50,
      ),
    );

    Set<String> matchedNames = {};

    for (final word in queryWords) {
      final results = fuse.search(word);
      for (final r in results) {
        matchedNames.add(r.item.toString());
      }
    }

    // Fallback: contains (hanya jika hasil fuse sedikit)
    if (matchedNames.length < 2) {
      for (final p in products) {
        final nama = normalize(p.nama);
        // Full contains
        if (nama.contains(normalizedQuery)) {
          matchedNames.add(nama);
        }
        // Per kata contains
        for (final nWord in nama.split(' ')) {
          for (final qWord in queryWords) {
            if (qWord.length >= 3 && nWord.contains(qWord)) {
              matchedNames.add(nama);
            }
          }
        }
      }
    }

    return products.where((p) => matchedNames.contains(normalize(p.nama))).toList();
  }
}
