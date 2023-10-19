import 'dart:typed_data';

import '../dart_elf.dart';

/// An ELF segment
class ElfSegment {
  final ElfFileHeader _meta;
  final ElfSegmentHeader _header;
  final ElfIoBuffer _buffer;

  /// Get the ELF file header
  ElfFileHeader get meta => _meta;

  /// Get the ELF segment header
  ElfSegmentHeader get header => _header;

  /// Get the IO buffer associated with this segment
  ElfIoBuffer get buffer => _buffer;

  ElfSegment(this._meta, this._header, this._buffer);

  /// Check to see if the segment has the read permission set
  bool get readable =>
      ElfSegmentPermissions.isSet(header.flags, ElfSegmentPermissions.read);

  /// Check to see if the segment has the write permission set
  bool get writeable =>
      ElfSegmentPermissions.isSet(header.flags, ElfSegmentPermissions.write);

  /// Check to see if the segment has the execute permission set
  bool get executable =>
      ElfSegmentPermissions.isSet(header.flags, ElfSegmentPermissions.exec);

  /// Get the raw data for the segment
  Uint8List data() {
    _buffer.seek(_header.offset, absolute: true);
    return _buffer.readBytes(_header.fsize);
  }
}
