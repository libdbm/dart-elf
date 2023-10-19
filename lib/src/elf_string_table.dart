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
  String at(int off) {
    _buffer.seek(offset + off, absolute: true);
    List<int> bytes = [];
    int byte = _buffer.readByte();
    while (byte != 0) {
      if (byte != 0) {
        bytes.add(byte);
      }
      byte = _buffer.readByte();
    }
    return String.fromCharCodes(bytes);
  }
}
