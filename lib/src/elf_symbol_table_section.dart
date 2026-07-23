import '../dart_elf.dart';

/// A section containing a symbol table
class ElfSymbolTableSection extends ElfSection {
  List<ElfSymbol>? _symbols;

  ElfSymbolTableSection(super._meta, super._header, super._name, super._buffer);

  /// Get the possibly empty list of symbols in this section
  ///
  /// The table is parsed once on first access and cached. Repeated reads are
  /// common, and reparsing on each one makes indexed access quadratic.
  List<ElfSymbol> get symbols => _symbols ??= List.unmodifiable(_getSymbols());

  List<ElfSymbol> _getSymbols() {
    final int minimum = meta.word == ElfWordSize.word32Bit ? 16 : 24;
    if (header.entsize < minimum) {
      throw ElfFormatException(
          'Symbol table entry size ${header.entsize} is below the minimum $minimum',
          offset: header.offset);
    }
    List<ElfSymbol> ret = [];
    int count = (header.size ~/ header.entsize);
    for (int i = 0; i < count; i++) {
      ret.add(_parseSymbol(i));
    }
    return ret;
  }

  ElfSymbol _parseSymbol(int index) {
    int off = header.offset + (index * header.entsize);
    buffer.seek(off, absolute: true);
    int nindex, value, size, info, other, shndx;
    if (meta.word == ElfWordSize.word32Bit) {
      nindex = buffer.readInt(meta.endian); //4
      value = buffer.readInt(meta.endian); //4
      size = buffer.readInt(meta.endian); //4
      info = buffer.readByte(); //1
      other = buffer.readByte(); //1
      shndx = buffer.readShort(meta.endian); //2 16
    } else {
      nindex = buffer.readInt(meta.endian); //4
      info = buffer.readByte(); //1
      other = buffer.readByte(); //1
      shndx = buffer.readShort(meta.endian); //2
      value = buffer.readLong(meta.endian); //4
      size = buffer.readLong(meta.endian); //4 16
    }
    return (
      type: ElfSymbolType.byId(info & 0x0f),
      binding: ElfSymbolBinding.byId((info >>> 4) & 0xf),
      visibility: ElfSymbolVisibility.byId(other & 0x3),
      nindex: nindex,
      value: value,
      size: size,
      info: info,
      other: other,
      shndx: shndx
    );
  }
}
