/// Product storage is decimal; technical binary values need KiB/MiB/GiB labels.
const decimalGb = 1000000000;
const storageUnitBytes = <String, int>{
  'B': 1,
  'kB': 1000,
  'MB': 1000000,
  'GB': decimalGb,
  'TB': 1000000000000,
};

/// Convert a decimal input exactly, rounding search thresholds half-up once.
int? storageInputBytes(String input, String unit) {
  final raw = input.trim().replaceAll(',', '.');
  if (!RegExp(r'^\d+(?:\.\d+)?$').hasMatch(raw)) return null;
  final factor = storageUnitBytes[unit];
  if (factor == null || raw.length > 400) return null;
  final parts = raw.split('.');
  final fraction = parts.length == 2 ? parts[1] : '';
  final denominator = BigInt.from(10).pow(fraction.length);
  final numerator = BigInt.parse('${parts[0]}$fraction') * BigInt.from(factor);
  final bytes = (numerator + denominator ~/ BigInt.two) ~/ denominator;
  if (bytes > BigInt.from(9007199254740991)) return null;
  return bytes.toInt();
}
