import '../dart_elf.dart';

/// An ELF section containing a symbol hash table.
class ElfHashTableSection extends ElfSection {
  final ElfHashTable _hashTable;

  ElfHashTableSection(super._meta, super._header, super._name, super._buffer)
      : _hashTable = _loadHashTable(_meta, _header, _buffer);

  /// Get the hash table for this section
  ElfHashTable get hashTable => _hashTable;

  static ElfHashTable _loadHashTable(
      ElfFileHeader meta, ElfSectionHeader header, ElfIoBuffer buffer) {
    buffer.seek(header.offset, absolute: true);

    int buckets = buffer.readInt(meta.endian);
    int chains = buffer.readInt(meta.endian);

    List<int> bucket = [];
    for (int i = 0; i < buckets; i++) {
      bucket.add(buffer.readInt(meta.endian));
    }
    List<int> chain = [];
    for (int i = 0; i < chains; i++) {
      chain.add(buffer.readInt(meta.endian));
    }
    return (bucket: bucket, chain: chain, nbucket: buckets, nchain: chains);
  }
}
