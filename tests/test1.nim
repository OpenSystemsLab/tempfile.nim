import tempfile


proc ct(): string {.compileTime.} =
  result = mktempUnsafe()
  echo "Compile time: " & result

const a = ct()


echo "Run time: " & a
