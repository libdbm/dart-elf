import '../dart_elf.dart';

/// A section containing relocation items
class ElfRelocationSection extends ElfSection {
  final bool _hasAddends;
  final List<ElfRelocation> _entries;

  ElfRelocationSection(
      super._meta, super._header, super._name, super._buffer, this._hasAddends)
      : _entries = _parseEntries(_meta, _header, _buffer, _hasAddends);

  /// Get the flag indicating if this section includes addends
  bool get hasAddends => _hasAddends;

  /// Get the entries
  List<ElfRelocation> get entries => _entries;

  static List<ElfRelocation> _parseEntries(ElfFileHeader meta,
      ElfSectionHeader header, ElfIoBuffer buffer, bool hasAddends) {
    final int minimum = meta.word == ElfWordSize.word32Bit
        ? (hasAddends ? 12 : 8)
        : (hasAddends ? 24 : 16);
    if (header.entsize < minimum) {
      throw ElfFormatException(
          'Relocation entry size ${header.entsize} is below the minimum $minimum',
          offset: header.offset);
    }
    List<ElfRelocation> ret = [];
    buffer.seek(header.offset, absolute: true);
    for (int i = 0; i < header.size ~/ header.entsize; i++) {
      final int offset = header.offset + (i * header.entsize);
      ret.add(_parseEntry(meta, buffer, offset, hasAddends));
    }
    return ret;
  }

  static ElfRelocation _parseEntry(
      ElfFileHeader meta, ElfIoBuffer buffer, int offset, bool hasAddend) {
    buffer.seek(offset, absolute: true);
    // differs based on word size
    if (meta.word == ElfWordSize.word32Bit) {
      return (
        offset: buffer.readInt(meta.endian),
        info: buffer.readInt(meta.endian),
        addend: hasAddend ? _signed(buffer.readInt(meta.endian)) : null
      );
    }

    // A 64 bit addend needs no conversion. readLong shifts the top byte into
    // the sign bit of a Dart int, which is already 64 bit two's complement.
    return (
      offset: buffer.readLong(meta.endian),
      info: buffer.readLong(meta.endian),
      addend: hasAddend ? buffer.readLong(meta.endian) : null
    );
  }

  /// Reinterpret an unsigned 32 bit read as the signed Elf32_Sword the ABI
  /// defines r_addend to be
  static int _signed(final int value) {
    return (value & 0x80000000) != 0 ? value - 0x100000000 : value;
  }
}
