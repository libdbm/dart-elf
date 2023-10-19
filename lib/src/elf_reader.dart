import 'dart:io';
import 'dart:typed_data';

import 'package:dart_elf/src/elf_gnu_versym_section.dart';

import '../dart_elf.dart';

/// Parser for ELF files.
class ElfReader {
  final ElfIoBuffer _buffer;
  final ElfFileHeader _header;
  late ElfStringTableSection _sectionNames;
  late List<ElfSection> _sections;
  late List<ElfSegment> _segments;

  /// The backing buffer holding the raw ELF file
  ElfIoBuffer get buffer => _buffer;

  /// The ELF header
  ElfFileHeader get header => _header;

  /// The list of segments in the ELF file
  List<ElfSegment> get segments => _segments;

  /// The list of sections in the ELF file
  List<ElfSection> get sections => _sections;

  /// Get the symbol table section if it exists
  ElfSymbolTableSection? get symbolTableSection => _getSymbolTableSection();

  /// Get the dynamic symbol table section, if it exists
  ElfSymbolTableSection? get dynamicSymbolTableSection =>
      _getDynamicSymbolTableSection();

  /// Get the string table if it exists
  ElfStringTable? get stringTable => _getStringTable();

  /// Get the dynamic string table, if it exists
  ElfStringTable? get dynamicStringTable => _getDynamicStringTable();

  /// Get the version symbol table if it exists
  ElfGnuVersionSymbolTableSection? get versionSymbolTableSection =>
      _getVersionSymbolTableSection();

  /// Create an ELF parser from a buffer
  ElfReader.fromIoBuffer(ElfIoBuffer buffer)
      : _buffer = buffer,
        _header = _parseHeader(buffer) {
    _sectionNames = _loadSectionNameStringTable();
    _sections = _parseSections();
    _segments = _parseSegments();
  }

  /// Create an ELF parser from a list of raw bytes.
  ElfReader.fromBytes(Uint8List bytes)
      : this.fromIoBuffer(ElfInMemoryBuffer.fromBytes(bytes));

  /// Create an ELF parser from a File.
  ElfReader.fromRandomAccessFile(RandomAccessFile file)
      : this.fromIoBuffer(ElfRandomFileBuffer.fromRandomAccessFile(file));

  /// Helper function to convert [address] to a file offset based on segments
  int toFileOffset(int address) {
    for (ElfSegment segment in segments) {
      int start = segment.header.vaddr;
      int end = segment.header.vaddr + segment.header.msize;
      if (address >= start && address < end) {
        int offset = address - start;
        if (offset <= segment.header.fsize) {
          return offset + segment.header.offset;
        }
      }
    }
    throw StateError('Invalid ELF file. Unable to map address to file');
  }

  ElfStringTableSection _loadSectionNameStringTable() {
    final int offset = _header.shoff + (_header.shstrndx * _header.shentsize);
    ElfSectionHeader section = _parseSectionHeader(offset);
    return ElfStringTableSection(_header, section, 'segment names', _buffer);
  }

  List<ElfSegment> _parseSegments() {
    List<ElfSegment> segments = [];
    for (int i = 0; i < _header.phnum; i++) {
      final int offset = _header.phoff + (i * _header.phentsize);
      ElfSegmentHeader head = _parseSegmentHeader(offset);
      segments.add(ElfSegment(_header, head, _buffer));
    }
    return segments;
  }

