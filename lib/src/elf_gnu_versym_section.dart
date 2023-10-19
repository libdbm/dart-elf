import 'package:dart_elf/dart_elf.dart';

/// An ELF section representing a GNU version symbol table section
class ElfGnuVersionSymbolTableSection extends ElfSection {
  ElfGnuVersionSymbolTableSection(
      super._meta, super._header, super._name, super._buffer);
}
