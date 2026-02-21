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
      expect(header.arch, equals(ElfArchitectureIdentifier.ia64));
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
      expect(header.arch, equals(ElfArchitectureIdentifier.ia64));
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
      expect(header.arch, equals(ElfArchitectureIdentifier.ia64));
    });
    test('Load bad-elf-file', () {
      expect(
          () => ElfReader.fromBytes(
              File('test/data/bad-elf-file').readAsBytesSync()),
          throwsA(TypeMatcher<StateError>()));
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
      expect(header.arch, equals(ElfArchitectureIdentifier.ia64));
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
      final reader = ElfReader.fromBytes(
          File('test/data/64_intel_yes').readAsBytesSync());
      final symbols = reader.dynamicSymbolTableSection!.symbols;
      final global = symbols.where(
          (final s) => s.binding == ElfSymbolBinding.global);
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

    test('String table handles EOF without infinite loop', () {
      final bytes = Uint8List.fromList([0x41, 0x42, 0x43]);
      final buffer = ElfInMemoryBuffer.fromBytes(bytes);
      final table = ElfStringTable(buffer, 0, 3);
      final result = table.at(0);
      expect(result, equals('ABC'));
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
      final reader = ElfReader.fromBytes(
          File('test/data/64_intel_yes').readAsBytesSync());
      final notes = reader.sections
          .whereType<ElfNoteSection>()
          .toList();
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
}