  List<ElfSection> _parseSections() {
    List<ElfSection> ret = [];
    for (int i = 0; i < _header.shnum; i++) {
      final int offset = _header.shoff + (i * _header.shentsize);
      ElfSectionHeader head = _parseSectionHeader(offset);
      ElfSectionType type =
          ElfSectionType.byArchitecture(_header.arch, head.type);
      String name = _sectionNames.table.at(head.nindex);
      switch (type) {
        case ElfSectionType.none:
          ret.add(ElfSection(_header, head, name, _buffer));
          break;
        case ElfSectionType.progbits:
          ret.add(ElfSection(_header, head, name, _buffer));
          break;
        case ElfSectionType.symtab:
          ret.add(ElfSymbolTableSection(_header, head, name, _buffer));
          break;
        case ElfSectionType.strtab:
          ret.add(ElfStringTableSection(_header, head, name, _buffer));
          break;
        case ElfSectionType.hash:
          ret.add(ElfHashTableSection(_header, head, name, _buffer));
          break;
        case ElfSectionType.dyn:
          ret.add(ElfDynamicSection(_header, head, name, _buffer));
          break;
        case ElfSectionType.note:
          ret.add(ElfNoteSection(_header, head, name, _buffer));
          break;
        case ElfSectionType.nobits:
          ret.add(ElfSection(_header, head, name, _buffer));
          break;
        case ElfSectionType.rel:
          ret.add(ElfRelocationSection(_header, head, name, _buffer, false));
          break;
        case ElfSectionType.rela:
          ret.add(ElfRelocationSection(_header, head, name, _buffer, true));
          break;
        case ElfSectionType.dynsym:
          ret.add(ElfSymbolTableSection(_header, head, name, _buffer));
          break;
        case ElfSectionType.gnuHash:
          ret.add(ElfGnuHashTableSection(_header, head, name, _buffer));
          break;
        case ElfSectionType.gnuVerSym:
          if (name == '.gnu.version') {
            ret.add(
                ElfGnuVersionSymbolTableSection(_header, head, name, _buffer));
          } else {
            ret.add(ElfSection(_header, head, name, _buffer));
          }
          break;
        case ElfSectionType.gnuVerDef:
          if (name == '.gnu.version_d') {
            ret.add(
                ElfGnuVersionDefinitionSection(_header, head, name, _buffer));
          } else {
            ret.add(ElfSection(_header, head, name, _buffer));
          }
          break;
        case ElfSectionType.gnuVerNeed:
          if (name == '.gnu.version_r') {
            ret.add(ElfGnuVersionNeededSection(_header, head, name, _buffer));
          } else {
            ret.add(ElfSection(_header, head, name, _buffer));
          }
          break;
        // TODO: handle these specific types
        case ElfSectionType.shlib:
        case ElfSectionType.init:
        case ElfSectionType.fini:
        case ElfSectionType.preinit:
        case ElfSectionType.group:
        case ElfSectionType.shndx:
        case ElfSectionType.armAttributes:
        case ElfSectionType.armDebugOverlay:
        case ElfSectionType.armExceptionIndex:
        case ElfSectionType.armOverlay:
        case ElfSectionType.armPreemptionMap:
        default:
          ret.add(ElfSection(_header, head, name, _buffer));
      }
    }
    return ret;
  }

  ElfSegmentHeader _parseSegmentHeader(int pos) {
    _buffer.seek(pos, absolute: true);
    if (_header.word == ElfWordSize.word32Bit) {
      return (
        type: ElfSegmentType.byArchitecture(
            _header.arch, _buffer.readInt(_header.endian)),
        offset: _buffer.readInt(_header.endian),
        vaddr: _buffer.readInt(_header.endian),
        paddr: _buffer.readInt(_header.endian),
        fsize: _buffer.readInt(_header.endian),
        msize: _buffer.readInt(_header.endian),
        flags: _buffer.readInt(_header.endian),
        align: _buffer.readInt(_header.endian)
      );
    }
    return (
      type: ElfSegmentType.byArchitecture(
          _header.arch, _buffer.readInt(_header.endian)),
      flags: _buffer.readInt(_header.endian),
      offset: _buffer.readLong(_header.endian),
      vaddr: _buffer.readLong(_header.endian),
      paddr: _buffer.readLong(_header.endian),
      fsize: _buffer.readLong(_header.endian),
      msize: _buffer.readLong(_header.endian),
      align: _buffer.readLong(_header.endian)
    );
  }

