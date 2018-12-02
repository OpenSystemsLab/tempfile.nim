## This module contains basic procs for
## creating temporary files and directories
##
## This module is impressed by Python's `tempfile` module

import os, math, random

const
  MAX_RETRIES = 9999
  CHARSET = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

randomize()


proc getTempDir(): string =
  when defined(tempDir):
    const tempDir {.strdefine.}: string = nil
    return tempDir

  # Lines bellow are forked of Boost's filesystem library
  # https://github.com/boostorg/filesystem/blob/0703e62a317c6a8ec63fd87c556d0b8e8ac956df/src/operations.cpp#L1863

  when defined(posix):
    for env in ["TMP", "TEMP", "TMPDIR", "TEMPDIR"]:
      result = getenv(env)
      if result.len != 0 and result.dirExists:
        return result
    when defined(android):
      let default = "/data/local/tmp"
    else:
      let default = "/tmp"
    if default.dirExists:
      return default
  else:
    let envList = ["TMP", "TEMP", "LOCALAPPDATA", "USERPROFILE"]
    for i in 0..<envList.len:
      result = getenv(envList[i])
      if result.len != 0:
        if i >= 2:
          result = result.joinPath("Temp")
        if result.dirExists:
          return result
  raise newException(IOError, "unable to find temp directory")


proc mktempUnsafe*(prefix = "tmp", suffix = "", dir = "", len = 8): string =
  ## Returns a unique temporary file name. The file is not created.

  var name = newString(len)
  for x in 0..MAX_RETRIES:
    for i in 0..len-1:
      name[i] = CHARSET[random(CHARSET.len-1)]

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
    name = mktempUnsafe(prefix, suffix, dir)
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
    path = mktempUnsafe(prefix, suffix, dir)
    try:
      when declared(existsOrCreateDir):
        # Nim 0.15.3 or later
        createDir(path.parentDir)
        if not existsOrCreateDir(path):
          return path
      else:
        # Nim 0.15.2 or older (for compatibility)
        # A bit racy, but better than nothing
        if not path.existsDir:
          createDir(path)
          # Before 0.15.3 `createDir` didn't fail if `path` did
          # already exist, but was not a directory.
          if path.existsDir:
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
