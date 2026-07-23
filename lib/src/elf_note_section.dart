import 'dart:typed_data';

import '../dart_elf.dart';

/// A section containing one or more notes.
///
/// A single SHT_NOTE section can hold any number of records laid out back to
/// back, which is common in core dumps and vendor note sections. The singular
/// accessors describe the first record; use [notes] to reach the rest.
class ElfNoteSection extends ElfSection {
  final List<ElfNote> _notes;

  ElfNoteSection(super._meta, super._header, super._name, super._buffer)
      : _notes = _readNotes(_meta, _header, _buffer);

  /// Get every note in this section, in the order they appear
  List<ElfNote> get notes => List.unmodifiable(_notes);

  /// Get the note type
  ElfNoteType get noteType => ElfNoteType.byId(_first.tid);

  /// Get the note size
  int get noteSize => _first.descsz;

  /// Get the note name
  String get noteName => _first.name;

  ElfNote get _first {
    if (_notes.isEmpty) {
      throw ElfFormatException(
          'Note section ${name.isEmpty ? '?' : name} is empty',
          offset: header.offset);
    }
    return _notes.first;
  }

  /// Assuming the note is a GNU ABI descriptor, read in the note
  ///
  /// Throws a [StateError] if this is not a GNU ABI descriptor note
  ElfGnuAbiDescriptor readGnuAbiDescriptor([final ElfNote? note]) {
    final ElfNote target = note ?? _first;
    if (ElfNoteType.byId(target.tid) != ElfNoteType.gnuAbiTag) {
      throw StateError('Not a GNU ABI descriptor');
    }
    if (target.descsz < 16) {
      throw ElfFormatException(
          'GNU ABI descriptor needs 16 bytes, note holds ${target.descsz}',
          offset: target.descoff);
    }
    buffer.seek(target.descoff, absolute: true);
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
  ElfGnuBuildId readGnuBuildId([final ElfNote? note]) {
    final ElfNote target = note ?? _first;
    if (ElfNoteType.byId(target.tid) != ElfNoteType.gnuBuildId) {
      throw StateError('Not a GNU build id');
    }
    Uint8List raw = _descriptor(target);
    return (
      raw: raw,
      text: raw.map((e) => e.toRadixString(16).padLeft(2, '0')).join()
    );
  }

  /// Read the note as a HEX string
  String readHexString([final ElfNote? note]) {
    return _descriptor(note ?? _first)
        .map((e) => e.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  /// Assuming the note is a GNU gold id, read in the note
  ///
  /// Throws a [StateError] if this is not a GNU gold id note
  ElfGnuGoldVersion readGnuGoldVersion([final ElfNote? note]) {
    final ElfNote target = note ?? _first;
    if (ElfNoteType.byId(target.tid) != ElfNoteType.gnuGoldVersion) {
      throw StateError('Not a GNU build id');
    }
    Uint8List raw = _descriptor(target);
    return (raw: raw, text: String.fromCharCodes(raw));
  }

  /// Read in a generic note
  String readNote([final ElfNote? note]) {
    return String.fromCharCodes(_descriptor(note ?? _first));
  }

  Uint8List _descriptor(final ElfNote note) {
    buffer.seek(note.descoff, absolute: true);
    return buffer.readBytes(note.descsz);
  }

  /// Round [value] up to the next 4 byte boundary, as note records are aligned
  static int _align(final int value) => (value + 3) & ~3;

  static List<ElfNote> _readNotes(
      ElfFileHeader meta, ElfSectionHeader header, ElfIoBuffer buffer) {
    final List<ElfNote> ret = [];
    final int limit = header.offset + header.size;
    int position = header.offset;

    // Every record is a 12 byte prologue followed by an aligned name and an
    // aligned descriptor. Sizes come from the file, so each one is checked
    // against what is left of the section before it is used.
    while (position + 12 <= limit) {
      buffer.seek(position, absolute: true);
      final int namesz = buffer.readInt(meta.endian);
      final int descsz = buffer.readInt(meta.endian);
      final int tid = buffer.readInt(meta.endian);
      if (namesz < 0 || descsz < 0) {
        throw ElfFormatException('Note has a negative name or descriptor size',
            offset: position);
      }
      final int nameoff = position + 12;
      final int descoff = nameoff + _align(namesz);
      final int next = descoff + _align(descsz);
      if (descoff > limit || next > limit) {
        throw ElfFormatException(
            'Note of $namesz name and $descsz descriptor bytes overruns the section',
            offset: position);
      }

      // The name is null terminated within namesz bytes. A namesz of zero is
      // legal and means the note is anonymous.
      buffer.seek(nameoff, absolute: true);
      final String name =
          namesz == 0 ? '' : String.fromCharCodes(buffer.readBytes(namesz - 1));

      ret.add((
        namesz: namesz,
        descsz: descsz,
        tid: tid,
        name: name,
        descoff: descoff
      ));
      position = next;
    }
    return ret;
  }
}
