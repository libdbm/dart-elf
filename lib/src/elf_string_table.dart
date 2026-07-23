import 'package:dart_elf/src/elf_format_exception.dart';
import 'package:dart_elf/src/elf_io_buffer.dart';

/// An ELF string table that is created from section data.
///
/// Each string is a null terminated list of bytes. Reading strings requires
/// knowing the starting offset within the buffer
class ElfStringTable {
  final ElfIoBuffer _buffer;
  final int offset;
  final int size;

  ElfStringTable(this._buffer, this.offset, this.size);

  /// Get a string at offset [off] within the table.
  ///
  /// The ABI requires a string and its terminating null to lie inside the
  /// table, so the scan is bounded by [size] rather than running to the end of
  /// the file. Throws an [ElfFormatException] when [off] falls outside the
  /// table or the string is unterminated.
  String at(int off) {
    if (off < 0 || off >= size) {
      throw ElfFormatException(
          'String offset $off is outside the $size byte string table',
          offset: offset + off);
    }
    _buffer.seek(offset + off, absolute: true);
    final int limit = offset + size;
    final List<int> bytes = [];
    while (_buffer.offset < limit) {
      final int byte = _buffer.readByte();
      if (byte < 0) break;
      if (byte == 0) return String.fromCharCodes(bytes);
      bytes.add(byte);
    }
    throw ElfFormatException(
        'Unterminated string at offset $off in string table',
        offset: offset + off);
  }
}
