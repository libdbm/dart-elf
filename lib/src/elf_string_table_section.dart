import 'package:dart_elf/src/elf_string_table.dart';

import 'elf_section.dart';

/// A section containing a string table
class ElfStringTableSection extends ElfSection {
  final ElfStringTable _table;

  ElfStringTableSection(super._meta, super._header, super._name, super._buffer)
      : _table = ElfStringTable(_buffer, _header.offset, _header.size);

  ElfStringTable get table => _table;
}