  ElfSectionHeader _parseSectionHeader(int pos) {
    _buffer.seek(pos, absolute: true);
    return (
      nindex: _buffer.readInt(_header.endian),
      type: _buffer.readInt(_header.endian),
      flags: _header.word == ElfWordSize.word32Bit
          ? _buffer.readInt(_header.endian)
          : _buffer.readLong(_header.endian),
      addr: _header.word == ElfWordSize.word32Bit
          ? _buffer.readInt(_header.endian)
          : _buffer.readLong(_header.endian),
      offset: _header.word == ElfWordSize.word32Bit
          ? _buffer.readInt(_header.endian)
          : _buffer.readLong(_header.endian),
      size: _header.word == ElfWordSize.word32Bit
          ? _buffer.readInt(_header.endian)
          : _buffer.readLong(_header.endian),
      link: _buffer.readInt(_header.endian),
      info: _buffer.readInt(_header.endian),
      align: _header.word == ElfWordSize.word32Bit
          ? _buffer.readInt(_header.endian)
          : _buffer.readLong(_header.endian),
      entsize: _header.word == ElfWordSize.word32Bit
          ? _buffer.readInt(_header.endian)
          : _buffer.readLong(_header.endian)
    );
  }

  static ElfFileHeader _parseHeader(ElfIoBuffer buffer) {
    // Validate the magic number
    if (buffer[EI_MAG0] != ELFMAG0 ||
        buffer[EI_MAG1] != ELFMAG1 ||
        buffer[EI_MAG2] != ELFMAG2 ||
        buffer[EI_MAG3] != ELFMAG3) {
      throw StateError('Invalid ELF file. Missing magic number');
    }

    // Validate the version
    int version = buffer[EI_VERSION];
    if (version != EV_CURRENT) {
      throw StateError('Invalid ELF file. Bad version: $version');
    }

    ElfWordSize wordSize = _parseWordSize(buffer);
    Endian endian = _parseEndian(buffer);
    ElfAbiIdentifier abi = _parseAbi(buffer);
    int abiVersion = buffer[EI_ABIVERSION];
    ElfFileType type = _parseFileType(buffer, endian);
    ElfArchitectureIdentifier arch = _parseArchitectureType(buffer, endian);
    int entry = _parseEntryPoint(buffer, endian, wordSize);
    int phoff = _parseProgramHeaderOffset(buffer, endian, wordSize);
    int shoff = _parseSectionHeaderOffset(buffer, endian, wordSize);
    int flags = _readInt(
        buffer, wordSize == ElfWordSize.word32Bit ? 0x24 : 0x30, endian);
    int ehsize = _readShort(
        buffer, wordSize == ElfWordSize.word32Bit ? 0x28 : 0x34, endian);
    int phentsize = _readShort(
        buffer, wordSize == ElfWordSize.word32Bit ? 0x2A : 0x36, endian);
    int phnum = _readShort(
        buffer, wordSize == ElfWordSize.word32Bit ? 0x2C : 0x38, endian);
    int shentsize = _readShort(
        buffer, wordSize == ElfWordSize.word32Bit ? 0x2E : 0x3A, endian);
    int shnum = _readShort(
        buffer, wordSize == ElfWordSize.word32Bit ? 0x30 : 0x3C, endian);
    if (phnum == 0 && shnum == 0) {
      throw StateError('Invalid ELF file. No program or section headers.');
    }
    int shstrndx = _readShort(
        buffer, wordSize == ElfWordSize.word32Bit ? 0x32 : 0x3E, endian);
    if (shstrndx == 0xffff) {
      throw StateError('Invalid ELF file. shstrndx == 0xffff');
    }
    buffer.seek(0, absolute: true);
    return (
      data: buffer.readBytes(wordSize == ElfWordSize.word32Bit ? 52 : 64),
      version: version,
      word: wordSize,
      endian: endian,
      abi: abi,
      abiVersion: abiVersion,
      type: type,
      arch: arch,
      entry: entry,
      phoff: phoff,
      shoff: shoff,
      flags: flags,
      ehsize: ehsize,
      phentsize: phentsize,
      phnum: phnum,
      shentsize: shentsize,
      shnum: shnum,
      shstrndx: shstrndx
    );
  }

