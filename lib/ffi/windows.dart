import 'dart:ffi' show Int32, IntPtr, Native, Pointer, Struct, Uint16, Uint32, Uint8;
import 'dart:io';
import 'package:ffi/ffi.dart' show Utf16;

typedef HANDLE = IntPtr;
typedef LONG = Int32;
typedef BOOL = Uint32;
typedef DWORD = Uint32;
typedef LPCWSTR = Pointer<Utf16>;
final Pointer<Never> NULL = Pointer.fromAddress(0);

/// Return only when the object is signaled.
const INFINITE = 0xFFFFFFFF;
final WAIT_ABANDONED = 0x00000080;
final WAIT_OBJECT_0 = 0x00000000;
final WAIT_TIMEOUT = 0x00000102;

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

// Path length
const MAX_PATH = 260;

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

@Native<Uint32 Function(HANDLE hHandle, DWORD dwMilliseconds)>()
external int WaitForSingleObject(int hHandle, int dwMilliseconds);

@Native<BOOL Function(HANDLE hSemaphore, LONG lReleaseCount, Pointer<LONG> lpPreviousCount)>()
external int ReleaseSemaphore(int hSemaphore, int lReleaseCount, Pointer<LONG> lpPreviousCount);

@Native<BOOL Function(HANDLE hObject)>()
external int CloseHandle(int hObject);

@Native<Uint32 Function()>()
external int GetLastError();

class WindowsCreateSemaphoreWMacros {
  static int INITIAL_VALUE_RECOMMENDED = 1;
  static int MAXIMUM_VALUE_RECOMMENDED = 1;
}
