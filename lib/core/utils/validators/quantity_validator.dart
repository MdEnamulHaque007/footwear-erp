class QuantityValidator {
  static bool isValidQuantity(int quantity) => quantity > 0;

  static bool isWithinLimit(int quantity, int limit) => quantity <= limit;

  static String? validateCuttingQuantity(
    int cuttingQuantity,
    int availablePOQuantity,
  ) {
    if (!isValidQuantity(cuttingQuantity)) {
      return 'Quantity must be greater than 0';
    }
    // Cutting is the only soft-limit stage. It may exceed the remaining PO
    // balance; callers use [cuttingExcess] to report the over-cut quantity.
    return null;
  }

  static int cuttingExcess(int cuttingQuantity, int availablePOQuantity) {
    final excess = cuttingQuantity - availablePOQuantity;
    return excess > 0 ? excess : 0;
  }
}
