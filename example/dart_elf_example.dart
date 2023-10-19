import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_elf/dart_elf.dart';
import 'package:sprintf/sprintf.dart';

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addFlag("all", abbr: "a",
        help: "Dump all information",
        defaultsTo: true)..addFlag(
        "file-header", abbr: "h", help: "Dump the file header")..addFlag(
        "program-headers",
        abbr: "l",
        help: "Dump the program headers",
        aliases: ['segments'])..addFlag("section-headers",
        abbr: "S",
        help: "Dump the section headers",
        aliases: ['sections'])..addFlag("symbols",
        abbr: "s", help: "Dump the symbol table", aliases: ['syms'])..addFlag(
        "notes", abbr: "n", help: "Dump notes", aliases: [])..addFlag(
        "help", abbr: "H", help: "Display this information")..addFlag(
        "version", abbr: "v", help: "Display the version number")
    ..addOption('file', help: 'ELF file to parser', mandatory: true);
  ArgResults args = parser.parse(arguments);
  if (!args.wasParsed('file') || args['help']) {
    print(parser.usage);
    exit(-1);
  }
  File file = File(args['file']);
  if (!file.existsSync()) {
    print('File not found: ${args['file']}');
    exit(-1);
  }

  ElfReader reader = ElfReader.fromRandomAccessFile(file.openSync());
  bool fileHeader = args['all'] || args['file-header'];
  bool sectionHeaders = args['all'] || args['section-headers'];
  bool programHeaders = args['all'] || args['program-headers'];
  bool symbolTables = args['all'] || args['symbols'];
  bool notes = args['all'] || args['notes'];

  if (fileHeader) {
    _printFileHeader(reader);
  }
  if (sectionHeaders) {
    _printSectionHeaders(reader);
  }
  if (programHeaders) {
    _printProgramHeaders(reader);
  }
  if (programHeaders && reader.header.shnum > 0) {
    _printSectionToSegmentMapping(reader);
  }
  if (sectionHeaders) {
    _printDynamicSections(reader);
    // TODO: Split this into a different option
    _printRelocationSections(reader);
  }
  if (symbolTables) {
    if (reader.symbolTableSection != null) {
      _printSymbolTable(reader, reader.symbolTableSection!);
    }
    if (reader.dynamicSymbolTableSection != null) {
      _printSymbolTable(reader, reader.dynamicSymbolTableSection!);
    }
  }
  if (notes) {
    for (var section in reader.sections) {
      if (section is ElfNoteSection) {
        _printNotes(reader, section);
      }
    }
  }
  exit(0);
}

void _printNotes(ElfReader reader, ElfNoteSection section) {
  print('Displaying notes found in: ${section.name}');
  print('  Owner                Data size 	Description');
  print(sprintf('  %-20.20s %#08x   %s',
      [section.noteName, section.noteSize, section.noteType.name]));
  switch (section.noteType) {
    case ElfNoteType.gnuAbiTag:
      ElfGnuAbiDescriptor d = section.readGnuAbiDescriptor();
      String os = sprintf('Unknown(%d)', [d.os]);
      if (d.os == 0) {
        os = 'Linux';
      }
      print(
          sprintf('    OS: %s, ABI: %d.%d.%d', [os, d.major, d.minor, d.sub]));
      break;
    case ElfNoteType.gnuBuildId:
      print('    Build ID: ${section
          .readGnuBuildId()
          .text}');
      break;
    case ElfNoteType.gnuProperties:
    // TODO: Dump the actual properties
      print('    Properties: ${section.readHexString()}');
      break;
    case ElfNoteType.gnuHwcap:
    // TODO: Dump the hardware capabilities
      print('    Hardware Cap: ${section.readHexString()}');
      break;
    default:
      print('    ${section.readNote()}');
      break;
  }
  print('');
}

