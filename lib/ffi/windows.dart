import 'dart:ffi'
    show DynamicLibrary, DynamicLibraryExtension, Int32, IntPtr, Native, Pointer, Struct, Uint16, Uint32, Uint8;
import 'dart:math' show min;
import 'package:ffi/ffi.dart' show Utf16;

typedef HANDLE = IntPtr;
typedef LONG = Int32;
typedef BOOL = Uint32;
typedef DWORD = Uint32;
typedef LPCWSTR = Pointer<Utf16>;

/// The SECURITY_ATTRIBUTES structure contains the security descriptor for
/// an object and specifies whether the handle retrieved by specifying this
/// structure is inheritable. This structure provides security settings for
/// objects created by various functions, such as CreateFile, CreatePipe,
/// CreateProcess, RegCreateKeyEx, or RegSaveKeyEx.
///
/// {@category struct}
base class SECURITY_ATTRIBUTES extends Struct {
  @Uint32()
  external int nLength;

  external Pointer lpSecurityDescriptor;

  @Int32()
  external int bInheritHandle;
}

/// The SECURITY_DESCRIPTOR structure contains the security information
/// associated with an object. Applications use this structure to set and
/// query an object's security status.
///
/// {@category struct}
base class SECURITY_DESCRIPTOR extends Struct {
  @Uint8()
  external int Revision;

  @Uint8()
  external int Sbz1;

  @Uint16()
  external int Control;

  external Pointer Owner;

  external Pointer Group;

  external Pointer<ACL> Sacl;

  external Pointer<ACL> Dacl;
}

/// The ACL structure is the header of an access control list (ACL). A
/// complete ACL consists of an ACL structure followed by an ordered list of
/// zero or more access control entries (ACEs).
///
/// {@category struct}
base class ACL extends Struct {
  @Uint8()
  external int AclRevision;

  @Uint8()
  external int Sbz1;

  @Uint16()
  external int AclSize;

  @Uint16()
  external int AceCount;

  @Uint16()
  external int Sbz2;
}

/// Creates or opens a named or unnamed semaphore object.
///
/// [lpSecurityAttributes] is a pointer to a [SECURITY_ATTRIBUTES] structure that
/// determines whether the returned handle can be inherited by child processes.
/// If [lpSecurityAttributes] is [NULL], the semaphore object gets a default security descriptor.
/// The ACLs in the default security descriptor for a semaphore come from the primary
/// or impersonation token of the creator.
///
/// [lInitialCount] specifies the initial count for the semaphore object. This value
/// must be greater than or equal to zero and less than or equal to [lMaximumCount].
/// The semaphore is signaled when its count is greater than zero and nonsignaled when it is zero.
///
/// [lMaximumCount] is the maximum count for the semaphore object and must be greater than zero.
///
/// [lpName] is the name of the semaphore object. The name is case sensitive and limited to [MAX_PATH] characters.
/// If [lpName] is [NULL], the semaphore object is created without a name. Specifying a name allows the semaphore
/// to be shared between processes. If [lpName] matches the name of an existing semaphore, this function requests
/// the [SEMAPHORE_ALL_ACCESS] access right and the [lInitialCount] and [lMaximumCount] parameters are ignored.
///
/// Returns a handle to the semaphore object if the function succeeds. If the named semaphore object existed
/// before the function call, the function returns a handle to the existing object. If the function fails,
/// the return value is [NULL]. Use [GetLastError] to get extended error information.
///
/// Note: The name can have a "Global\\" or "Local\\" prefix to explicitly create the object in the global
/// or session namespace. The remainder of the name can contain any character except the backslash character (`\`).
/// For more information, see Kernel Object Namespaces.
@Native<HANDLE Function(IntPtr lpSecurityAttributes, LONG lInitialCount, LONG lMaximumCount, LPCWSTR lpName)>()
external int CreateSemaphoreW(int lpSecurityAttributes, int lInitialCount, int lMaximumCount, LPCWSTR lpName);

/// Waits until the specified object is in the signaled state or the time-out interval elapses.
///
/// [hHandle] is a handle to the object. This handle must have the SYNCHRONIZE access right.
/// For a list of the object types whose handles can be specified, see the following Remarks section.
/// If this handle is closed while the wait is still pending, the function's behavior is undefined.
///
/// [dwMilliseconds] specifies the time-out interval, in milliseconds. If a nonzero value is specified,
/// the function waits until the object is signaled or the interval elapses. If [dwMilliseconds] is zero,
/// the function does not enter a wait state if the object is not signaled; it always returns immediately.
/// If [dwMilliseconds] is [INFINITE], the function will return only when the object is signaled.
///
/// Returns [WAIT_FAILED] on failure, [WAIT_OBJECT_0] if the specified object is in the signaled state,
/// [WAIT_TIMEOUT] if the time-out interval elapses, and [WAIT_ABANDONED] if the specified object is a mutex
/// that was not released by the thread that owned the mutex before the owning thread terminated.
/// Use [GetLastError] to get extended error information if [WAIT_FAILED] is returned.
@Native<Uint32 Function(HANDLE hHandle, DWORD dwMilliseconds)>()
external int WaitForSingleObject(int hHandle, int dwMilliseconds);

