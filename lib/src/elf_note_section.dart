import 'dart:typed_data';

import '../dart_elf.dart';

/// A section containing a note.
class ElfNoteSection extends ElfSection {
  /// Parsed data record
  final ({
    int namesz,
    int descsz,
    int tid,
    String name,
    int descoff,
  }) _data;

  ElfNoteSection(super._meta, super._header, super._name, super._buffer)
      : _data = _readData(_meta, _header, _buffer);

  /// Get the note type
  ElfNoteType get noteType => ElfNoteType.byId(_data.tid);

  /// Get the note size
  int get noteSize => _data.descsz;

  /// Get the note name
  String get noteName => _data.name;

  /// Assuming the note is a GNU ABI descriptor, read in the note
  ///
  /// Throws a [StateError] if this is not a GNU ABI descriptor note
  ElfGnuAbiDescriptor readGnuAbiDescriptor() {
    if (noteType != ElfNoteType.gnuAbiTag) {
      throw StateError('Not a GNU ABI descriptor');
    }
    buffer.seek(_data.descoff, absolute: true);
    return (
      os: buffer.readInt(meta.endian),
      major: buffer.readInt(meta.endian),
      minor: buffer.readInt(meta.endian),
      sub: buffer.readInt(meta.endian)
    );
  }

  /// Assuming the note is a GNU build id, read in the note
  ///
  /// Throws a [StateError] if this is not a GNU build id note
  ElfGnuBuildId readGnuBuildId() {
    if (noteType != ElfNoteType.gnuBuildId) {
      throw StateError('Not a GNU build id');
    }
    buffer.seek(_data.descoff, absolute: true);
    Uint8List raw = buffer.readBytes(_data.descsz);
    return (
      raw: raw,
      text: raw.map((e) => e.toRadixString(16).padLeft(2, '0')).join()
    );
  }

  /// Read the note as a HEX string
  String readHexString() {
    buffer.seek(_data.descoff, absolute: true);
    Uint8List raw = buffer.readBytes(_data.descsz);
    return raw.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Assuming the note is a GNU gold id, read in the note
  ///
  /// Throws a [StateError] if this is not a GNU gold id note
  ElfGnuGoldVersion readGnuGoldVersion() {
    if (noteType != ElfNoteType.gnuGoldVersion) {
      throw StateError('Not a GNU build id');
    }
    buffer.seek(_data.descoff, absolute: true);
    Uint8List raw = buffer.readBytes(_data.descsz);
    return (raw: raw, text: String.fromCharCodes(raw));
  }

  /// Read in a generic note
  String readNote() {
    buffer.seek(_data.descoff, absolute: true);
    Uint8List raw = buffer.readBytes(_data.descsz);
    return String.fromCharCodes(raw);
  }

  static _readData(
      ElfFileHeader meta, ElfSectionHeader header, ElfIoBuffer buffer) {
    buffer.seek(header.offset, absolute: true);
    int namesz = buffer.readInt(meta.endian);
    int descsz = buffer.readInt(meta.endian);
    int tid = buffer.readInt(meta.endian);
    String name = String.fromCharCodes(buffer.readBytes(namesz - 1));
    buffer.skip(1);
    buffer.skip(namesz % 4);
    return (
      namesz: namesz,
      descsz: descsz,
      tid: tid,
      name: name,
      descoff: buffer.offset
    );
  }
}
