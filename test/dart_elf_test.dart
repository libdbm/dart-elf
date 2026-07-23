import 'dart:io';
import 'dart:typed_data';

import 'package:dart_elf/dart_elf.dart';
import 'package:test/test.dart';

void main() {
  group('Parsing header file', () {
    setUp(() {
      // Additional setup goes here.
    });
    test('Load statically linked ARM strings', () {
      ElfReader reader = ElfReader.fromBytes(
          File('test/data/32_arm_strings').readAsBytesSync());
      ElfFileHeader header = reader.header;
      expect(header.version, equals(1));
      expect(header.word, equals(ElfWordSize.word32Bit));
      expect(header.endian, equals(Endian.little));
      expect(header.abi, equals(ElfAbiIdentifier.systemv));
      expect(header.type, equals(ElfFileType.executable));
      expect(header.arch, equals(ElfArchitectureIdentifier.arm));
      expect(header.phentsize, equals(32));
      expect(header.phnum, equals(4));
      expect(header.shentsize, equals(40));
      expect(header.shnum, equals(17));
    });
    test('Load using a RandomAccessFile', () {
      ElfReader reader = ElfReader.fromRandomAccessFile(
          File('test/data/32_arm_strings').openSync());
      ElfFileHeader header = reader.header;
      expect(header.version, equals(1));
      expect(header.word, equals(ElfWordSize.word32Bit));
      expect(header.endian, equals(Endian.little));
      expect(header.abi, equals(ElfAbiIdentifier.systemv));
      expect(header.type, equals(ElfFileType.executable));
      expect(header.arch, equals(ElfArchitectureIdentifier.arm));
      expect(header.phentsize, equals(32));
      expect(header.phnum, equals(4));
      expect(header.shentsize, equals(40));
      expect(header.shnum, equals(17));
    });
    test('Load statically linked x64 strings', () {
      ElfReader reader = ElfReader.fromBytes(
          File('test/data/64_intel_strings').readAsBytesSync());
      ElfFileHeader header = reader.header;
      expect(header.version, equals(1));
      expect(header.word, equals(ElfWordSize.word64Bit));
      expect(header.endian, equals(Endian.little));
      expect(header.abi, equals(ElfAbiIdentifier.systemv));
      expect(header.type, equals(ElfFileType.executable));
      expect(header.arch, equals(ElfArchitectureIdentifier.x8664));
      expect(header.phentsize, equals(56));
      expect(header.phnum, equals(3));
      expect(header.shentsize, equals(64));
      expect(header.shnum, equals(16));
    });
    test('Load 64_riscv_selfie RISC-V', () {
      ElfReader reader = ElfReader.fromBytes(
          File('test/data/64_riscv_selfie').readAsBytesSync());
      ElfFileHeader header = reader.header;
      expect(header.version, equals(1));
      expect(header.word, equals(ElfWordSize.word64Bit));
      expect(header.endian, equals(Endian.little));
      expect(header.abi, equals(ElfAbiIdentifier.systemv));
      expect(header.type, equals(ElfFileType.executable));
      expect(header.arch, equals(ElfArchitectureIdentifier.riscv));
      expect(header.phentsize, equals(56));
      expect(header.phnum, equals(2));
      expect(header.shentsize, equals(0));
      expect(header.shnum, equals(0));
    });
    test('Load 32 bit shared object file', () {
      ElfReader reader = ElfReader.fromBytes(
          File('test/data/32_arm_object.o').readAsBytesSync());
      ElfFileHeader header = reader.header;
      expect(header.version, equals(1));
      expect(header.word, equals(ElfWordSize.word32Bit));
      expect(header.endian, equals(Endian.little));
      expect(header.abi, equals(ElfAbiIdentifier.systemv));
      expect(header.type, equals(ElfFileType.relocatable));
      expect(header.arch, equals(ElfArchitectureIdentifier.arm));
      expect(header.phentsize, equals(0));
      expect(header.phnum, equals(0));
      expect(header.shentsize, equals(40));
      expect(header.shnum, equals(10));
      expect(reader.sections.length, equals(10));
      expect(reader.segments.length, equals(0));
    });
    test('Load 64 bit shared object file', () {
      ElfReader reader = ElfReader.fromBytes(
          File('test/data/64_arm_object.o').readAsBytesSync());
      ElfFileHeader header = reader.header;
      expect(header.version, equals(1));
      expect(header.word, equals(ElfWordSize.word64Bit));
      expect(header.endian, equals(Endian.little));
      expect(header.abi, equals(ElfAbiIdentifier.systemv));
      expect(header.type, equals(ElfFileType.relocatable));
      expect(header.arch, equals(ElfArchitectureIdentifier.x8664));
    });
    test('Load Android ARM libncurses', () {
      ElfReader reader = ElfReader.fromBytes(
          File('test/data/32_arm_libncurses').readAsBytesSync());
      ElfFileHeader header = reader.header;
      expect(header.version, equals(1));
      expect(header.word, equals(ElfWordSize.word32Bit));
      expect(header.endian, equals(Endian.little));
      expect(header.abi, equals(ElfAbiIdentifier.systemv));
      expect(header.type, equals(ElfFileType.shared));
      expect(header.arch, equals(ElfArchitectureIdentifier.arm));
    });
    test('Load 32 bit executable file', () {
      ElfReader reader =
          ElfReader.fromBytes(File('test/data/32_arm_ls').readAsBytesSync());
      ElfFileHeader header = reader.header;
      expect(header.version, equals(1));
      expect(header.word, equals(ElfWordSize.word32Bit));
      expect(header.endian, equals(Endian.little));
      expect(header.abi, equals(ElfAbiIdentifier.systemv));
      expect(header.type, equals(ElfFileType.executable));
      expect(header.arch, equals(ElfArchitectureIdentifier.arm));
    });
    test('Load 64 bit executable file', () {
      ElfReader reader =
          ElfReader.fromBytes(File('test/data/64_intel_ls').readAsBytesSync());
      ElfFileHeader header = reader.header;
      expect(header.version, equals(1));
      expect(header.word, equals(ElfWordSize.word64Bit));
      expect(header.endian, equals(Endian.little));
      expect(header.abi, equals(ElfAbiIdentifier.systemv));
      expect(header.type, equals(ElfFileType.executable));
      expect(header.arch, equals(ElfArchitectureIdentifier.x8664));
    });
    test('Load bad-elf-file', () {
      expect(
          () => ElfReader.fromBytes(
              File('test/data/bad-elf-file').readAsBytesSync()),
          throwsA(isA<ElfFormatException>()));
    });
    test('Load ARM dynamic', () {
      ElfReader reader =
          ElfReader.fromBytes(File('test/data/32_arm_tset').readAsBytesSync());
      ElfFileHeader header = reader.header;
      expect(header.version, equals(1));
      expect(header.word, equals(ElfWordSize.word32Bit));
      expect(header.endian, equals(Endian.little));
      expect(header.abi, equals(ElfAbiIdentifier.systemv));
      expect(header.type, equals(ElfFileType.executable));
      expect(header.arch, equals(ElfArchitectureIdentifier.arm));
    });
    test('Load x64 yes', () {
      ElfReader reader =
          ElfReader.fromBytes(File('test/data/64_intel_yes').readAsBytesSync());
      ElfFileHeader header = reader.header;
      expect(header.version, equals(1));
      expect(header.word, equals(ElfWordSize.word64Bit));
      expect(header.endian, equals(Endian.little));
      expect(header.abi, equals(ElfAbiIdentifier.systemv));
      expect(header.type, equals(ElfFileType.shared));
      expect(header.arch, equals(ElfArchitectureIdentifier.x8664));
      expect(header.phentsize, equals(56));
      expect(header.phnum, equals(13));
      expect(header.shentsize, equals(64));
      expect(header.shnum, equals(31));
      expect(header.shstrndx, equals(30));
      expect(reader.sections[0].name, equals(''));
      expect(reader.sections[1].name, equals('.interp'));
      expect(reader.sections[2].name, equals('.note.gnu.property'));
      expect(reader.sections[3].name, equals('.note.gnu.build-id'));
      expect(reader.sections[4].name, equals('.note.ABI-tag'));
    });
  });

  group('Bug fixes', () {
    test('Symbol binding is parsed correctly', () {
      final reader =
          ElfReader.fromBytes(File('test/data/64_intel_yes').readAsBytesSync());
      final symbols = reader.dynamicSymbolTableSection!.symbols;
      final global =
          symbols.where((final s) => s.binding == ElfSymbolBinding.global);
      expect(global, isNotEmpty);
    });

    test('readInto reads consecutive bytes without skipping', () {
      final bytes = Uint8List.fromList([0x7f, 0x45, 0x4c, 0x46]);
      final buffer = ElfInMemoryBuffer.fromBytes(bytes);
      final dest = Uint8List(4);
      final count = buffer.readInto(dest);
      expect(count, equals(4));
      expect(dest, equals(bytes));
    });

    test('String table rejects an unterminated string', () {
      final bytes = Uint8List.fromList([0x41, 0x42, 0x43]);
      final buffer = ElfInMemoryBuffer.fromBytes(bytes);
      final table = ElfStringTable(buffer, 0, 3);
      expect(() => table.at(0), throwsA(isA<ElfFormatException>()));
    });

    test('sunSegment and sunStack have distinct values', () {
      expect(ElfSegmentType.sunSegment.id,
          isNot(equals(ElfSegmentType.sunStack.id)));
    });

    test('textrel has value 0x4', () {
      expect(ElfDynamicFlags.textrel.id, equals(0x4));
    });

    test('FreeBSD ABI name is correct', () {
      expect(ElfAbiIdentifier.freebsd.name, equals('ELFOSABI_FREEBSD'));
    });

    test('OpenBSD ABI name is correct', () {
      expect(ElfAbiIdentifier.openbsd.name, equals('ELFOSABI_OPENBSD'));
    });

    test('64-bit word size description is correct', () {
      expect(ElfWordSize.word64Bit.description, equals('64 bit ELF'));
    });

    test('Note sections parse correctly', () {
      final reader =
          ElfReader.fromBytes(File('test/data/64_intel_yes').readAsBytesSync());
      final notes = reader.sections.whereType<ElfNoteSection>().toList();
      expect(notes, isNotEmpty);
      for (final note in notes) {
        expect(note.noteName, isNotEmpty);
      }
    });

    test('RISC-V file with shnum==0 loads without error', () {
      final reader = ElfReader.fromBytes(
          File('test/data/64_riscv_selfie').readAsBytesSync());
      expect(reader.header.shnum, equals(0));
      expect(reader.sections, isEmpty);
      expect(reader.segments, isNotEmpty);
    });
  });

  // Malformed input must fail with a contextual ElfFormatException rather than
  // a RangeError, an integer division error, or unbounded work. Each case
  // perturbs exactly one field of an otherwise valid file, or drives a single
  // section parser directly.
  group('Robustness', () {
    test('Truncated file is rejected', () {
      final full = File('test/data/64_intel_yes').readAsBytesSync();
      for (final length in [0, 4, 16, 40, 63]) {
        expect(() => ElfReader.fromBytes(full.sublist(0, length)),
            throwsA(isA<ElfFormatException>()),
            reason: 'prefix of $length bytes');
      }
    });

    test('Program header offset past the end is rejected', () {
      expect(() => ElfReader.fromBytes(_patch({0x20: _le64(0x7fffffff)})),
          throwsA(isA<ElfFormatException>()));
    });

    test('Section header offset past the end is rejected', () {
      expect(() => ElfReader.fromBytes(_patch({0x28: _le64(0x7fffffff)})),
          throwsA(isA<ElfFormatException>()));
    });

    test('Undersized program header entries are rejected', () {
      expect(() => ElfReader.fromBytes(_patch({0x36: _le16(8)})),
          throwsA(isA<ElfFormatException>()));
    });

    test('Undersized section header entries are rejected', () {
      expect(() => ElfReader.fromBytes(_patch({0x3A: _le16(8)})),
          throwsA(isA<ElfFormatException>()));
    });

    test('Section name index beyond the section count is rejected', () {
      expect(() => ElfReader.fromBytes(_patch({0x3E: _le16(999)})),
          throwsA(isA<ElfFormatException>()));
    });

    test('Section name index of SHN_UNDEF yields empty names', () {
      final reader = ElfReader.fromBytes(_patch({0x3E: _le16(0)}));
      expect(reader.sections, hasLength(31));
      expect(reader.sections.every((final s) => s.name.isEmpty), isTrue);
    });

    test('Extended numbering resolves the count from section header zero', () {
      // e_shnum of zero with a section table means the real count lives in
      // sh_size of section header zero.
      final reader = ElfReader.fromBytes(_patch({
        0x3C: _le16(0),
        _shoff + 32: _le64(31),
      }));
      expect(reader.header.shnum, equals(0));
      expect(reader.sections, hasLength(31));
      expect(reader.sections[1].name, equals('.interp'));
    });

    test('SHN_XINDEX resolves the name index from section header zero', () {
      final reader = ElfReader.fromBytes(_patch({
        0x3E: _le16(0xffff),
        _shoff + 40: _le32(30),
      }));
      expect(reader.sections, hasLength(31));
      expect(reader.sections[1].name, equals('.interp'));
    });

    test('Symbol table with a zero entry size is rejected', () {
      final section = ElfSymbolTableSection(_meta(ElfWordSize.word64Bit),
          _head(type: 2, size: 48), '.symtab', _buffer(64));
      expect(() => section.symbols, throwsA(isA<ElfFormatException>()));
    });

    test('Relocation section with a zero entry size is rejected', () {
      expect(
          () => ElfRelocationSection(_meta(ElfWordSize.word64Bit),
              _head(type: 4, size: 48), '.rela', _buffer(64), true),
          throwsA(isA<ElfFormatException>()));
    });

    test('Hash table larger than its section is rejected', () {
      // A truncated .hash whose counts claim far more space than the section
      // holds. Before bounds checking this attempted billions of insertions.
      final data = <int>[..._le32(1000000), ..._le32(1000000)];
      expect(
          () => ElfHashTableSection(_meta(ElfWordSize.word64Bit),
              _head(type: 5, size: 8), '.hash', _bytes(data)),
          throwsA(isA<ElfFormatException>()));
    });

    test('String table rejects an offset past its end', () {
      final table = ElfStringTable(_bytes([0x41, 0x00, 0x42, 0x00]), 0, 2);
      expect(table.at(0), equals('A'));
      expect(() => table.at(2), throwsA(isA<ElfFormatException>()));
    });

    test('String table does not read beyond its declared size', () {
      // Four bytes of backing data, but the table only owns the first two.
      final table = ElfStringTable(_bytes([0x41, 0x42, 0x43, 0x00]), 0, 2);
      expect(() => table.at(0), throwsA(isA<ElfFormatException>()));
    });

    test('Note with a zero length name parses', () {
      final data = <int>[
        ..._le32(0), // namesz
        ..._le32(4), // descsz
        ..._le32(3), // NT_GNU_BUILD_ID
        0xde, 0xad, 0xbe, 0xef,
      ];
      final section = ElfNoteSection(_meta(ElfWordSize.word64Bit),
          _head(type: 7, size: data.length), '.note', _bytes(data));
      expect(section.notes, hasLength(1));
      expect(section.noteName, isEmpty);
      expect(section.readGnuBuildId().text, equals('deadbeef'));
    });

    test('Note section holding two records parses both', () {
      final data = <int>[
        ..._le32(4), // namesz, 'GNU\0'
        ..._le32(4), // descsz
        ..._le32(3), // NT_GNU_BUILD_ID
        0x47, 0x4e, 0x55, 0x00,
        0xde, 0xad, 0xbe, 0xef,
        ..._le32(4),
        ..._le32(4),
        ..._le32(4), // NT_GNU_GOLD_VERSION
        0x47, 0x4e, 0x55, 0x00,
        0x31, 0x2e, 0x31, 0x31,
      ];
      final section = ElfNoteSection(_meta(ElfWordSize.word64Bit),
          _head(type: 7, size: data.length), '.note', _bytes(data));
      expect(section.notes, hasLength(2));
      expect(section.notes[0].name, equals('GNU'));
      expect(section.notes[1].name, equals('GNU'));
      expect(section.readGnuBuildId(section.notes[0]).text, equals('deadbeef'));
      expect(section.readGnuGoldVersion(section.notes[1]).text, equals('1.11'));
    });

    test('Note claiming more space than its section is rejected', () {
      final data = <int>[
        ..._le32(4),
        ..._le32(0x7fffffff), // descsz far beyond the section
        ..._le32(3),
        0x47, 0x4e, 0x55, 0x00,
      ];
      expect(
          () => ElfNoteSection(_meta(ElfWordSize.word64Bit),
              _head(type: 7, size: data.length), '.note', _bytes(data)),
          throwsA(isA<ElfFormatException>()));
    });

    test('32 bit addend is read as signed', () {
      // r_addend is Elf32_Sword, so 0xfffffffc is -4 and not 4294967292.
      final data = <int>[
        ..._le32(0x1000), // r_offset
        ..._le32(0x101), // r_info
        ..._le32(0xfffffffc), // r_addend
      ];
      final section = ElfRelocationSection(
          _meta(ElfWordSize.word32Bit),
          _head(type: 4, size: 12, entsize: 12),
          '.rela.text',
          _bytes(data),
          true);
      expect(section.entries, hasLength(1));
      expect(section.entries.single.addend, equals(-4));
    });

    test('64 bit addend is read as signed', () {
      final data = <int>[
        ..._le64(0x1000),
        ..._le64(0x101),
        ...List<int>.filled(8, 0xff), // -1
      ];
      final section = ElfRelocationSection(
          _meta(ElfWordSize.word64Bit),
          _head(type: 4, size: 24, entsize: 24),
          '.rela.text',
          _bytes(data),
          true);
      expect(section.entries.single.addend, equals(-1));
    });

    test('Buffer reads past the end are rejected rather than masked', () {
      // Every EOF byte used to arrive as -1 and get masked to 0xff, so a
      // truncated read produced 0xffffffff instead of an error.
      final buffer = ElfInMemoryBuffer.fromBytes(Uint8List(0));
      expect(() => buffer.readInt(Endian.little),
          throwsA(isA<ElfFormatException>()));
      expect(() => buffer.readBytes(1024), throwsA(isA<ElfFormatException>()));
    });

    test('Seeking outside the buffer is rejected rather than clamped', () {
      final buffer = ElfInMemoryBuffer.fromBytes(Uint8List(16));
      expect(buffer.seek(16), equals(16));
      expect(() => buffer.seek(17), throwsA(isA<ElfFormatException>()));
      expect(() => buffer.seek(-1), throwsA(isA<ElfFormatException>()));
    });
  });

  group('Machine identifiers', () {
    test('0x3e is x86-64 and 0x32 is Itanium', () {
      expect(ElfArchitectureIdentifier.byId(0x3e),
          equals(ElfArchitectureIdentifier.x8664));
      expect(ElfArchitectureIdentifier.x8664.name, equals('EM_X86_64'));
      expect(ElfArchitectureIdentifier.byId(0x32),
          equals(ElfArchitectureIdentifier.itanium));
      expect(ElfArchitectureIdentifier.itanium.name, equals('EM_IA_64'));
    });

    test('Relocation identifiers match their ABI names', () {
      expect(ElfRelocationType.x8664GOT32.name, equals('R_X86_64_GOT32'));
      expect(ElfRelocationType.x8664GOT32.id, equals(3));
      expect(ElfRelocationType.x8664PLT32.name, equals('R_X86_64_PLT32'));
      expect(ElfRelocationType.x8664PLT32.id, equals(4));
    });
  });
}

