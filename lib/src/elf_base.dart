/// Constants and types related to parsing an ELF binary
// ignore_for_file: constant_identifier_names

import 'dart:typed_data';

// Offsets into the identification header.
const EI_MAG0 = 0x0;
const EI_MAG1 = 0x1;
const EI_MAG2 = 0x2;
const EI_MAG3 = 0x3;
const EI_CLASS = 0x4;
const EI_DATA = 0x5;
const EI_VERSION = 0x6;
const EI_OSABI = 0x7;
const EI_ABIVERSION = 0x08;
const EI_PAD = 0x09;
const EI_FILE_TYPE = 0x10;
const EI_ARCH_TYPE = 0x12;
const EI_ENTRY = 0x18;

// Constants used within the ELF specification.
const ELFMAG0 = 0x7f;
const ELFMAG1 = 0x45; // E
const ELFMAG2 = 0x4c; // L
const ELFMAG3 = 0x46; // F
const ELFCLASS32 = 1;
const ELFCLASS64 = 2;
const ELFDATA2LSB = 1;
const ELFDATA2MSB = 2;
const EV_CURRENT = 1;

/// ELF file header record
typedef ElfFileHeader = ({
  Uint8List data,
  int version,
  Endian endian,
  ElfWordSize word,
  ElfAbiIdentifier abi,
  int abiVersion,
  ElfFileType type,
  ElfArchitectureIdentifier arch,
  int entry,
  int phoff,
  int shoff,
  int flags,
  int ehsize,
  int phentsize,
  int phnum,
  int shentsize,
  int shnum,
  int shstrndx,
});

/// ELF section header record
typedef ElfSectionHeader = ({
  int nindex,
  int type,
  int flags,
  int addr,
  int offset,
  int size,
  int link,
  int info,
  int align,
  int entsize
});

/// ELF segment header record
typedef ElfSegmentHeader = ({
  ElfSegmentType type,
  int offset,
  int vaddr,
  int paddr,
  int fsize,
  int msize,
  int flags,
  int align
});

/// ELF symbol record
typedef ElfSymbol = ({
  ElfSymbolType type,
  ElfSymbolBinding binding,
  ElfSymbolVisibility visibility,
  int nindex,
  int value,
  int size,
  int info,
  int other,
  int shndx
});

/// ELF relocation record with optional addend
typedef ElfRelocation = ({
  int offset,
  int info,
  int? addend,
});

/// ELF hash table record
typedef ElfHashTable = ({
  int nbucket,
  int nchain,
  List<int> bucket,
  List<int> chain,
});

/// ELF dynamic entry record
typedef ElfDynamicEntry = ({
  int tag,
  int value,
});

/// ELF GNU Build Id record
typedef ElfGnuBuildId = ({
  Uint8List raw,
  String text,
});

/// ELF GNU Gold version record
typedef ElfGnuGoldVersion = ({
  Uint8List raw,
  String text,
});

/// ELF GNU ABI Descriptor record
typedef ElfGnuAbiDescriptor = ({
  int os,
  int major,
  int minor,
  int sub,
});

/// An enum containing processor architecture identifiers
enum ElfArchitectureIdentifier {
  none(0x0, 'EM_NONE', 'Unknown'),
  att(0x1, 'EM_M32', 'AT&T WE 32100'),
  sparc(0x2, 'EM_SPARC', 'SPARC'),
  i386(0x3, 'EM_386', 'Intel i386'),
  m68k(0x4, 'EM_68k', 'Motorola 68000 series'),
  m88k(0x5, 'EM_88k', 'Motorola 88000 series'),
  i486(0x6, 'EM_486', 'Intel 486'),
  i860(0x7, 'EM_860', 'Intel i1860'),
  mips(0x8, 'EM_MIPS', 'MIPS'),
  arm(0x28, 'EM_ARM', 'Arm (Armv7/AArch32)'),
  ia64(0x3e, 'EM_IA_64', 'Advanced Micro Devices X86-64'),
  aarch64(0xb7, 'EM_AARCH64', 'Arm 64-bits (Armv8/AArch64)'),
  riscv(0xf3, 'EM_RISCV', 'RISC-V'),
  bpf(0xf7, 'EM_BPF', 'Berkeley Packet Filter'),
  wdc(0x101, 'EM_WDC', 'WDC 65C816');

  final int id;
  final String name;
  final String description;

  const ElfArchitectureIdentifier(this.id, this.name, this.description);

  /// Finds an architecture given an [id].
  ///
  /// Throws a [StateError] if the id could not be found.
  static ElfArchitectureIdentifier byId(int id) {
    return ElfArchitectureIdentifier.values.firstWhere((x) => x.id == id);
  }
}

