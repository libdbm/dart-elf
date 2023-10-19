import 'package:dart_elf/dart_elf.dart';

/// An ELF section containing information needed for dynamic linking.
class ElfDynamicSection extends ElfSection {
  final List<ElfDynamicEntry> _entries;

  ElfDynamicSection(super._meta, super._header, super._name, super._buffer)
      : _entries = _loadDynamicEntries(_meta, _header, _buffer);

  /// A possibly empty list of dynamic section entries
  List<ElfDynamicEntry> get entries => _entries;

  static List<ElfDynamicEntry> _loadDynamicEntries(
      ElfFileHeader meta, ElfSectionHeader header, ElfIoBuffer buffer) {
    List<ElfDynamicEntry> ret = [];
    buffer.seek(header.offset, absolute: true);
    int count = header.size ~/ (meta.word == ElfWordSize.word32Bit ? 8 : 16);
    for (int i = 0; i < count; i++) {
      var tag = meta.word == ElfWordSize.word32Bit
          ? buffer.readInt(meta.endian)
          : buffer.readLong(meta.endian);
      var value = meta.word == ElfWordSize.word32Bit
          ? buffer.readInt(meta.endian)
          : buffer.readLong(meta.endian);
      ret.add((tag: tag, value: value));
      if (tag == ElfDynamicTag.none.id) break;
    }
    return ret;
  }
}