  static int _readInt(buffer, offset, endian) {
    buffer.seek(offset);
    return buffer.readInt(endian);
  }

  static int _readShort(buffer, offset, endian) {
    buffer.seek(offset);
    return buffer.readShort(endian);
  }

  static int _readLong(buffer, offset, endian) {
    buffer.seek(offset);
    return buffer.readLong(endian);
  }

  static int _parseEntryPoint(bytes, endian, wordSize) {
    return wordSize == ElfWordSize.word32Bit
        ? _readInt(bytes, EI_ENTRY, endian)
        : _readLong(bytes, EI_ENTRY, endian);
  }

  static int _parseProgramHeaderOffset(bytes, endian, wordSize) {
    int offset = wordSize == ElfWordSize.word32Bit ? 0x1C : 0x20;
    return wordSize == ElfWordSize.word32Bit
        ? _readInt(bytes, offset, endian)
        : _readLong(bytes, offset, endian);
  }

  static int _parseSectionHeaderOffset(bytes, endian, wordSize) {
    int offset = wordSize == ElfWordSize.word32Bit ? 0x20 : 0x28;
    return wordSize == ElfWordSize.word32Bit
        ? _readInt(bytes, offset, endian)
        : _readLong(bytes, offset, endian);
  }

  static ElfWordSize _parseWordSize(buffer) {
    // Validate the word size
    int flag = buffer[EI_CLASS];
    if (flag != ELFCLASS32 && flag != ELFCLASS64) {
      throw StateError('Invalid ELF file. Bad size: $flag');
    }
    return flag == ELFCLASS32 ? ElfWordSize.word32Bit : ElfWordSize.word64Bit;
  }

  static Endian _parseEndian(buffer) {
    // Validate the endian flag
    int flag = buffer[EI_DATA];
    if (flag != ELFDATA2LSB && flag != ELFDATA2MSB) {
      throw StateError('Invalid ELF file. Bad endian flag: $flag');
    }
    return flag == ELFDATA2LSB ? Endian.little : Endian.big;
  }

  static ElfFileType _parseFileType(buffer, endian) {
    int type = _readShort(buffer, EI_FILE_TYPE, endian);
    return ElfFileType.byId(type);
  }

  static ElfArchitectureIdentifier _parseArchitectureType(buffer, endian) {
    int type = _readShort(buffer, EI_ARCH_TYPE, endian);
    return ElfArchitectureIdentifier.byId(type);
  }

  static ElfAbiIdentifier _parseAbi(buffer) {
    return ElfAbiIdentifier.byId(buffer[EI_OSABI]);
  }

  ElfSymbolTableSection? _getSymbolTableSection() {
    for (var section in sections) {
      if (section.type.id == ElfSectionType.symtab.id) {
        return section as ElfSymbolTableSection;
      }
    }
    return null;
  }

  ElfSymbolTableSection? _getDynamicSymbolTableSection() {
    for (var section in sections) {
      if (section.type.id == ElfSectionType.dynsym.id) {
        return section as ElfSymbolTableSection;
      }
    }
    return null;
  }

  ElfStringTable? _getStringTable() {
    for (var section in sections) {
      if (section.name == '.strtab') {
        return (section as ElfStringTableSection).table;
      }
    }
    return null;
  }

  ElfStringTable? _getDynamicStringTable() {
    for (var section in sections) {
      if (section.name == '.dynstr') {
        return (section as ElfStringTableSection).table;
      }
    }
    return null;
  }

  ElfGnuVersionSymbolTableSection? _getVersionSymbolTableSection() {
    for (var section in sections) {
      if (section.type == ElfSectionType.gnuVerSym) {
        return section as ElfGnuVersionSymbolTableSection;
      }
    }
    return null;
  }
}