/// An enum containing operating system/ABI identifiers
enum ElfAbiIdentifier {
  systemv(0x00, 'ELFOSABI_NONE', 'System V'),
  hpux(0x01, 'ELFOSABI_HPUX', 'HP-UX'),
  netbsd(0x02, 'ELFOSABI_NETBSD', 'NetBSD'),
  linux(0x03, 'ELFOSABI_LINUX', 'Linux'),
  hurd(0x04, 'ELFOSABI_GNU', 'GNU Hurd'),
  solaris(0x06, 'ELFOSABI_SOLARIS', 'Solaris'),
  aix(0x07, 'ELFOSABI_AIX', 'AIX (Monterey)'),
  irix(0x08, 'ELFOSABI_IRIX', 'IRIX'),
  freebsd(0x09, 'ELFOSABI_IRIX', 'FreeBSD'),
  tru64(0x0a, 'ELFOSABI_TRU64', 'Tru64'),
  modesto(0x0b, 'ELFOSABI_MODESTO', 'Novell Modesto'),
  openbsd(0x0c, 'ELFOSABI_OPENVMS', 'OpenBSD'),
  openvms(0x0d, 'ELFOSABI_OPENVMS', 'OpenVMS'),
  nonstop(0x0e, 'ELFOSABI_NSK', 'NonStop Kernel'),
  aros(0x0f, 'ELFOSABI_AROS', 'AROS'),
  fenix(0x10, 'ELFOSABI_FENIX', 'FenixOS'),
  cloud(0x11, 'ELFOSABI_CLOUD', 'Nuxi CloudABI'),
  openvos(0x12, 'ELFOSABI_OPENVOS', 'Stratus Technologies OpenVOS');

  final int id;
  final String name;
  final String description;

  const ElfAbiIdentifier(this.id, this.name, this.description);

  /// Finds an identifier given an [id].
  ///
  /// Throws a [StateError] if the id could not be found.
  static ElfAbiIdentifier byId(int id) {
    return ElfAbiIdentifier.values.firstWhere((x) => x.id == id);
  }
}

/// An enum containing file types
enum ElfFileType {
  unknown(0x0, 'ET_NONE', 'unknown file type'),
  relocatable(0x1, 'ET_REL', 'Relocatable file'),
  executable(0x2, 'ET_EXEC', 'Executable file '),
  shared(0x3, 'ET_DYN', 'Position independent executable file'),
  core(0x4, 'ET_CORE', 'Core file '),
  os(0xfe00, 'ET_LOOS', 'Operating system specific'),
  processor(0xff00, 'ET_LOPROC', 'Processor specific');

  final int id;
  final String name;
  final String description;

  const ElfFileType(this.id, this.name, this.description);

  /// Finds a file type given an [id].
  ///
  /// Throws a [StateError] if the id could not be found.
  static ElfFileType byId(int id) {
    if (id >= 0xfe00 && id <= 0xfeff) return ElfFileType.os;
    if (id >= 0xff00 && id <= 0xffff) return ElfFileType.processor;
    return ElfFileType.values.firstWhere((x) => x.id == id);
  }
}

/// An enum containing segment types
enum ElfSegmentType {
  none(0x0, null, 'PT_NULL', ''),
  load(0x1, null, 'PT_LOAD', ''),
  dynamic(0x2, null, 'PT_DYNAMIC', ''),
  interp(0x3, null, 'PT_INTERP', ''),
  note(0x4, null, 'PT_NOTE', ''),
  shlib(0x5, null, 'PT_SHLIB', ''),
  phdr(0x6, null, 'PT_PHDR', ''),
  tls(0x7, null, 'PT_TLS', ''),
  num(0x8, null, 'PT_NUM', 'Number of defined types'),
  gnuEhFrame(0x6474e550, null, 'PT_GNU_EH_FRAME', 'GCC .eh_frame_hdr segment'),
  gnuStack(0x6474e551, null, 'PT_GNU_STACK', 'Indicates stack execution'),
  gnuRelRO(0x6474e552, null, 'PT_GNU_RELRO', 'Read-only after relocation'),
  gnuProperty(0x6474e553, null, 'PT_GNU_PROPERTY', 'GNU property'),
  sunSegment(0x6ffffffa, null, 'PT_SUNWBSS', 'Sun specific segment'),
  sunStack(0x6ffffffa, null, 'PT_SUNWSTACK', 'Sun stack segment'),
  os(0x60000000, null, 'PT_LOOS', 'OS specific'),
  processor(0x70000000, null, 'PT_LOPROC', 'Processor specific'),

  // MIPS
  mipsRegisterUsageInfo(0x70000000, ElfArchitectureIdentifier.mips,
      'PT_MIPS_REGINFO', 'MIPS register usage'),
  mipsRuntimeProcedureTable(0x70000001, ElfArchitectureIdentifier.mips,
      'PT_MIPS_RTPROC', 'MIPS runtime procedure table'),
  mipsOptions(0x70000002, ElfArchitectureIdentifier.mips, 'PT_MIPS_OPTIONS',
      'MIPS .MIPS.options section'),

  // ARM
  armExIdx(
      0x70000001, ElfArchitectureIdentifier.arm, 'PT_ARM_EXIDX', 'ARM EXIDX');

  final int id;
  final ElfArchitectureIdentifier? arch;
  final String name;
  final String description;

  const ElfSegmentType(this.id, this.arch, this.name, this.description);

