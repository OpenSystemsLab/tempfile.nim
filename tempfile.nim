## This module contains basic procs for
## creating temporary files and directories
##
## This module is impressed by Python's `tempfile` module

import os
import math
when defined(windows):
  import winlean
else:
  import posix

const
  MAX_RETRIES = 9999

randomize()
proc mktemp*(prefix = "tmp", suffix = "", dir = "", len = 8): string {.deprecated.} =
  ## Returns a unique temporary file name. The file is not created.
  let charset {.global.} = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  var name = newString(len)
  for x in 0..MAX_RETRIES:
    for i in 0..len-1:
      name[i] = charset[random(charset.len-1)]

    if dir == "":
      result = getTempDir().joinPath(prefix & name & suffix)
    else:
      result = dir.joinPath(prefix & name & suffix)
      
    if not result.existsFile:
      return result
  raise newException(IOError, "Unable to find an available temporary file")

proc mkstemp*(prefix = "tmp", suffix = "", dir = "", mode = fmRead): tuple[fd: File, name: string] =
  ## Creates and returns a unique temporary file.
  var name: string
  var file: File
  for x in 0..MAX_RETRIES:
    name = mktemp(prefix, suffix, dir)
    try:
      # force create file
      file = name.open(fmWrite)
      if mode != fmWrite:
        # reopen as user specified mode
        if not file.reopen(name, mode):
          raise newException(IOError, "Unable to change file mode")
      return (file, name)
    except IOError:
      #echo getCurrentExceptionMsg()
      if name.existsFile:
        name.removeFile      
      
  raise newException(IOError, "Unable to create temporary file")

proc mkdtemp*(prefix = "tmp", suffix = "", dir = ""): string = 
  ## Returns value is the pathname of the directory.
  var path: string
  for x in 0..MAX_RETRIES:
    path = mktemp(prefix, suffix, dir)
    try:
      when defined(windows):
        createDirectoryW(path)
      else:
        discard mkdir(path, 0700)
      return path
    except:
      discard
  raise newException(IOError, "Unable to create temporary directory")
      
when isMainModule:
  var (file, name) = mkstemp()  
  echo name, " ", getFileInfo(file).id
  assert name.existsFile
  assert getFileHandle(file) != -1
  file.close()
  name.removeFile

  var dir = mkdtemp()
  echo dir
  assert dir.existsDir()
  dir.removeDir
  
