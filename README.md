# tempfile.nim
This module contains basic procs for creating temporary files and directories

Installation
============
```
$ nimble install tempfile
```
Usage
=====
```nim
import tempfile

var (file, name) = mkstemp()
echo name
var dir = mkdtemp()
echo dir
```
