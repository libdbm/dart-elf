import 'dart:io';
import 'dart:typed_data';

import 'elf_format_exception.dart';

/// A class representing an ELF IO buffer with convenience methods for reading specific data types.
abstract class ElfIoBuffer {
  final int _size;
  int _offset;

  ElfIoBuffer({int offset = 0, int size = 0})
      : _offset = offset,
        _size = size;

  /// Get the current offset
  int get offset => _offset;

  /// Get the size of the buffer
  int get size => _size;

  /// Read a byte at a given location
  int operator [](int i) {
    seek(i);
    return readByte();
  }

  /// Seek to a given [offset], relative from the beginning if [absolute]
  /// is true
  ///
  /// Seeking to exactly [size] is legal and leaves the buffer at EOF. Any
  /// other position outside the buffer throws an [ElfFormatException].
  int seek(int offset, {bool absolute = true}) {
    final int target = absolute ? offset : _offset + offset;
    if (target < 0 || target > _size) {
      throw ElfFormatException(
          'Offset $target is outside the file (size $_size)',
          offset: target);
    }
    _offset = target;
    return offset;
  }

  /// Verify that [count] bytes remain readable from the current position
  void _require(final int count) {
    if (_offset + count > _size) {
      throw ElfFormatException(
          'Truncated file: needed $count bytes, ${_size - _offset} remain',
          offset: _offset);
    }
  }

  /// Skip forward [skip] bytes from the current position
  int skip(int skip) {
    return seek(skip, absolute: false);
  }

  /// read a single byte, increment offset by 1. return -1 on EOF
  int readByte();

  /// Read a short (16 bit) value based on [endian]
  int readShort(Endian endian) {
    _require(2);
    int b1 = readByte();
    int b2 = readByte();
    if (endian == Endian.little) {
      return ((b2 & 0xff) << 8) | (b1 & 0xff);
    } else {
      return ((b1 & 0xff) << 8) | (b2 & 0xff);
    }
  }

  /// Read an int (32 bit) value based on [endian]
  int readInt(Endian endian) {
    _require(4);
    int b1 = readByte();
    int b2 = readByte();
    int b3 = readByte();
    int b4 = readByte();
    if (endian == Endian.little) {
      return (b4 & 0xff) << 24 |
          (b3 & 0xff) << 16 |
          (b2 & 0xff) << 8 |
          (b1 & 0xff);
    } else {
      return (b1 & 0xff) << 24 |
          (b2 & 0xff) << 16 |
          (b3 & 0xff) << 8 |
          (b4 & 0xff);
    }
  }

  /// Read a long (64 bit) value based on [endian]
  int readLong(Endian endian) {
    _require(8);
    int b1 = readByte();
    int b2 = readByte();
    int b3 = readByte();
    int b4 = readByte();
    int b5 = readByte();
    int b6 = readByte();
    int b7 = readByte();
    int b8 = readByte();

    if (endian == Endian.little) {
      return (b8 << 56) |
          (b7 & 0xff) << 48 |
          (b6 & 0xff) << 40 |
          (b5 & 0xff) << 32 |
          (b4 & 0xff) << 24 |
          (b3 & 0xff) << 16 |
          (b2 & 0xff) << 8 |
          (b1 & 0xff);
    } else {
      return (b1 << 56) |
          (b2 & 0xff) << 48 |
          (b3 & 0xff) << 40 |
          (b4 & 0xff) << 32 |
          (b5 & 0xff) << 24 |
          (b6 & 0xff) << 16 |
          (b7 & 0xff) << 8 |
          (b8 & 0xff);
    }
  }

  /// Read a list of [length] bytes from the current position
  ///
  /// The request is validated against the remaining bytes before anything is
  /// allocated, so an implausible length from a malformed file cannot exhaust
  /// memory.
  Uint8List readBytes(int length) {
    if (length < 0) {
      throw ElfFormatException('Negative read length $length', offset: _offset);
    }
    _require(length);
    Uint8List ret = Uint8List(length);
    for (int i = 0; i < length; i++) {
      ret[i] = readByte();
    }
    return ret;
  }

  /// Read a sequence of bytes into [buffer]
  int readInto(Uint8List buffer) {
    int read = 0;
    for (int i = 0; i < buffer.length && _offset < _size; i++) {
      int byte = readByte();
      if (byte == -1) break;
      read += 1;
      buffer[i] = byte;
    }
    return read;
  }

  /// Release any resource backing this buffer
  ///
  /// Buffers that own no resource do nothing. Reading after a close is not
  /// supported.
  void close() {}
}

/// ElfIoBuffer backed by a list of bytes held in memory
class ElfInMemoryBuffer extends ElfIoBuffer {
  final Uint8List _bytes;

  ElfInMemoryBuffer.fromBytes(Uint8List bytes)
      : _bytes = bytes,
        super(offset: 0, size: bytes.length);

  @override
  int readByte() {
    if (_offset < _size) {
      return _bytes[_offset++];
    }
    return -1;
  }
}

/// ElfIoBuffer backed by a RandomAccessFile
///
/// The file handle is supplied by the caller, who keeps ownership of it unless
/// the buffer was created through [ElfReader.fromFile].
class ElfRandomFileBuffer extends ElfIoBuffer {
  final RandomAccessFile _file;

  /// Where the file handle actually sits, which only needs to be corrected
  /// when it drifts from the logical offset. Seeking on every byte turns a
  /// large table into millions of system calls.
  int _position = 0;

  ElfRandomFileBuffer.fromRandomAccessFile(RandomAccessFile file)
      : _file = file,
        super(offset: 0, size: file.lengthSync());

  @override
  int readByte() {
    if (_offset < _size) {
      _sync();
      _offset += 1;
      _position += 1;
      return _file.readByteSync();
    }
    return -1;
  }

  @override
  Uint8List readBytes(int length) {
    if (length < 0) {
      throw ElfFormatException('Negative read length $length', offset: _offset);
    }
    _require(length);
    _sync();
    final Uint8List ret = Uint8List(length);
    final int read = _file.readIntoSync(ret);
    _offset += read;
    _position += read;
    if (read != length) {
      throw ElfFormatException('Short read: wanted $length bytes, got $read',
          offset: _offset);
    }
    return ret;
  }

  @override
  int readInto(Uint8List buffer) {
    final int remaining = _size - _offset;
    final int wanted = buffer.length < remaining ? buffer.length : remaining;
    if (wanted <= 0) return 0;
    _sync();
    final int read = _file.readIntoSync(buffer, 0, wanted);
    _offset += read;
    _position += read;
    return read;
  }

  /// Move the file handle to the logical offset if it has drifted
  void _sync() {
    if (_position != _offset) {
      _position = _offset;
      _file.setPositionSync(_position);
    }
  }

  @override
  void close() {
    _file.closeSync();
  }
}
