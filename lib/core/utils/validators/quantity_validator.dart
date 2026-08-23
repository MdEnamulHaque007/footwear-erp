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
    if (!isWithinLimit(cuttingQuantity, availablePOQuantity)) {
      return 'Cutting quantity ($cuttingQuantity) exceeds available PO quantity ($availablePOQuantity)';
    }
    return null;
  }
}
