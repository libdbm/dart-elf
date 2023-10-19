import 'dart:typed_data';

import '../dart_elf.dart';

/// An ELF section, which is also a superclass for specific section types.
class ElfSection {
  final String _name;
  final ElfFileHeader _meta;
  final ElfSectionHeader _header;
  final ElfIoBuffer _buffer;

  /// Get the resolve name of the section
  String get name => _name;

  /// Get the ELF file header
  ElfFileHeader get meta => _meta;

  /// Get the ELF section header
  ElfSectionHeader get header => _header;

  /// Get the ELF section type
  ElfSectionType get type => ElfSectionType.byId(_header.type);

  /// Get the IO buffer used to parse the section
  ElfIoBuffer get buffer => _buffer;

  ElfSection(this._meta, this._header, this._name, this._buffer);

  /// Read the raw data for the section
  Uint8List data() {
    _buffer.seek(_header.offset, absolute: true);
    return _buffer.readBytes(_header.size);
  }
}
