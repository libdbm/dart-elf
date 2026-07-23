## 2.0.0

Hardening release. Malformed input is rejected with a contextual exception
rather than producing garbage values or unbounded work.

### Breaking
- Malformed files throw `ElfFormatException` instead of `StateError`, `RangeError`, or integer division errors.
- Reads past the end of a buffer throw instead of yielding `0xff` filled values, and `seek` rejects out of range offsets instead of clamping.
- `ElfStringTable.at` is bounded by the table size, and throws on an out of range offset or an unterminated string.
- `ElfReader.sections` and `ElfReader.segments` return unmodifiable lists.
- `ElfArchitectureIdentifier.ia64` and the `ElfRelocationType.ia64*` constants are deprecated aliases for their `x8664` equivalents.

### Fixed
- Machine 0x3e is now `x8664` (`EM_X86_64`); real IA-64 added as `itanium` (0x32).
- Relocation identifiers match their ABI names, correcting `ia64` (`R_X86_64_GOT32`) and `ia64GOT32` (`R_X86_64_PLT32`).
- 32 bit `r_addend` is read as a signed `Elf32_Sword`.
- Note sections parse every record instead of only the first, and accept a zero length name.
- Extended section numbering is supported: `e_shnum == 0` resolves the count from section header zero, `SHN_XINDEX` resolves the name index, and `e_shstrndx == SHN_UNDEF` yields empty names.
- Valid files with no program headers are no longer rejected.
- `ElfSection.type` resolves against the file architecture, so it agrees with the class the reader built.
- Section accessors select on runtime type instead of casting on a type id or a section name.
- Symbol tables are parsed once and cached, removing a quadratic access path.
- The file backed buffer seeks only when its position drifts, instead of once per byte.

### Added
- `ElfFormatException`, carrying a message and file offset.
- `ElfNote` record and `ElfNoteSection.notes`.
- `ElfReader.fromFile` and `ElfReader.close` for reader owned file handles.
- Validation of header, table, and section geometry against the file size.

## 1.0.2
- Various bug fixes.

## 1.0.1
- Package updates

## 1.0.0

- Initial version.
