class QuickAddParseResult {
  final String name;
  final int quantity;
  final double price;
  final String notes;
  QuickAddParseResult({
    required this.name,
    required this.quantity,
    required this.price,
    required this.notes,
  });
}

class QuickAddParser {
  static QuickAddParseResult parse(String raw) {
    String input = raw.trim();
    if (input.isEmpty) {
      return QuickAddParseResult(name: '', quantity: 1, price: 0, notes: '');
    }
    int quantity = 1;
    double price = 0;
    String notes = '';

    final noteRegex = RegExp(r'(?:note:|n:)([^@]+)', caseSensitive: false);
    final noteMatch = noteRegex.firstMatch(input);
    if (noteMatch != null) {
      notes = noteMatch.group(1)!.trim();
      input = input.replaceFirst(noteMatch.group(0)!, '').trim();
    }

    final atPrice = RegExp(r'@([0-9]+(?:\.[0-9]+)?)');
    final atMatch = atPrice.firstMatch(input);
    if (atMatch != null) {
      price = double.tryParse(atMatch.group(1)!) ?? 0;
      input = input.replaceFirst(atMatch.group(0)!, '').trim();
    } else {
      final trailingNumber = RegExp(r'(.*)\s([0-9]+(?:\.[0-9]+)?)$');
      final m = trailingNumber.firstMatch(input);
      if (m != null) {
        price = double.tryParse(m.group(2)!) ?? 0;
        input = m.group(1)!.trim();
      }
    }

    final qtyRegex = RegExp(r'^(\d+)[xX ]');
    final qm = qtyRegex.firstMatch(input);
    if (qm != null) {
      quantity = int.tryParse(qm.group(1)!) ?? 1;
      input = input.substring(qm.group(0)!.length).trim();
    }

    final qtyUnitName = RegExp(r'^(\d+)([a-zA-Z]{1,4})\s+');
    final qum = qtyUnitName.firstMatch(input);
    if (qum != null) {
      quantity = int.tryParse(qum.group(1)!) ?? quantity;
      input = input.substring(qum.group(0)!.length).trim();
    }

    final name = input.trim();
    return QuickAddParseResult(
      name: name,
      quantity: quantity,
      price: price,
      notes: notes,
    );
  }
}
