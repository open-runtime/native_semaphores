// Note this probably wont work for code obfuscation
typedef LatePropertySetParameterType = dynamic Function();

bool LatePropertyAssigned<X>(LatePropertySetParameterType function) {
  try {
    return function() is X;
  } catch (error, trace) {
    return !(error.toString().contains('has not been initialized.') || (Error.throwWithStackTrace(error, trace)));
  }
}
