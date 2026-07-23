/// Thrown when an ELF file is malformed, truncated, or internally inconsistent.
///
/// This signals bad input rather than a defect in the library. Every parsing
/// path that acts on a value read from the file validates it first and throws
/// this exception when the value cannot be trusted.
class ElfFormatException implements Exception {
  /// A description of what was rejected
  final String message;

  /// The file offset the failure relates to, or -1 when not applicable
  final int offset;

  ElfFormatException(this.message, {this.offset = -1});

  @override
  String toString() {
    if (offset < 0) {
      return 'ElfFormatException: $message';
    }
    return 'ElfFormatException: $message (at offset 0x${offset.toRadixString(16)})';
  }
}