  /// Finds a segment type given an [arch] and an [id].
  ///
  /// Throws a [StateError] if the segment type could not be found.
  static ElfSegmentType byArchitecture(ElfArchitectureIdentifier arch, int id) {
    for (ElfSegmentType type in ElfSegmentType.values) {
      if (type.id == id && type.arch == arch) return type;
    }
    return byId(id);
  }

  /// Finds a segment type given an [id].
  ///
  /// Throws a [StateError] if the segment type could not be found.
  static ElfSegmentType byId(int id) {
    for (ElfSegmentType type in ElfSegmentType.values) {
      if (type.id == id) return type;
    }
    if (id >= 0x60000000 && id <= 0x6fffffff) return ElfSegmentType.os;
    if (id >= 0x70000000 && id <= 0x7fffffff) return ElfSegmentType.processor;
    throw StateError('Unknown segment type $id');
  }
}

/// An enum containing segment permissions
enum ElfSegmentPermissions {
  exec(0x1, 'PF_X', 'Execution allowed'),
  write(0x2, 'PF_W', 'Write allowed'),
  read(0x4, 'PF_R', 'Read allowed'),
  maskOS(0x0ff00000, 'PT_MASKOS', 'Reserved for OS semantics'),
  maskProcessor(0xf0000000, 'PT_MASKPROC', 'Reserved for processor semantics');

  final int id;
  final String name;
  final String description;

  const ElfSegmentPermissions(this.id, this.name, this.description);

  /// Create a formatted string from flags set in [bits]
  static String format(int bits) {
    String r = isSet(bits, ElfSegmentPermissions.read) ? 'R' : '_';
    String w = isSet(bits, ElfSegmentPermissions.write) ? 'W' : '_';
    String x = isSet(bits, ElfSegmentPermissions.exec) ? 'X' : '_';
    return '$r$w$x';
  }

  /// Check to see if a given [flag] is set in [i].
  static bool isSet(int i, ElfSegmentPermissions flag) {
    return (i & flag.id) > 0;
  }

  /// Finds a permission given an [id].
  ///
  /// Throws a [StateError] if the id could not be found.
  static ElfSegmentPermissions byId(int id) {
    return ElfSegmentPermissions.values.firstWhere((x) => x.id == id);
  }
}

/// An enum containing section types
enum ElfSectionType {
  none(0x0, null, 'SHT_NULL', 'Inactive'),
  progbits(0x1, null, 'SHT_PROGBITS', 'Program specific data'),
  symtab(0x2, null, 'SHT_SYMTAB', 'Symbol table'),
  strtab(0x3, null, 'SHT_STRTAB', 'String table'),
  rela(0x4, null, 'SHT_RELA', 'Relocation entries with addends'),
  hash(0x5, null, 'SHT_HASH', 'Symbol hash table'),
  dyn(0x6, null, 'SHT_DYNAMIC', 'Dynamic linking data'),
  note(0x7, null, 'SHT_NOTE', 'Note'),
  nobits(0x8, null, 'SHT_NOBITS', 'No data'),
  rel(0x9, null, 'SHT_REL', 'Relocation entries'),
  shlib(0xa, null, 'SHT_SHLIB', 'Reserved'),
  dynsym(0xb, null, 'SHT_DYNSYM', 'Symbol table for dynamic data'),
  init(0xe, null, 'SHT_INIT', 'Initialization functions'),
  fini(0xf, null, 'SHT_FINI', 'Terminiation functions'),
  preinit(0x10, null, 'SHT_PREINIT', 'Pre-initialization functions'),
  group(0x11, null, 'SHT_GROUP', 'Section group'),
  shndx(0x12, null, 'SHT_SHNDX', 'Index'),

  // OS specific range
  os(0x60000000, null, 'LOOS', 'OS Specific'),

  // GNU - overlaps with SUN
  gnuHash(0x6ffffff6, null, '', 'GNU Hash'),
  gnuVerDef(0x6ffffffd, null, 'SHT_GNU_verdef', 'GNU Version Definition'),
  gnuVerNeed(0x6ffffffe, null, 'SHT_GNU_verneed', 'GNU Version Need'),
  gnuVerSym(0x6fffffff, null, 'SHT_GNU_versym', 'GNU Version Symbol'),

  // SUN
  sunwMove(0x6ffffffa, ElfArchitectureIdentifier.sparc, 'SHT_SUNW_move', ''),
  sunwComdat(
      0x6ffffffb, ElfArchitectureIdentifier.sparc, 'SHT_SUNW_COMDAT', ''),
  sunwSyminfo(
      0x6ffffffc, ElfArchitectureIdentifier.sparc, 'SHT_SUNW_syminfo', ''),
  sunwVerdef(
      0x6ffffffd, ElfArchitectureIdentifier.sparc, 'SHT_SUNW_verdef', ''),
  sunwVerneed(
      0x6ffffffe, ElfArchitectureIdentifier.sparc, 'SHT_SUNW_verneed', ''),
  sunwVerSym(
      0x6fffffff, ElfArchitectureIdentifier.sparc, 'SHT_SUNW_versym', ''),

  // Processor specific range
  processor(0x70000000, null, 'LOPROC', 'Processor specific'),