/// Offset of the section header table in test/data/64_intel_yes
const int _shoff = 29120;

/// Read 64_intel_yes and overwrite the given offsets with the given bytes
Uint8List _patch(final Map<int, List<int>> edits) {
  final bytes = File('test/data/64_intel_yes').readAsBytesSync();
  edits.forEach((final offset, final values) {
    for (var i = 0; i < values.length; i++) {
      bytes[offset + i] = values[i];
    }
  });
  return bytes;
}

List<int> _le16(final int value) => [value & 0xff, (value >> 8) & 0xff];

List<int> _le32(final int value) =>
    [for (var i = 0; i < 4; i++) (value >> (i * 8)) & 0xff];

List<int> _le64(final int value) =>
    [for (var i = 0; i < 8; i++) (value >> (i * 8)) & 0xff];

ElfInMemoryBuffer _bytes(final List<int> values) =>
    ElfInMemoryBuffer.fromBytes(Uint8List.fromList(values));

ElfInMemoryBuffer _buffer(final int size) =>
    ElfInMemoryBuffer.fromBytes(Uint8List(size));

/// A minimal valid file header, for driving one section parser in isolation
ElfFileHeader _meta(final ElfWordSize word) {
  final small = word == ElfWordSize.word32Bit;
  return (
    data: Uint8List(0),
    version: 1,
    endian: Endian.little,
    word: word,
    abi: ElfAbiIdentifier.systemv,
    abiVersion: 0,
    type: ElfFileType.relocatable,
    arch: small
        ? ElfArchitectureIdentifier.i386
        : ElfArchitectureIdentifier.x8664,
    entry: 0,
    phoff: 0,
    shoff: 0,
    flags: 0,
    ehsize: small ? EHSIZE32 : EHSIZE64,
    phentsize: 0,
    phnum: 0,
    shentsize: small ? SHENTSIZE32 : SHENTSIZE64,
    shnum: 0,
    shstrndx: 0,
  );
}

ElfSectionHeader _head({
  final int type = 1,
  final int offset = 0,
  final int size = 0,
  final int entsize = 0,
}) {
  return (
    nindex: 0,
    type: type,
    flags: 0,
    addr: 0,
    offset: offset,
    size: size,
    link: 0,
    info: 0,
    align: 0,
    entsize: entsize,
  );
}
