import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// A class representing an ELF IO buffer with convenience methods for reading specific data types.
abstract class ElfIoBuffer {
  final int _size;
  int _offset;

  ElfIoBuffer({int offset = 0, int size = 0})
      : _offset = offset,
        _size = size;

  /// Get the current offset
  get offset => _offset;

  /// Get the size of the buffer
  get size => _size;

  /// Read a byte at a given location
  operator [](int i) {
    seek(i);
    return readByte();
  }

  /// Seek to a given [offset], relative from the beginning if [absolute]
  /// is true
  int seek(int offset, {bool absolute = true}) {
    if (absolute) {
      _offset = offset;
    } else {
      _offset += offset;
    }
    _offset = min(max(0, _offset), _size);
    return offset;
  }

  /// Skip forward [skip] bytes from the current position
  int skip(int skip) {
    return seek(skip, absolute: false);
  }

  /// read a single byte, increment offset by 1. return -1 on EOF
  int readByte();

  /// Read a short (16 bit) value based on [endian]
  int readShort(Endian endian) {
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
  Uint8List readBytes(int length) {
    Uint8List ret = Uint8List(length);
    for (int i = 0; i < length && _offset < _size; i++) {
      // TODO: need to check for eof
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
      buffer[i] = readByte();
    }
    return read;
  }
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
class ElfRandomFileBuffer extends ElfIoBuffer {
  final RandomAccessFile _file;

  ElfRandomFileBuffer.fromRandomAccessFile(RandomAccessFile file)
      : _file = file,
        super(offset: 0, size: file.lengthSync());

  @override
  int readByte() {
    if (_offset < _size) {
      _file.setPositionSync(_offset++);
      return _file.readByteSync();
    }
    return -1;
  }
}