  // ARM
  armExceptionIndex(0x70000001, ElfArchitectureIdentifier.arm, 'SHT_ARM_EXIDX',
      'ARM Exception Table Index'),
  armPreemptionMap(0x70000002, ElfArchitectureIdentifier.arm,
      'SHT_ARM_PREEMPTMAP', 'ARM preemption map'),
  armAttributes(0x70000003, ElfArchitectureIdentifier.arm, 'SHT_ARM_ATTRIBUTES',
      'ARM object attributes'),
  armDebugOverlay(0x70000004, ElfArchitectureIdentifier.arm,
      'SHT_ARM_DEBUGOVERLAY', 'ARM debug overlay'),
  armOverlay(0x70000005, ElfArchitectureIdentifier.arm,
      'SHT_ARM_OVERLAYSECTION', 'ARM overlay section'),

  // MIPS
  mipsLibList(0x70000001, ElfArchitectureIdentifier.mips, 'SHT_MIPS_LIBLIST',
      'MIPS shared objects used when statically linking'),
  mipsRegInfo(0x70000006, ElfArchitectureIdentifier.mips, 'SHT_MIPS_REGINFO',
      'MIPS register usage information'),

  // User specific range
  user(0x80000000, null, 'LOUSER', 'User specific');

  final int id;
  final ElfArchitectureIdentifier? arch;
  final String name;
  final String description;

  const ElfSectionType(this.id, this.arch, this.name, this.description);

  /// Finds a section type given [arch] and an [id].
  ///
  /// Throws a [StateError] if the id could not be found.
  static ElfSectionType byArchitecture(ElfArchitectureIdentifier arch, int id) {
    for (ElfSectionType type in ElfSectionType.values) {
      if (type.id == id && type.arch == arch) return type;
    }
    return byId(id);
  }

  /// Finds a section type given an [id].
  ///
  /// Throws a [StateError] if the id could not be found.
  static ElfSectionType byId(int id) {
    for (ElfSectionType type in ElfSectionType.values) {
      if (type.id == id) return type;
    }
    if (id >= 0x60000000 && id <= 0x6fffffff) return ElfSectionType.os;
    if (id >= 0x70000000 && id <= 0x7fffffff) return ElfSectionType.processor;
    if (id >= 0x80000000 && id <= 0xffffffff) return ElfSectionType.user;
    throw StateError('Unknown section header type $id');
  }
}

/// An enum containing word sizes
enum ElfWordSize {
  word32Bit('ELF32', '32 bit ELF'),
  word64Bit('ELF64', '364 bit ELF');

  final String id;
  final String description;

  const ElfWordSize(this.id, this.description);
}

/// An enum containing symbol binding types
enum ElfSymbolBinding {
  local(0, 'LOCAL', 'Not visible outside the file'),
  global(1, 'GLOBAL', 'Globally visible'),
  weak(2, 'WEAK', 'Like a global but with lower precedence'),
  gnuUnique(10, 'GNU_UNIQUE', 'GNU unique'),
  loproc(13, 'LOPROC', 'Processors specific');

  final int id;
  final String name;
  final String description;

  const ElfSymbolBinding(this.id, this.name, this.description);

  /// Finds a section type given an [id].
  ///
  /// Throws a [StateError] if the id could not be found.
  static ElfSymbolBinding byId(int id) {
    if (id >= 13) return ElfSymbolBinding.loproc;
    return ElfSymbolBinding.values.firstWhere((x) => x.id == id);
  }
}

/// An enum containing section header flags
enum ElfSectionHeaderFlags {
  write(0x1, 'SHF_WRITE', 'Writable during process execution'),
  alloc(0x2, 'SHF_ALLOC', 'Allocated at execution'),
  exec(0x4, 'SHF_EXECINSTR', 'Executable code'),
  merge(0x10, 'SHF_MERGE', 'Mergeable section'),
  strings(0x20, 'SHF_STRINGS', 'Contains strings'),
  infoLink(0x40, 'SHF_INFO_LINK', 'Holds a section table index'),
  linkOrder(0x80, 'SHF_LINK_ORDER', 'Ordering information'),
  nonConforming(0x100, 'SHF_OS_NONCONFORMING', ''),
  group(0x200, 'SHF_GROUP', 'Part of a section group'),
  maskOS(0x0ff00000, 'SHF_MASKOS', 'Reserved for OS semantics'),
  ordered(0x40000000, 'SHF_ORDERED', 'Requires ordering'),
  exclude(0x80000000, 'SHF_EXCLUDE', 'Excluded during linking'),
  maskProcessor(0xf0000000, 'SHF_MASKPROC', 'Reserved for processor semantics');

  final int id;
  final String name;
  final String description;

  const ElfSectionHeaderFlags(this.id, this.name, this.description);