/// Releases the specified semaphore by increasing its count by [lReleaseCount].
///
/// [hSemaphore] is a handle to the semaphore object. This handle is obtained
/// through the CreateSemaphore or OpenSemaphore function and must have the
/// SEMAPHORE_MODIFY_STATE access right. For more information, see
/// Synchronization Object Security and Access Rights documentation.
///
/// [lReleaseCount] is the amount by which the semaphore object's current count
/// is to be increased. The value must be greater than zero. If the specified
/// amount would cause the semaphore's count to exceed the maximum count that
/// was specified when the semaphore was created, the count is not changed and
/// the function returns [FALSE].
///
/// [lpPreviousCount] is a pointer to a variable to receive the previous count
/// for the semaphore. This parameter can be [NULL] if the previous count is not
/// required.
///
/// Returns a nonzero value if the function succeeds, or zero if the function
/// fails. To get extended error information, call [GetLastError].
@Native<BOOL Function(HANDLE hSemaphore, LONG lReleaseCount, Pointer<LONG> lpPreviousCount)>()
external int ReleaseSemaphore(int hSemaphore, int lReleaseCount, Pointer<LONG> lpPreviousCount);

/// Closes an open object handle.
///
/// [hObject] is a valid handle to an open object. This handle must have been obtained through
/// a call to functions that return handles, such as [CreateSemaphoreW]
///
/// Returns a nonzero value if the function succeeds, indicating that the handle has been closed.
///
/// Returns zero if the function fails. To get extended error information, call [GetLastError].
///
/// If the application is running under a debugger, the function will throw an exception if it
/// receives either a handle value that is not valid or a pseudo-handle value. This can occur if
/// a handle is closed twice.
///
/// It is important to close handles when they are no longer needed to avoid resource leaks.
@Native<BOOL Function(HANDLE hObject)>()
external int CloseHandle(int hObject);

/// Retrieves the calling thread's last-error code value. The last-error
/// code is maintained on a per-thread basis. Multiple threads do not
/// overwrite each other's last-error code.
///
/// ```c
/// DWORD GetLastError();
/// ```
/// {@category kernel32}
int GetLastError() => _GetLastError();

final _GetLastError =
    DynamicLibrary.open('kernel32.dll').lookupFunction<Uint32 Function(), int Function()>('GetLastError');

// @Native<Uint32 Function()>()
// external int GetLastError();

class WindowsCreateSemaphoreWMacros {
  static Pointer<Never> NULL = Pointer.fromAddress(0);

  static Pointer<Never> SEM_FAILED = NULL;

  /// ERROR_INVALID_NAME: The specified name is invalid. It is either too long or contains invalid characters.
  /// When naming semaphore objects, certain characters are considered invalid
  /// and cannot be used. The name must not include any of the following characters:
  /// - `<` (less than)
  /// - `>` (greater than)
  /// - `:` (colon)
  /// - `"` (double quote)
  /// - `/` (forward slash)
  /// - `\` (backslash)
  /// - `|` (pipe)
  /// - `?` (question mark)
  /// - `*` (asterisk)
  ///
  /// Additionally, names cannot contain characters with ASCII codes less than 32,
  /// which includes control characters such as newline (`\n`), carriage return (`\r`),
  /// tab (`\t`), etc.
  static const int ERROR_INVALID_NAME = 123;

  static const int ERROR_SUCCESS = 0;

  // ERROR_ACCESS_DENIED: The caller does not have the required access rights to create or open the semaphore object.
  static const int ERROR_ACCESS_DENIED = 5;

  // ERROR_INVALID_HANDLE: An invalid handle was specified.
  static const int ERROR_INVALID_HANDLE = 6;

  // ERROR_INVALID_PARAMETER: One of the parameters was invalid.
  static const int ERROR_INVALID_PARAMETER = 87;

  // ERROR_TOO_MANY_POSTS: The semaphore cannot be set to the specified count because it would exceed the semaphore's maximum count.
  static const int ERROR_TOO_MANY_POSTS = 298;

  // ERROR_SEM_NOT_FOUND: The specified semaphore does not exist.
  static const int ERROR_SEM_NOT_FOUND = 187;