void _printSymbolTable(ElfReader reader, ElfSymbolTableSection section) {
  print(sprintf('Symbol table \'%s\' contains %d entries:',
      [section.name, section.symbols.length]));

  print('   Num:    Value  Size Type         Bind    Vis      Ndx Name');
  ElfStringTable stringTable = section.name == '.dynsym'
      ? reader.dynamicStringTable!
      : reader.stringTable!;
  for (var i = 0; i < section.symbols.length; i++) {
    var symbol = section.symbols[i];
    print(sprintf('%6d: %08x %5d %-12.12s %-7.7s %-8.8s %3.3s %s', [
      i,
      symbol.value,
      symbol.size,
      symbol.type.name,
      symbol.binding.name,
      symbol.visibility.name,
      '???',
      stringTable.at(symbol.nindex),
    ]));
  }
  print('');
}

void _printRelocationSections(ElfReader reader) {
  for (var section in reader.sections) {
    if (section is ElfRelocationSection) {
      print(sprintf(
          'Relocation section \'%s\' at offset %#0x contains %d entries:',
          [section.name, section.header.offset, section.entries.length]));
      print('Offset    Info      Type             Value     Name');
      ElfSymbolTableSection? symbolTable = reader.dynamicSymbolTableSection;
      for (ElfRelocation h in section.entries) {
        var tid = _getRelocationType(reader.header, h.info);
        var idx = _getRelocationIndex(reader.header, h.info);
        var type = ElfRelocationType.byArchitecture(reader.header.arch, tid);
        var binding = symbolTable?.symbols[idx];
        var value = binding?.value ?? -1;
        var nindex = binding?.nindex ?? -1;
        var addend = h.addend != null ? '+ ${h.addend!.toRadixString(10)}' : '';
        var name = reader.dynamicStringTable?.at(nindex) ?? '-';
        print(sprintf('%08x  %08x  %-15.15s  %08x  %s %s',
            [h.offset, h.info, type.name, value, name, addend]));
      }
      print('');
    }
  }
}

int _getRelocationType(ElfFileHeader header, int info) {
  return header.word == ElfWordSize.word32Bit ? info & 0xff : info & 0xffffffff;
}

int _getRelocationIndex(ElfFileHeader header, int info) {
  return info >> (header.word == ElfWordSize.word32Bit ? 8 : 32);
}

void _printDynamicSections(ElfReader reader) {
  for (var section in reader.sections) {
    if (section is ElfDynamicSection) {
      int stringTableSize = 0;
      ElfStringTable? stringTable;

      // first try to load the string table for the dynamic section
      for (ElfDynamicEntry entry in section.entries) {
        if (entry.tag == ElfDynamicTag.strsz.id) {
          stringTableSize = entry.value;
        }
        if (entry.tag == ElfDynamicTag.strtab.id) {
          int offset = reader.toFileOffset(entry.value);
          stringTable = ElfStringTable(reader.buffer, offset, stringTableSize);
        }
      }
      print(sprintf('Dynamic section at offset %#x contains %d entries:',
          [section.header.offset, section.entries.length]));
      print('  Tag           Type              Name/Value');
      for (ElfDynamicEntry entry in section.entries) {
        int tag = entry.tag;
        String name = ElfDynamicTag
            .byId(entry.tag)
            .name;
        String value = '0x${entry.value.toRadixString(16)}';
        if (tag == ElfDynamicTag.needed.id) {
          var name = stringTable?.at(entry.value) ?? '(missing strtab)';
          value = 'Shared library: [$name]';
        }
        if (tag == ElfDynamicTag.strsz.id ||
            tag == ElfDynamicTag.initarraysz.id ||
            tag == ElfDynamicTag.finiarraysz.id ||
            tag == ElfDynamicTag.pltrelsz.id ||
            tag == ElfDynamicTag.relsz.id ||
            tag == ElfDynamicTag.relent.id) {
          value = '${entry.value} (bytes)';
        }
        if (tag == ElfDynamicTag.verneednum.id) {
          value = entry.value.toRadixString(10);
        }
        print(sprintf('%#010x    %-16s  %s', [tag, name, value]));
      }
      print('');
    }
  }
}