  /// Create a formatted string containing the flags
  /// <pre>
  /// W (write), A (alloc), X (execute), M (merge), S (strings), I (info),
  /// L (link order), O (extra OS processing required), G (group), T (TLS),
  /// C (compressed), x (unknown), o (OS specific), E (exclude),
  /// D (mbind), y (purecode), p (processor specific)
  /// </pre>
  static String format(int bits) {
    String w = isSet(bits, ElfSectionHeaderFlags.write) ? 'W' : '_';
    String a = isSet(bits, ElfSectionHeaderFlags.alloc) ? 'A' : '_';
    String x = isSet(bits, ElfSectionHeaderFlags.exec) ? 'X' : '_';
    String m = isSet(bits, ElfSectionHeaderFlags.merge) ? 'M' : '_';
    String s = isSet(bits, ElfSectionHeaderFlags.strings) ? 'S' : '_';
    String i = isSet(bits, ElfSectionHeaderFlags.infoLink) ? 'I' : '_';
    String l = isSet(bits, ElfSectionHeaderFlags.linkOrder) ? 'L' : '_';
    String o = isSet(bits, ElfSectionHeaderFlags.nonConforming) ? 'O' : '_';
    String g = isSet(bits, ElfSectionHeaderFlags.group) ? 'G' : '_';
    String e = isSet(bits, ElfSectionHeaderFlags.exclude) ? 'E' : '_';
    return '$w$a$x$m$s$i$l$o$g$e';
  }

  /// Check to see of [flag] is set in [i]
  static bool isSet(int i, ElfSectionHeaderFlags flag) {
    return (i & flag.id) > 0;
  }

  /// Finds a flag given an [id].
  ///
  /// Throws a [StateError] if the id could not be found.
  static ElfSectionHeaderFlags byId(int id) {
    return ElfSectionHeaderFlags.values.firstWhere((x) => x.id == id);
  }
}

/// An enum containing symbol types
enum ElfSymbolType {
  unknown(-1, 'UNKNOWN', 'Unknown'),
  none(0, 'STT_NOTYPE', 'Symbol type not specified'),
  object(1, 'STT_OBJECT', 'Symbol is a data object'),
  func(2, 'STT_FUNC', 'Symbol is executable code (function, etc.)'),
  section(3, 'STT_SECTION', 'Symbol refers to a section'),
  file(4, 'STT_FILE', 'Local, absolute symbol that refers to a file'),
  common(5, 'STT_COMMON', 'An uninitialized common block'),
  tls(6, 'STT_TLS', 'Thread local data object'),
  num(7, 'STT_NUM', 'Numeric constant'),
  loos(10, 'STT_LOOS', ''),
  hios(12, 'STT_HIOS', ''),
  loproc(13, 'STT_LOPROC', ''),
  hiproc(15, 'STT_HIPROC', '');

  final int id;
  final String name;
  final String description;

  const ElfSymbolType(this.id, this.name, this.description);

  /// Finds a symbol type given an [id].
  ///
  /// Throws a [StateError] if the id could not be found.
  static ElfSymbolType byId(int id) {
    for (ElfSymbolType type in ElfSymbolType.values) {
      if (type.id == id) return type;
    }
    if (id >= ElfSymbolType.loos.id && id <= ElfSymbolType.hios.id) {
      return ElfSymbolType.loos;
    }
    if (id >= ElfSymbolType.loproc.id && id <= ElfSymbolType.hiproc.id) {
      return ElfSymbolType.loproc;
    }
    throw StateError('Unknown symbol type $id');
  }
}

/// An enum containing symbol visibility
enum ElfSymbolVisibility {
  base(0, 'DEFAULT'),
  internal(1, 'INTERNAL'),
  hidden(2, 'HIDDEN'),
  protected(3, 'PROTECTED');

  final int id;
  final String name;

  const ElfSymbolVisibility(this.id, this.name);

  /// Finds a symbol type given an [id].
  ///
  /// Throws a [StateError] if the id could not be found.
  static ElfSymbolVisibility byId(int id) {
    return ElfSymbolVisibility.values.firstWhere((x) => x.id == id);
  }
}

/// An enum containing note types
enum ElfNoteType {
  unknown(0, 'UNKNOWN'),
  gnuAbiTag(1, 'NT_GNU_ABI_TAG'),
  gnuHwcap(2, 'NT_GNU_HWCAP'),
  gnuBuildId(3, 'NT_GNU_BUILD_ID'),
  gnuGoldVersion(4, 'NT_GNU_GOLD_VERSION'),
  gnuProperties(5, 'NT_GNU_PROPERTY_TYPE_0');

  final int id;
  final String name;

  const ElfNoteType(this.id, this.name);

  /// Finds a note type given an [id].
  ///
  /// Throws a [StateError] if the id could not be found.
  static ElfNoteType byId(int id) {
    if (id == 0 || id > 5) {
      return ElfNoteType.unknown;
    }
    return ElfNoteType.values.firstWhere((x) => x.id == id);
  }
}

