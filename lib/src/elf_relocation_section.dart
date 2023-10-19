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
        addend: hasAddend ? buffer.readInt(meta.endian) : null
      );
    }

    return (
      offset: buffer.readLong(meta.endian),
      info: buffer.readLong(meta.endian),
      addend: hasAddend ? buffer.readLong(meta.endian) : null
    );
  }
}
