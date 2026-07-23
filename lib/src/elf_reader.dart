import 'dart:io';
import 'dart:typed_data';

import 'package:dart_elf/src/elf_gnu_versym_section.dart';

import '../dart_elf.dart';

/// Parser for ELF files.
class ElfReader {
  final ElfIoBuffer _buffer;
  final ElfFileHeader _header;
  late final int _shnum;
  late final int _shstrndx;
  late final ElfStringTableSection? _sectionNames;
  late final List<ElfSection> _sections;
  late final List<ElfSegment> _segments;

  /// The backing buffer holding the raw ELF file
  ElfIoBuffer get buffer => _buffer;

  /// The ELF header
  ElfFileHeader get header => _header;

  /// The list of segments in the ELF file
  List<ElfSegment> get segments => List.unmodifiable(_segments);

  /// The list of sections in the ELF file
  List<ElfSection> get sections => List.unmodifiable(_sections);

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
    // Section header zero carries the real section count and name table index
    // when the ELF header cannot hold them. It is only present when there is a
    // section table at all.
    final ElfSectionHeader? first =
        _header.shoff != 0 ? _parseSectionHeader(_header.shoff) : null;
    _shnum = _resolveCount(first);
    _shstrndx = _resolveIndex(first);
    _validateSectionTable();
    _sectionNames =
        _shstrndx == SHN_UNDEF ? null : _loadSectionNameStringTable();
    _sections = _parseSections();
    _segments = _parseSegments();
  }

  /// Create an ELF parser from a list of raw bytes.
  ElfReader.fromBytes(Uint8List bytes)
      : this.fromIoBuffer(ElfInMemoryBuffer.fromBytes(bytes));

  /// Create an ELF parser from an open file.
  ///
  /// The caller keeps ownership of [file] and remains responsible for closing
  /// it. Use [ElfReader.fromFile] to have the reader own the handle instead.
  ElfReader.fromRandomAccessFile(RandomAccessFile file)
      : this.fromIoBuffer(ElfRandomFileBuffer.fromRandomAccessFile(file));

  /// Create an ELF parser that owns the handle it opens for [file].
  ///
  /// Call [close] when finished, or the descriptor leaks.
  ElfReader.fromFile(File file) : this.fromRandomAccessFile(file.openSync());

  /// Release the backing buffer's resources
  ///
  /// Only meaningful for readers that own a file handle. Reading after a close
  /// is not supported.
  void close() {
    _buffer.close();
  }

  /// Helper function to convert [address] to a file offset based on segments
  int toFileOffset(int address) {
    for (ElfSegment segment in segments) {
      int start = segment.header.vaddr;
      int end = segment.header.vaddr + segment.header.msize;
      if (address >= start && address < end) {
        int offset = address - start;
        if (offset < segment.header.fsize) {
          return offset + segment.header.offset;
        }
      }
    }
    throw ElfFormatException('Invalid ELF file. Unable to map address to file');
  }

  /// Resolve the section count from [first], section header zero.
  ///
  /// A count of zero in the ELF header means either that there are no sections
  /// at all, or that the real count did not fit and lives in section header
  /// zero. The presence of a section table tells the two apart.
  int _resolveCount(final ElfSectionHeader? first) {
    if (_header.shnum != 0) return _header.shnum;
    if (first == null) return 0;
    return first.size;
  }

  /// Resolve the section name table index from [first], section header zero.
  ///
  /// An index of SHN_XINDEX means the real index did not fit in the ELF header
  /// and lives in the link field of section header zero.
  int _resolveIndex(final ElfSectionHeader? first) {
    if (_header.shstrndx != SHN_XINDEX) return _header.shstrndx;
    if (first == null) {
      throw ElfFormatException(
          'Section name index is SHN_XINDEX but the file has no section table');
    }
    return first.link;
  }

  /// Verify that the resolved section table is present and fits in the file
  void _validateSectionTable() {
    if (_shnum == 0) {
      if (_shstrndx != SHN_UNDEF) {
        throw ElfFormatException(
            'Section name index $_shstrndx but the file has no sections');
      }
      return;
    }
    final int minimum =
        _header.word == ElfWordSize.word32Bit ? SHENTSIZE32 : SHENTSIZE64;
    if (_header.shentsize < minimum) {
      throw ElfFormatException(
          'Section header size ${_header.shentsize} is below the minimum $minimum');
    }
    final int end = _header.shoff + (_shnum * _header.shentsize);
    if (end > _buffer.size) {
      throw ElfFormatException(
          'Section table of $_shnum entries overruns the file (size ${_buffer.size})',
          offset: _header.shoff);
    }
    if (_shstrndx >= _shnum) {
      throw ElfFormatException(
          'Section name index $_shstrndx is outside the $_shnum section headers');
    }
  }

  /// Verify that section [i] lies within the file
  ///
  /// SHT_NOBITS occupies no file space and SHT_NULL is inactive, so neither
  /// has a payload to bound.
  void _validateSection(
      final int i, final ElfSectionHeader head, final ElfSectionType type) {
    if (type == ElfSectionType.nobits || type == ElfSectionType.none) return;
    if (head.offset < 0 || head.size < 0) {
      throw ElfFormatException('Section $i has a negative offset or size',
          offset: head.offset);
    }
    if (head.offset + head.size > _buffer.size) {
      throw ElfFormatException(
          'Section $i of ${head.size} bytes overruns the file (size ${_buffer.size})',
          offset: head.offset);
    }
  }

  ElfStringTableSection _loadSectionNameStringTable() {
    final int offset = _header.shoff + (_shstrndx * _header.shentsize);
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
    for (int i = 0; i < _shnum; i++) {
      final int offset = _header.shoff + (i * _header.shentsize);
      ElfSectionHeader head = _parseSectionHeader(offset);
      ElfSectionType type =
          ElfSectionType.byArchitecture(_header.arch, head.type);
      _validateSection(i, head, type);
      String name = _sectionNames?.table.at(head.nindex) ?? '';
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
        // The section type alone decides the class. Gating on the canonical
        // name as well would leave vendor variants as plain sections that the
        // type based accessors would then fail to cast.
        case ElfSectionType.gnuVerSym:
          ret.add(
              ElfGnuVersionSymbolTableSection(_header, head, name, _buffer));
          break;
        case ElfSectionType.gnuVerDef:
          ret.add(ElfGnuVersionDefinitionSection(_header, head, name, _buffer));
          break;
        case ElfSectionType.gnuVerNeed:
          ret.add(ElfGnuVersionNeededSection(_header, head, name, _buffer));
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
      throw ElfFormatException('Invalid ELF file. Missing magic number');
    }

    // Validate the version
    int version = buffer[EI_VERSION];
    if (version != EV_CURRENT) {
      throw ElfFormatException('Invalid ELF file. Bad version: $version');
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
    int shstrndx = _readShort(
        buffer, wordSize == ElfWordSize.word32Bit ? 0x32 : 0x3E, endian);

    _validateHeader(buffer, wordSize, ehsize, phoff, phentsize, phnum);

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

  /// Verify the ELF header's self-reported sizes and that the program header
  /// table it describes fits within the file.
  ///
  /// The section header table is validated separately, after extended
  /// numbering has been resolved.
  static void _validateHeader(final ElfIoBuffer buffer, final ElfWordSize word,
      final int ehsize, final int phoff, final int phentsize, final int phnum) {
    final bool small = word == ElfWordSize.word32Bit;
    final int minimum = small ? EHSIZE32 : EHSIZE64;
    if (ehsize < minimum) {
      throw ElfFormatException(
          'ELF header size $ehsize is below the minimum $minimum');
    }
    if (phnum == 0) return;
    final int entry = small ? PHENTSIZE32 : PHENTSIZE64;
    if (phentsize < entry) {
      throw ElfFormatException(
          'Program header size $phentsize is below the minimum $entry');
    }
    if (phoff + (phnum * phentsize) > buffer.size) {
      throw ElfFormatException(
          'Program table of $phnum entries overruns the file (size ${buffer.size})',
          offset: phoff);
    }
  }

  static int _readInt(ElfIoBuffer buffer, int offset, Endian endian) {
    buffer.seek(offset);
    return buffer.readInt(endian);
  }

  static int _readShort(ElfIoBuffer buffer, int offset, Endian endian) {
    buffer.seek(offset);
    return buffer.readShort(endian);
  }

  static int _readLong(ElfIoBuffer buffer, int offset, Endian endian) {
    buffer.seek(offset);
    return buffer.readLong(endian);
  }

  static int _parseEntryPoint(
      ElfIoBuffer bytes, Endian endian, ElfWordSize wordSize) {
    return wordSize == ElfWordSize.word32Bit
        ? _readInt(bytes, EI_ENTRY, endian)
        : _readLong(bytes, EI_ENTRY, endian);
  }

  static int _parseProgramHeaderOffset(
      ElfIoBuffer bytes, Endian endian, ElfWordSize wordSize) {
    int offset = wordSize == ElfWordSize.word32Bit ? 0x1C : 0x20;
    return wordSize == ElfWordSize.word32Bit
        ? _readInt(bytes, offset, endian)
        : _readLong(bytes, offset, endian);
  }

  static int _parseSectionHeaderOffset(
      ElfIoBuffer bytes, Endian endian, ElfWordSize wordSize) {
    int offset = wordSize == ElfWordSize.word32Bit ? 0x20 : 0x28;
    return wordSize == ElfWordSize.word32Bit
        ? _readInt(bytes, offset, endian)
        : _readLong(bytes, offset, endian);
  }

  static ElfWordSize _parseWordSize(ElfIoBuffer buffer) {
    // Validate the word size
    int flag = buffer[EI_CLASS];
    if (flag != ELFCLASS32 && flag != ELFCLASS64) {
      throw ElfFormatException('Invalid ELF file. Bad size: $flag');
    }
    return flag == ELFCLASS32 ? ElfWordSize.word32Bit : ElfWordSize.word64Bit;
  }

  static Endian _parseEndian(ElfIoBuffer buffer) {
    // Validate the endian flag
    int flag = buffer[EI_DATA];
    if (flag != ELFDATA2LSB && flag != ELFDATA2MSB) {
      throw ElfFormatException('Invalid ELF file. Bad endian flag: $flag');
    }
    return flag == ELFDATA2LSB ? Endian.little : Endian.big;
  }

  static ElfFileType _parseFileType(ElfIoBuffer buffer, Endian endian) {
    int type = _readShort(buffer, EI_FILE_TYPE, endian);
    return ElfFileType.byId(type);
  }

  static ElfArchitectureIdentifier _parseArchitectureType(
      ElfIoBuffer buffer, Endian endian) {
    int type = _readShort(buffer, EI_ARCH_TYPE, endian);
    return ElfArchitectureIdentifier.byId(type);
  }

  static ElfAbiIdentifier _parseAbi(ElfIoBuffer buffer) {
    return ElfAbiIdentifier.byId(buffer[EI_OSABI]);
  }

  // These accessors select on runtime type rather than casting on a type id
  // or a section name. Both of those come from the file and can disagree with
  // the class the section was actually built as.

  ElfSymbolTableSection? _getSymbolTableSection() {
    return _sections
        .whereType<ElfSymbolTableSection>()
        .where((final section) => section.type.id == ElfSectionType.symtab.id)
        .firstOrNull;
  }

  ElfSymbolTableSection? _getDynamicSymbolTableSection() {
    return _sections
        .whereType<ElfSymbolTableSection>()
        .where((final section) => section.type.id == ElfSectionType.dynsym.id)
        .firstOrNull;
  }

  ElfStringTable? _getStringTable() {
    return _sections
        .whereType<ElfStringTableSection>()
        .where((final section) => section.name == '.strtab')
        .firstOrNull
        ?.table;
  }

  ElfStringTable? _getDynamicStringTable() {
    return _sections
        .whereType<ElfStringTableSection>()
        .where((final section) => section.name == '.dynstr')
        .firstOrNull
        ?.table;
  }

  ElfGnuVersionSymbolTableSection? _getVersionSymbolTableSection() {
    return _sections.whereType<ElfGnuVersionSymbolTableSection>().firstOrNull;
  }
}