void _printFileHeader(ElfReader reader) {
  ElfFileHeader header = reader.header;
  var magic = header.data
      .sublist(0, 16)
      .map((e) => e.toRadixString(16).padLeft(2, '0'))
      .join(' ');
  print('ELF Header:');
  print(' Magic:   $magic');
  print(' Class:                     ${header.word.id}');
  print(' Data:                      ${header.type}');
  print(' Version:                   ${header.version}');
  print(' OS/ABI:                    ${header.abi.description}');
  print(' ABI Version:               ${header.abiVersion}');
  print(' Type:                      ${header.type.description}');
  print(' Machine:                   ${header.arch.description}');
  print(' Version:                   ${header.version}');
  print(' Entry point address:       0x${header.entry.toRadixString(16)}');
  print(' Start of program headers:  ${header.phoff} (bytes into file)');
  print(' Start of section headers:  ${header.shoff} (bytes into file)');
  print(' Flags:                     0x${header.flags.toRadixString(16)}');
  print(' Size of this header:       ${header.data.length} (bytes)');
  print(' Size of program headers:   ${header.phentsize} (bytes)');
  print(' Number of program headers: ${header.phnum}');
  print(' Size of section headers:   ${header.shentsize} (bytes)');
  print(' Number of section headers: ${header.shnum}');
  print(' Header string table index: ${header.shstrndx}');
  print('');
}

void _printSectionHeaders(ElfReader reader) {
  print('Section Headers:');
  print(' [ Nr] Name              Type             Address           Offset');
  print('       Size              EntSize          Flags  Link  Info  Align');
  int count = 0;
  for (var section in reader.sections) {
    print(sprintf(' [%3i] %-16.16s %-16.16s %16.16x %16.16x', [
      count++,
      section.name,
      section.type.name,
      section.header.addr,
      section.header.offset
    ]));
    print(sprintf('       %16.16x %16.16i %10s %2i %2i %12i', [
      section.header.size,
      section.header.entsize,
      ElfSectionHeaderFlags.format(section.header.flags),
      section.header.link,
      section.header.info,
      section.header.align
    ]));
  }
  print('''Key to Flags:
  W (write), A (alloc), X (execute), M (merge), S (strings), I (info),
  L (link order), O (extra OS processing required), G (group), E (exclude)''');
  print('');
}

void _printProgramHeaders(ElfReader reader) {
  print('Program Headers:');
  print('  Type             Offset           VirtAddr           PhysAddr');
  print('                   FileSiz          MemSiz             Flags  Align');
  for (var segment in reader.segments) {
    print(sprintf('  %-16s %0#16x %0#16x %0#16x', [
      segment.header.type.name,
      segment.header.offset,
      segment.header.vaddr,
      segment.header.paddr
    ]));
    print(sprintf('  %-16s %0#16x %0#16x %-6s %0#x', [
      '',
      segment.header.fsize,
      segment.header.msize,
      ElfSegmentPermissions.format(segment.header.flags),
      segment.header.align,
    ]));
    if (segment.header.type == ElfSegmentType.interp) {
      var val = String.fromCharCodes(segment.data().takeWhile((v) => v != 0));
      print('    [Requesting program interpreter: $val]');
    }
  }
  print('');
}

void _printSectionToSegmentMapping(ElfReader reader) {
  print('Section to Segment mapping:');
  print('  Segment Sections...');
  int count = 0;
  for (var segment in reader.segments) {
    List<String> names = [];
    for (var section in reader.sections) {
      if (_sectionInSegment(section, segment) && section.name.isNotEmpty) {
        names.add(section.name);
      }
    }
    print(sprintf('   %3d   %s', [count++, names.join(' ')]));
  }
  print('');
}

bool _sectionInSegment(ElfSection section, ElfSegment segment) {
  ElfSectionType sectionType = section.type;

  // TODO: Make this align with ELF internal
  if (sectionType != ElfSectionType.nobits) {
    if (section.header.offset >= segment.header.offset &&
        section.header.offset - segment.header.offset <=
            segment.header.fsize - 1) {
      return true;
    }
  }

  return false;
}