  // ERROR_SEM_IS_SET: The semaphore is already set, and cannot be set again.
  static const int ERROR_SEM_IS_SET = 102;

  static int INITIAL_VALUE_RECOMMENDED = 1;

  static int MAXIMUM_VALUE_RECOMMENDED = 1;

  static String GLOBAL_NAME_PREFIX = 'Global\\';

  static String LOCAL_NAME_PREFIX = 'Local\\';

  // Maximum length of a path for a named semaphore, in some cases on windows 10 it can be up to 32,767
  static int MAX_PATH = 260 - min(GLOBAL_NAME_PREFIX.length, LOCAL_NAME_PREFIX.length);
}

class WindowsCreateSemaphoreWError extends Error {
  final int code;
  final String message;
  final String? identifier;
  late final String? description = toString();

  WindowsCreateSemaphoreWError(this.code, this.message, this.identifier);

  @override
  String toString() => 'WindowsCreateSemaphoreWMacros: [Error: $identifier Code: $code]: $message';

  static WindowsCreateSemaphoreWError fromErrorCode(int code) {
    if (code == WindowsCreateSemaphoreWMacros.ERROR_ACCESS_DENIED)
      return WindowsCreateSemaphoreWError(
          code,
          "The caller does not have the required access rights to create or open the semaphore object.",
          'ERROR_ACCESS_DENIED');

    if (code == WindowsCreateSemaphoreWMacros.ERROR_INVALID_HANDLE)
      return WindowsCreateSemaphoreWError(code, "An invalid handle was specified.", 'ERROR_INVALID_HANDLE');

    if (code == WindowsCreateSemaphoreWMacros.ERROR_INVALID_PARAMETER)
      return WindowsCreateSemaphoreWError(code, "One of the parameters was invalid.", 'ERROR_INVALID_PARAMETER');

    if (code == WindowsCreateSemaphoreWMacros.ERROR_TOO_MANY_POSTS)
      return WindowsCreateSemaphoreWError(
          code,
          "The semaphore cannot be set to the specified count because it would exceed the semaphore's maximum count.",
          'ERROR_TOO_MANY_POSTS');

    if (code == WindowsCreateSemaphoreWMacros.ERROR_SEM_NOT_FOUND)
      return WindowsCreateSemaphoreWError(code, "The specified semaphore does not exist.", 'ERROR_SEM_NOT_FOUND');

    if (code == WindowsCreateSemaphoreWMacros.ERROR_SEM_IS_SET)
      return WindowsCreateSemaphoreWError(
          code, "The semaphore is already set, and cannot be set again.", 'ERROR_SEM_IS_SET');

    if (code == WindowsCreateSemaphoreWMacros.ERROR_INVALID_NAME)
      return WindowsCreateSemaphoreWError(code,
          "The specified name is invalid. It is either too long or contains invalid characters.", 'ERROR_INVALID_NAME');

    if (code == WindowsCreateSemaphoreWMacros.ERROR_SUCCESS)
      return WindowsCreateSemaphoreWError(
          code, "The operation completed successfully and there is no 'last error'.", 'ERROR_SUCCESS');

    // Default case if none of the specific error codes match
    return WindowsCreateSemaphoreWError(code, "Unknown error.", 'UNKNOWN');
  }
}

class WindowsWaitForSingleObjectMacros {
  static const int TIMEOUT_RECOMMENDED = TIMEOUT_INFINITE;

  /// Return only when the object is signaled.
  static const int TIMEOUT_INFINITE = 0xFFFFFFFF;

  /// Return immediately if the object is not signaled.
  static const int TIMEOUT_ZERO = 0;

  // The specified object is a mutex object that was not released by the thread that owned the mutex object before
  // the owning thread terminated. Ownership of the mutex object is granted to the calling thread and the
  // mutex state is set to nonsignaled. If the mutex was protecting persistent state information,
  // you should check it for consistency.
  static const int WAIT_ABANDONED = 0x00000080;

  // The state of the specified object is signaled.
  static const int WAIT_OBJECT_0 = 0x00000000;

  // The time-out interval elapsed, and the object's state is nonsignaled.
  static const int WAIT_TIMEOUT = 0x00000102;

  // The function has failed. To get extended error information, call GetLastError. (DWORD)0xFFFFFFFF
  static const int WAIT_FAILED = 0xFFFFFFFF;
}

class WindowsReleaseSemaphoreMacros {
  static const int RELEASE_COUNT_RECOMMENDED = 1;

  static late Pointer<Never> PREVIOUS_RELEASE_COUNT_RECOMMENDED = NULL;

  static Pointer<Never> NULL = Pointer.fromAddress(0);
}
