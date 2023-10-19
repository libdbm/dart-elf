A pure Dart library for parsing ELF binary files.

## Features

This library makes fairly heavy use of records and enums to represent the core data structures.

* Basic parsing of common ELF structures
* Reasonable abstractions for dealing with the various OS and CPU specific data
* A partial clone of `readelf`

## Usage

Look at the sample in the `/example` folder for more detail.

```dart

ElfParser reader = ElfParser.fromRandomAccessFile(file.openSync());
```

## Additional information

For more information look at the various ELF parsing descriptions. For example:

* https://en.wikipedia.org/wiki/Executable_and_Linkable_Format
* https://refspecs.linuxbase.org/LSB_5.0.0/LSB-Core-generic/LSB-Core-generic/tocobjformat.html