/// An enum containing relocation types.
///
/// These are architecture specific
enum ElfRelocationType {
  unknown(ElfArchitectureIdentifier.none, 0, 'UNKNOWN'),
  ia64NONE(ElfArchitectureIdentifier.ia64, 0, 'R_X86_64_NONE'),
  ia6464(ElfArchitectureIdentifier.ia64, 1, 'R_X86_64_64'),
  ia64PC32(ElfArchitectureIdentifier.ia64, 2, 'R_X86_64_PC32'),
  ia64(ElfArchitectureIdentifier.ia64, 3, 'R_X86_64_GOT32'),
  ia64GOT32(ElfArchitectureIdentifier.ia64, 4, 'R_X86_64_PLT32'),
  ia64COPY(ElfArchitectureIdentifier.ia64, 5, 'R_X86_64_COPY'),
  ia64GLOB_DAT(ElfArchitectureIdentifier.ia64, 6, 'R_X86_64_GLOB_DAT'),
  ia64JUMP_SLOT(ElfArchitectureIdentifier.ia64, 7, 'R_X86_64_JUMP_SLOT'),
  ia64RELATIVE(ElfArchitectureIdentifier.ia64, 8, 'R_X86_64_RELATIVE'),
  ia64GOTPCREL(ElfArchitectureIdentifier.ia64, 9, 'R_X86_64_GOTPCREL'),
  ia6432(ElfArchitectureIdentifier.ia64, 10, 'R_X86_64_32'),
  ia6432S(ElfArchitectureIdentifier.ia64, 11, 'R_X86_64_32S'),
  ia6416(ElfArchitectureIdentifier.ia64, 12, 'R_X86_64_16'),
  ia64PC16(ElfArchitectureIdentifier.ia64, 13, 'R_X86_64_PC16'),
  ia648(ElfArchitectureIdentifier.ia64, 14, 'R_X86_64_8'),
  ia64PC8(ElfArchitectureIdentifier.ia64, 15, 'R_X86_64_PC8'),
  ia64DTPMOD64(ElfArchitectureIdentifier.ia64, 16, 'R_X86_64_DTPMOD64'),
  ia64DTPOFF64(ElfArchitectureIdentifier.ia64, 17, 'R_X86_64_DTPOFF64'),
  ia64TPOFF64(ElfArchitectureIdentifier.ia64, 18, 'R_X86_64_TPOFF64'),
  ia64TLSGD(ElfArchitectureIdentifier.ia64, 19, 'R_X86_64_TLSGD'),
  ia64TLSLD(ElfArchitectureIdentifier.ia64, 20, 'R_X86_64_TLSLD'),
  ia64DTPOFF32(ElfArchitectureIdentifier.ia64, 21, 'R_X86_64_DTPOFF32'),
  ia64GOTTPOFF(ElfArchitectureIdentifier.ia64, 22, 'R_X86_64_GOTTPOFF'),
  ia64TPOFF32(ElfArchitectureIdentifier.ia64, 23, 'R_X86_64_TPOFF32'),
  ia64PC64(ElfArchitectureIdentifier.ia64, 24, 'R_X86_64_PC64'),
  ia64GOTOFF64(ElfArchitectureIdentifier.ia64, 25, 'R_X86_64_GOTOFF64'),
  ia64GOTPC32(ElfArchitectureIdentifier.ia64, 26, 'R_X86_64_GOTPC32'),
  ia64GOT64(ElfArchitectureIdentifier.ia64, 27, 'R_X86_64_GOT64'),
  ia64GOTPCREL64(ElfArchitectureIdentifier.ia64, 28, 'R_X86_64_GOTPCREL64'),
  ia64GOTPC64(ElfArchitectureIdentifier.ia64, 29, 'R_X86_64_GOTPC64'),
  ia64GOTPLT64(ElfArchitectureIdentifier.ia64, 30, 'R_X86_64_GOTPLT64'),
  ia64PLTOFF64(ElfArchitectureIdentifier.ia64, 31, 'R_X86_64_PLTOFF64'),
  ia64SIZE32(ElfArchitectureIdentifier.ia64, 32, 'R_X86_64_SIZE32'),
  ia64SIZE64(ElfArchitectureIdentifier.ia64, 33, 'R_X86_64_SIZE64'),
  ia64GOTPC32TLSDESC(
      ElfArchitectureIdentifier.ia64, 34, 'R_X86_64_GOTPC32_TLSDESC'),
  ia64TLSDESCCALL(ElfArchitectureIdentifier.ia64, 35, 'R_X86_64_TLSDESC_CALL'),
  ia64TLSDESC(ElfArchitectureIdentifier.ia64, 36, 'R_X86_64_TLSDESC'),
  ia64IRELATIVE(ElfArchitectureIdentifier.ia64, 37, 'R_X86_64_IRELATIVE'),
  ia64RELATIVE64(ElfArchitectureIdentifier.ia64, 38, 'R_X86_64_RELATIVE64'),
  ia64GOTPCRELX(ElfArchitectureIdentifier.ia64, 41, 'R_X86_64_GOTPCRELX'),
  ia64REXGOTPCRELX(
      ElfArchitectureIdentifier.ia64, 42, 'R_X86_64_REX_GOTPCRELX'),
  ia64NUM(ElfArchitectureIdentifier.ia64, 43, 'R_X86_64_NUM'),

