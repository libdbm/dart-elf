import 'elf_section.dart';

/// An ELF section representing a GNU hash table
class ElfGnuHashTableSection extends ElfSection {
  ElfGnuHashTableSection(
      super._meta, super._header, super._name, super._buffer);
}
