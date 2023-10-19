import 'elf_section.dart';

/// An ELF section representing a GNU version needed
class ElfGnuVersionNeededSection extends ElfSection {
  ElfGnuVersionNeededSection(
      super._meta, super._header, super._name, super._buffer);
}