  // ARM relocation types
  armNone(ElfArchitectureIdentifier.arm, 0, 'R_ARM_NONE'),
  armPC24(ElfArchitectureIdentifier.arm, 1, 'R_ARM_PC24'),
  armABS32(ElfArchitectureIdentifier.arm, 2, 'R_ARM_ABS32'),
  armREL32(ElfArchitectureIdentifier.arm, 3, 'R_ARM_REL32'),
  armTHMCALL(ElfArchitectureIdentifier.arm, 10, 'R_ARM_THM_CALL'),
  armCOPY(ElfArchitectureIdentifier.arm, 20, 'R_ARM_COPY'),
  armGLOBDAT(ElfArchitectureIdentifier.arm, 21, 'R_ARM_GLOB_DAT'),
  armJUMPSLOT(ElfArchitectureIdentifier.arm, 22, 'R_ARM_JUMP_SLOT'),
  armRELATIVE(ElfArchitectureIdentifier.arm, 23, 'R_ARM_RELATIVE'),
  armCALL(ElfArchitectureIdentifier.arm, 28, 'R_ARM_CALL'),
  armJUMP24(ElfArchitectureIdentifier.arm, 30, 'R_ARM_JUMP24'),
  armTARGET1(ElfArchitectureIdentifier.arm, 38, 'R_ARM_TARGET1'),
  armV4BX(ElfArchitectureIdentifier.arm, 40, 'R_ARM_V4BX'),
  armPREL31(ElfArchitectureIdentifier.arm, 42, 'R_ARM_PREL31'),
  armMOVWABSNC(ElfArchitectureIdentifier.arm, 43, 'R_ARM_MOVW_ABS_NC'),
  armMOVTABS(ElfArchitectureIdentifier.arm, 44, 'R_ARM_TMOVT_ABS'),
  armMOVWPRELNC(ElfArchitectureIdentifier.arm, 45, 'R_ARM_MOVW_PREL_NC'),
  armMOVTPREL(ElfArchitectureIdentifier.arm, 46, 'R_ARM_MOVT_PREL'),
  armTHMMOVWABSNC(ElfArchitectureIdentifier.arm, 47, 'R_ARM_THM_MOVW_ABS_NC'),
  armTHMMOVTABS(ElfArchitectureIdentifier.arm, 48, 'R_ARM_THM_MOVT_ABS'),
  armTHMMOVWPRELNC(ElfArchitectureIdentifier.arm, 49, 'R_ARM_THM_MOVW_PREL_NC'),
  armTHMMOVTPREL(ElfArchitectureIdentifier.arm, 50, 'R_ARM_THM_MOVT_PREL');

  final int id;
  final String name;
  final ElfArchitectureIdentifier arch;

  const ElfRelocationType(this.arch, this.id, this.name);

  /// Finds a relocation type given [arch] and an [id].
  ///
  /// Throws a [StateError] if the id could not be found.
  static ElfRelocationType byArchitecture(
      ElfArchitectureIdentifier arch, int id) {
    for (ElfRelocationType type in ElfRelocationType.values) {
      if (type.id == id && type.arch.id == arch.id) return type;
    }
    return byId(id);
  }

  /// Finds a relocation type given an [id].
  ///
  /// Throws a [StateError] if the id could not be found.
  static ElfRelocationType byId(int id) {
    for (ElfRelocationType type in ElfRelocationType.values) {
      if (type.id == id) return type;
    }
    return ElfRelocationType.unknown;
  }
}

/// An enum containing dynamic tag types
enum ElfDynamicTag {
  none(0, 'DT_NULL', ''),
  needed(1, 'DT_NEEDED', ''),
  pltrelsz(2, 'DT_PLTRELSZ', ''),
  pltgot(3, 'DT_PLTGOT', ''),
  hash(4, 'DT_HASH', ''),
  strtab(5, 'DT_STRTAB', ''),
  symtab(6, 'DT_SYMTAB', ''),
  rela(7, 'DT_RELA', ''),
  relasz(8, 'DT_RELASZ', ''),
  relaent(9, 'DT_RELAENT', ''),
  strsz(10, 'DT_STRSZ', ''),
  syment(11, 'DT_SYMENT', ''),
  init(12, 'DT_INIT', ''),
  fini(13, 'DT_FINI', ''),
  soname(14, 'DT_SONAME', ''),
  rpath(15, 'DT_RPATH', ''),
  symbolic(16, 'DT_SYMBOLIC', ''),
  rel(17, 'DT_REL', ''),
  relsz(18, 'DT_RELSZ', ''),
  relent(19, 'DT_RELENT', ''),
  pltrel(20, 'DT_PLTREL', ''),
  debug(21, 'DT_DEBUG', ''),
  textrel(22, 'DT_TEXTREL', ''),
  jumprel(23, 'DT_JMPREL', ''),
  bindnow(24, 'DT_BIND_NOW', ''),
  initarray(25, 'DT_INIT_ARRAY', ''),
  finiarray(26, 'DT_FINI_ARRAY', ''),
  initarraysz(27, 'DT_INIT_ARRAYSZ', ''),
  finiarraysz(28, 'DT_FINI_ARRAYSZ', ''),
  runPath(29, 'DT_RUNPATH', ''),
  flags(30, 'DT_FLAGS', ''),
  encoding(31, 'DT_ENCODING', ''),
  array(32, 'DT_PREINIT_ARRAY', ''),
  arraysz(33, 'DT_PREINIT_ARRAYSZ', ''),
  os(0x6000000D, 'DT_LOOS', 'Reserved for OS semantics'),
  gnuHash(0x6ffffef5, 'DT_GNU_HASH', 'reference to GNU hash table'),
  relaCount(0x6ffffef9, 'DT_RELACOUNT', 'ELF32_Rela count'),
  relCount(0x6ffffefa, 'DT_RELCOUNT', 'ELF32_Rel count'),
  versym(0x6ffffff0, 'DT_VERSYM', 'Address of .gnu.version section table'),
  flags1(0x6ffffffb, 'DT_FLAGS_1', 'Flags_1'),
  verdef(0x6ffffffc, 'DT_VERDEF', 'Address of version definition'),
  verdefnum(0x6ffffffd, 'DT_VERDEFNUM', 'Number of version definitions'),
  verneeded(0x6ffffffe, 'DT_VERNEEDED', 'Address of version dependency table.'),
  verneednum(0x6fffffff, 'DT_VERNEEDNUM', 'Number of DT_VERNEEDED entries'),
  processor(0x70000000, 'DT_LOPROC', 'Reserved for processor semantics');

