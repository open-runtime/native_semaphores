// Note this probably wont work for code obfuscation
bool LatePropertyAllocated<X>(Function function) {
  try {
    final allocated = function() is X;
    return allocated;
  } catch (error, trace) {
    return !(error.toString().contains('has not been initialized.') || (Error.throwWithStackTrace(error, trace)));
  }
}
