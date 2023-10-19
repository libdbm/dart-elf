import 'elf_section.dart';

/// An ELF section representing a GNU version definition table
class ElfGnuVersionDefinitionSection extends ElfSection {
  ElfGnuVersionDefinitionSection(
      super._meta, super._header, super._name, super._buffer);
}