  final int id;
  final String name;
  final String description;

  const ElfDynamicTag(this.id, this.name, this.description);

  /// Finds a dynamic tag given an [id].
  ///
  /// Throws a [StateError] if the id could not be found.
  static ElfDynamicTag byId(int id) {
    for (ElfDynamicTag type in ElfDynamicTag.values) {
      if (type.id == id) return type;
    }
    if (id >= 0x60000000 && id <= 0x6fffffff) return ElfDynamicTag.os;
    if (id >= 0x70000000 && id <= 0x7fffffff) return ElfDynamicTag.processor;
    throw StateError('Unknown dynamic tag $id');
  }
}

/// An enum containing dynamic flags
enum ElfDynamicFlags {
  now1(0x00000001, 'DF_1_NOW', ''),
  global1(0x00000002, 'DF_1_GLOBAL', ''),
  group1(0x00000004, 'DF_1_GROUP', ''),
  nodelete1(0x00000008, 'DF_1_NODELETE', ''),
  loadfltr1(0x00000010, 'DF_1_LOADFLTR', ''),
  initfirst1(0x00000020, 'DF_1_INITFIRST', ''),
  noopen1(0x00000040, 'DF_1_NOOPEN', ''),
  origin1(0x00000080, 'DF_1_ORIGIN', ''),
  direct1(0x00000100, 'DF_1_DIRECT', ''),
  trans1(0x00000200, 'DF_1_TRANS', ''),
  interpose1(0x00000400, 'DF_1_INTERPOSE', ''),
  nodeflib1(0x00000800, 'DF_1_NODEFLIB', ''),
  nodump1(0x00001000, 'DF_1_NODUMP', ''),
  conflat1(0x00002000, 'DF_1_CONFALT', ''),
  endfiltee1(0x00004000, 'DF_1_ENDFILTEE', ''),
  dispreldne1(0x00008000, 'DF_1_DISPRELDNE', ''),
  disprelpnd1(0x00010000, 'DF_1_DISPRELPND', ''),
  nodirect1(0x00020000, 'DF_1_NODIRECT', ''),
  ignmuldef1(0x00040000, 'DF_1_IGNMULDEF', ''),
  noksyms1(0x00080000, 'DF_1_NOKSYMS', ''),
  nohdr1(0x00100000, 'DF_1_NOHDR', ''),
  edited1(0x00200000, 'DF_1_EDITED', ''),
  noreloc1(0x00400000, 'DF_1_NORELOC', ''),
  symintpose1(0x00800000, 'DF_1_SYMINTPOSE', ''),
  globaudit1(0x01000000, 'DF_1_GLOBAUDIT', ''),
  singleton1(0x02000000, 'DF_1_SINGLETON', ''),
  stud1(0x04000000, 'DF_1_STUB', ''),
  pie1(0x08000000, 'DF_1_PIE', ''),
  origin(0x1, 'DF_ORIGIN', ''),
  symbolic(0x2, 'DF_SYMBOLIC', ''),
  textrel(0x3, 'DF_TEXTREL', ''),
  bindnow(0x8, 'DF_BIND_NOW', '');

  final int id;
  final String name;
  final String description;

  const ElfDynamicFlags(this.id, this.name, this.description);

  /// Finds a dynamic flag given an [id].
  ///
  /// Throws a [StateError] if the id could not be found.
  static ElfDynamicFlags byId(int id) {
    for (ElfDynamicFlags type in ElfDynamicFlags.values) {
      if (type.id == id) return type;
    }
    throw StateError('Unknown dynamic flag $id');
  }

  // Check to see if a [flag] is set in [i]
  static bool isSet(int i, ElfDynamicFlags flag) {
    return (i & flag.id) > 0;
  }
}
