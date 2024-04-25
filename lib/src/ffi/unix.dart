import 'dart:ffi'
    show
        Abi,
        AbiSpecificInteger,
        AbiSpecificIntegerMapping,
        Char,
        Int,
        Native,
        Pointer,
        Uint16,
        Uint32,
        Uint64,
        Uint8,
        UnsignedInt,
        UnsignedLong,
        UnsignedShort,
        VarArgs;
import 'dart:io' show Platform;

// in C the sizeof(sem_t) = 4 bytes on MacOS Arm64 and x86_64 and on Linux it seems to be the same case!
typedef sem_t = Int;

/// Data Type: [mode_t] is typically defined as an unsigned integer type.
/// The exact size can vary between systems, but it is commonly 16 bits wide
/// on many UNIX and UNIX-like systems. Usage: It specifies file permissions
/// and type when creating new files or directories
/// (for example, with the open or mkdir system calls) and also
/// when changing permissions (with chmod or fchmod).
/// Size of [mode_t]: 2 bytes on MacOS Arm64 and x86_64

/// [mode_t] is often a 16-bit unsigned integer (uint16_t), but this can vary.
/// Dart FFI provides several integer types, such as [Uint8], [Uint16], [Uint32], and [Uint64],
/// to match the native types used by the C language.
/// Given the commonality of [mode_t] being a 16-bit value, you would likely use [Uint16] in Dart FFI,
/// but you should verify this against the documentation or header
/// files of the system you're working on. If you're interfacing with functions
/// that require [mode_t], you would declare them in Dart using [Uint16] for those parameters.

/// On [x86_64], [mode_t] is a [UnsignedShort] and on [arm64], [mode_t] is an [UnsignedLong]
/// mode_t
@AbiSpecificIntegerMapping({
  Abi.macosArm64: Uint64(),
  Abi.macosX64: Uint16(),
  Abi.linuxX64: Uint16(),
  Abi.linuxIA32: Uint16(),
})
final class mode_t extends AbiSpecificInteger {
  const mode_t();
}

class MODE_T_PERMISSIONS {
  static int x = 1;
  static int w = 2;
  static int r = 4;
  static int rw = r | w;
  static int rx = r | x;
  static int wx = w | x;
  static int rwx = r | w | x;

  static int perm({int u = 0, int g = 0, int o = 0, int user = 0, int group = 0, int others = 0}) =>
      ((u | user) << 6) | ((g | group) << 3) | (o | others);

  // Most common for named semaphores
  static int RECOMMENDED = MODE_T_PERMISSIONS.OWNER_READ_WRITE_GROUP_READ;

  // 0644 - Owner can read and write; the group can read; others can read.
  // static int OWNER_READ_WRITE_GROUP_READ = toOctal(0, 6, 4, 4);
  static int OWNER_READ_WRITE_GROUP_READ = perm(u: rw, g: r, o: r);

  // 0666 - Owner can read and write; the group can read and write; others can read and write.
  // static int OWNER_READ_WRITE_GROUP_READ_WRITE = toOctal(0, 6, 6, 6);
  static int OWNER_READ_WRITE_GROUP_AND_OTHERS_READ_WRITE = perm(u: rw, g: rw, o: rw);

  // 0600 - Owner can read and write; the group cannot access; others cannot access.
  // static int OWNER_READ_WRITE_GROUP_NO_ACCESS = toOctal(0, 6, 0, 0);
  static int OWNER_READ_WRITE_GROUP_NO_ACCESS = perm(u: rw, g: 0, o: 0);

  // 0700 - Owner can read, write, and execute; the group cannot access; others cannot access.
  // static int OWNER_READ_WRITE_EXECUTE_GROUP_NO_ACCESS = toOctal(0, 7, 0, 0);
  static int OWNER_READ_WRITE_EXECUTE_GROUP_NO_ACCESS = perm(u: rwx, g: 0, o: 0);

  // 0755 - Owner can read, write, and execute; the group can read and execute; others can read and execute.
  // static int OWNER_READ_WRITE_EXECUTE_GROUP_AND_OTHERS_READ_EXECUTE = toOctal(0, 7, 5, 5);
  static int OWNER_READ_WRITE_EXECUTE_GROUP_AND_OTHERS_READ_EXECUTE = perm(u: rwx, g: rx, o: rx);

  // 0777 - Owner can read, write, and execute; the group can read, write, and execute; others can read, write, and execute.
  // static int ALL_READ_WRITE_EXECUTE = toOctal(0, 7, 7, 7);
  static int ALL_READ_WRITE_EXECUTE = perm(u: rwx, g: rwx, o: rwx);
}

/// [sem_open] creates a new POSIX semaphore or opens an existing
/// semaphore.  The semaphore is identified by [name].  For details of
/// the construction of [name], see sem_overview(7).

/// The [oflag] argument specifies flags that control the operation of
/// the call.  (Definitions of the flags values can be obtained by
/// including <fcntl.h>.)  If [O_CREAT] is specified in [oflag], then the
/// semaphore is created if it does not already exist.  The owner
/// (user ID) of the semaphore is set to the effective user ID of the
/// calling process.  The group ownership (group ID) is set to the
/// effective group ID of the calling process.  If both [O_CREAT] and
/// [O_EXCL] are specified in [oflag], then an error is returned if a
/// semaphore with the given name already exists.

/// If [O_CREAT] is specified in [oflag], then two additional arguments
/// must be supplied.  The mode argument specifies the permissions to
/// be placed on the new semaphore, as for open(2).  (Symbolic
/// definitions for the permissions bits can be obtained by including
/// <sys/stat.h>.) The permissions settings are masked against the
/// process umask. Both read and write permission should be granted
/// to each class of user that will access the semaphore. The value
/// argument specifies the initial value for the new semaphore.  If
/// [O_CREAT] is specified, and a semaphore with the given name already
/// exists, then [mode_t] and [value] are ignored.

/// When [value] is greater than 0: It indicates the number of times processes
/// or threads can successfully [sem_wait] (decrement) the semaphore without blocking.
/// For example, if [value] is set to 3, up to three processes or threads can decrement
/// the semaphore without being blocked, effectively allowing simultaneous access to a
/// resource that can support that many concurrent accesses.
///
/// When [value] is 0: It means that the semaphore is initially "locked" or unavailable.
/// Any process or thread that tries to decrement the semaphore with [sem_wait] will block
/// until another process or thread increments the semaphore with [sem_post], making
/// the resource available.
@Native<Pointer<sem_t> Function(Pointer<Char>, Int, VarArgs<(mode_t, UnsignedInt)>)>()
external Pointer<sem_t> sem_open(Pointer<Char> name, int oflag, int mode, int value);

/// [sem_wait] Decrements (locks) the semaphore pointed to by sem.
/// If the semaphore's value is greater than zero, then the decrement
/// proceeds, and the function returns, immediately.  If the
/// semaphore currently has the value zero, then the call blocks
/// until either it becomes possible to perform the decrement (i.e.,
/// the semaphore value rises above zero), or a signal handler
/// interrupts the call.
///
/// The [sem_wait] function shall lock the semaphore referenced by sem by
/// performing a semaphore lock operation on that semaphore. If the semaphore
/// value is currently [zero], then the calling thread shall not return from the
/// call to [sem_wait] until it either locks the semaphore or the call is
/// interrupted by a signal. Upon successful return, the state of the semaphore
/// shall be locked and shall remain locked until the [sem_post] function is
/// executed and returns successfully. The [sem_wait] function is interruptible
/// by the delivery of a signal.
@Native<Int Function(Pointer<sem_t> sem_t)>()
external int sem_wait(Pointer<sem_t> sem_t);

/// [sem_trywait] is the same as [sem_wait], except that if the
/// decrement cannot be immediately performed, the call returns an
/// error ([errno] set to [EAGAIN]) instead of blocking.
///
/// The [sem_trywait] function shall lock the semaphore referenced by
/// sem only if the semaphore is currently not locked; that is, if the
/// semaphore value is currently positive. Otherwise,
/// it shall not lock the semaphore.
@Native<Int Function(Pointer<sem_t>)>()
external int sem_trywait(Pointer<sem_t> sem_t);

/// [sem_post] function shall unlock the semaphore referenced by sem by
/// performing a semaphore unlock operation on that semaphore.
/// If the semaphore value resulting from this operation is positive,
/// then no threads were blocked waiting for the semaphore to become unlocked;
/// the semaphore value is simply incremented.
///
/// If the value of the semaphore resulting from this operation is zero,
/// then one of the threads blocked waiting for the semaphore shall be
/// allowed to return successfully from its call to [sem_wait].
///
/// [sem_post] increments (unlocks) the semaphore pointed to by sem.  If the semaphore's value
/// consequently becomes greater than zero, then  another  process  or  thread  blocked  in  a
/// [sem_wait] call will be woken up and proceed to lock the semaphore.
///
/// [sem_post]  returns  0 on success; on error, the value of the semaphore is left unchanged,
/// -1 is returned, and [errno] is set to indicate the error.
@Native<Int Function(Pointer<sem_t>)>()
external int sem_post(Pointer<sem_t> sem_t);

/// [sem_close] closes the named semaphore referred to by sem,
/// allowing any resources that the system has allocated to the
/// calling process for this semaphore to be freed.

/// On success [sem_close] returns 0; on error, -1 is returned, with
/// [errno] set to indicate the error.
@Native<Int Function(Pointer<sem_t>)>()
external int sem_close(Pointer<sem_t> sem_t);

/// [sem_unlink] removes the named semaphore referred to by name.
///  The semaphore name is removed immediately.  The semaphore is
///  destroyed once all other processes that have the semaphore open
///  close it.
///  On  success  [sem_unlink]  returns 0; on error, -1 is returned,
///  with [errno] set to indicate the error.
@Native<Int Function(Pointer<Char>)>()
external int sem_unlink(Pointer<Char> name);

/// The <errno.h> header file defines the integer variable errno,
/// which is set by system calls and some library functions in the
/// event of an error to indicate what went wrong.
///
/// The value in errno is significant only when the return value of
/// the call indicated an error (i.e., -1 from most system calls; -1
/// or NULL from most library functions); a function that succeeds is
/// allowed to change [errno].  The value of errno is never set to zero
/// by any system call or library function.
@Native<Pointer<Int> Function()>()
external Pointer<Int> __error();

@Native<Pointer<Int> Function()>()
external Pointer<Int> __errno_location();

Pointer<Int> Function() _errno = () => Platform.isMacOS ? __error() : __errno_location();

Pointer<Int> get errno => _errno();

class UnixSemLimits {
  static bool isBSD = Platform.isMacOS;

  // Uint8
  // Size in bytes for a path (including null terminator): 1025
  static int PATH_MAX = 1024;

  // SEM_VALUE_MAX is of length 32767 on MacOS Arm64 and x86_64
  // Size of SEM_VALUE_MAX is 4 bytes on MacOS Arm64 and x86_64
  static int SEM_VALUE_MAX = 32767;

  // Size of NAME_MAX (size of an int): 4 bytes on MacOS Arm64 and x86_64
  static int NAME_MAX = 255;

  static int NAME_MAX_CHARACTERS = 30;
}

class UnixSemOpenMacros {
  // https://man7.org/linux/man-pages/man3/sem_open.3.html
  // https://pubs.opengroup.org/onlinepubs/009695399/functions/sem_open.html

  // MacOS will be BSD and Linux will be GNU
  static bool isBSD = Platform.isMacOS;

  // The semaphore exists, but the caller does not have permission to open it.
  // The named semaphore exists and the permissions specified by oflag are denied, or the named semaphore does not exist and permission to create the named semaphore is denied.
  static int EACCES = isBSD ? 13 : 13;

  // The sem_open() operation was interrupted by a signal.
  static int EINTR = isBSD ? 4 : 4;

  // Both O_CREAT and O_EXCL were specified in oflag, but a semaphore with this name already exists.
  // O_CREAT and O_EXCL are set and the named semaphore already exists.
  static int EEXIST = isBSD ? 17 : 17;

  /// [value] was greater than [SEM_VALUE_MAX].
  /// [name] consists of just "/", followed by no other characters.
  /// The [sem_open] operation is not supported for the given [name],
  /// or [O_CREAT] was specified in [oflag] and value was greater than [SEM_VALUE_MAX].
  static int EINVAL = isBSD ? 22 : 22;

  // The per-process limit on the number of open file descriptors has been reached.
  // You can check this by running `ulimit -Sn`
  // Too many semaphore descriptors or file descriptors are currently in use by this process.
  static int EMFILE = isBSD ? 24 : 24;

  /// [name] was too long.
  /// The length of the name argument exceeds [PATH_MAX]
  /// or a pathname component is longer than [NAME_MAX].
  static int ENAMETOOLONG = isBSD ? 63 : 36;

  // The system-wide limit on the total number of open files has been reached.
  // Too many semaphores are currently open in the system.
  static int ENFILE = isBSD ? 23 : 23;

  /// The [O_CREAT] flag was not specified in [oflag] and no semaphore with this [name] exists;
  /// or, [O_CREAT] was specified, but [name] wasn't well formed.
  /// [O_CREAT] is not set and the named semaphore does not exist.
  static int ENOENT = isBSD ? 2 : 2;

  // Insufficient memory.
  static int ENOMEM = isBSD ? 12 : 12;

  // There is insufficient space for the creation of the new named semaphore.
  static int ENOSPC = isBSD ? 28 : 28;

  // "Invalid memory address encountered. Please ensure all pointers and addresses are correctly set and accessible."
  static int EFAULT = isBSD ? 14 : 14;

  // Upon successful completion, the [sem_open] function shall return the address of the semaphore. Otherwise, it shall return a value of SEM_FAILED and set errno to indicate the error. The symbol SEM_FAILED is defined in the <semaphore.h> header. No successful return from sem_open() shall return the value SEM_FAILED.
  /// [SEM_FAILED] = 0xffffffffffffffff (as a pointer), 18446744073709551615 (as an unsigned integer)
  /// Size of SEM_FAILED (size of a pointer): 8 bytes on MacOS Arm64 and MacOS x86_64
  static Pointer<Uint64> SEM_FAILED =
      Platform.isMacOS ? Pointer.fromAddress(0xffffffffffffffff) : Pointer.fromAddress(0x0);

  /// This flag is used to create a semaphore if it does not already exist. If [O_CREAT] is set and the semaphore
  /// already exists, then [O_CREAT] has no effect, except as noted under [O_EXCL]. Otherwise, [sem_open] creates
  /// a named semaphore. The [O_CREAT] flag requires a third and a fourth argument: [mode], which is of type [mode_t],
  /// and [value], which is of type unsigned. The semaphore is created with an initial value of [value]. Valid initial
  /// values for semaphores are less than or equal to [SEM_VALUE_MAX]. The user ID of the semaphore is set to the
  /// effective user ID of the process; the group ID of the semaphore is set to a system default group ID or to the
  /// effective group ID of the process. The permission bits of the semaphore are set to the value of the [mode]
  /// argument except those set in the file mode creation mask of the process. When bits in [mode] other than the file
  /// permission bits are specified, the effect is unspecified. After the semaphore named [name] has been created by
  /// [sem_open] with the [O_CREAT] flag, other processes can connect to the semaphore by calling [sem_open]
  /// with the same value of [name].
  /// Size of the flags (size of an int): 4 bytes on MacOS Arm64 and MacOS x86_64
  static int O_CREAT = isBSD ? 512 : 64;

  /// If [O_EXCL] and [O_CREAT] are set, [sem_open] fails if the semaphore name exists. The check for the existence
  /// of the semaphore and the creation of the semaphore if it does not exist are atomic with respect to other processes
  /// executing [sem_open] with [O_EXCL] and [O_CREAT] set. If [O_EXCL] is set and [O_CREAT] is not set, the effect
  /// is undefined. If flags other than [O_CREAT] and [O_EXCL] are specified in the [oflag] parameter,
  /// the effect is unspecified.
  /// Size of the flags (size of an int): 4 bytes on MacOS Arm64 and MacOS x86_64
  ///
  static int _O_EXCL = isBSD ? 2048 : 128;

  /// O_EXCL can only be used along side O_CREAT otherwise it has no effect and will likely throw an error
  static int O_EXCL = O_CREAT | _O_EXCL;

  static int VALUE_RECOMMENDED = 1;
}

class UnixSemError extends Error {
  final bool critical;
  final int code;
  final String message;
  final String? identifier;
  late final String? description = toString();

  UnixSemError(this.code, this.message, this.identifier, [this.critical = true]);

  @override
  String toString() => 'UnixSemError: [Critical: $critical Error: $identifier Code: $code]: $message';
}

class UnixSemOpenError extends UnixSemError {
  UnixSemOpenError(code, message, identifier, [bool critical = true]) : super(code, message, identifier, critical);

  @override
  String toString() => 'UnixSemOpenError: [Error: $identifier Code: $code]: $message';

  static UnixSemOpenError fromErrno(int errno) {
    if (errno == UnixSemOpenMacros.EACCES)
      return UnixSemOpenError(
          errno, "The semaphore exists, but the caller does not have permission to open it.", 'EACCES');
    if (errno == UnixSemOpenMacros.EINTR)
      return UnixSemOpenError(errno, "The sem_open() operation was interrupted by a signal.", 'EINTR');
    if (errno == UnixSemOpenMacros.EEXIST)
      return UnixSemOpenError(errno,
          "Both O_CREAT and O_EXCL were specified in oflag, but a semaphore with this name already exists.", 'EEXIST');
    if (errno == UnixSemOpenMacros.EINVAL)
      return UnixSemOpenError(
          errno,
          "Invalid argument. The name was just '/' or the value was greater than SEM_VALUE_MAX, or the operation is not supported for the given name.",
          'EINVAL');
    if (errno == UnixSemOpenMacros.EMFILE)
      return UnixSemOpenError(
          errno, "The per-process limit on the number of open file descriptors has been reached.", 'EMFILE');
    if (errno == UnixSemOpenMacros.ENAMETOOLONG)
      return UnixSemOpenError(
          errno,
          "The name was too long, or a pathname component is longer than NAME_MAX i.e. 30 character dart String including the leading slash.",
          'ENAMETOOLONG');
    if (errno == UnixSemOpenMacros.ENFILE)
      return UnixSemOpenError(
          errno, "The system-wide limit on the total number of open files has been reached.", 'ENFILE');
    if (errno == UnixSemOpenMacros.ENOENT)
      return UnixSemOpenError(errno, "No semaphore with this name exists; or, name wasn't well formed.", 'ENOENT');
    if (errno == UnixSemOpenMacros.ENOMEM) return UnixSemOpenError(errno, "Insufficient memory.", 'ENOMEM');
    if (errno == UnixSemOpenMacros.ENOSPC)
      return UnixSemOpenError(
          errno, "There is insufficient space for the creation of the new named semaphore.", 'ENOSPC');
    if (errno == UnixSemOpenMacros.EFAULT)
      return UnixSemOpenError(
          errno,
          "Invalid memory address encountered. Please ensure all pointers and addresses are correctly set and accessible.",
          'EFAULT');
    else
      return UnixSemOpenError(errno, "Unknown error.", 'UNKNOWN');
  }
}

class UnixSemWaitOrTryWaitMacros {
  // https://man7.org/linux/man-pages/man3/sem_wait.3.html
  // https://pubs.opengroup.org/onlinepubs/009695399/functions/sem_wait.html

  // MacOS will be BSD and Linux will be GNU
  static bool isBSD = Platform.isMacOS;

  /// The semaphore was already locked, so it cannot be
  /// immediately locked by the [sem_trywait]
  /// operation ( [sem_trywait] only).
  static int EAGAIN = isBSD ? 35 : 11;

  // A deadlock condition was detected.
  static int EDEADLK = isBSD ? 11 : 35;

  // A signal interrupted this function.
  // The call was interrupted by a signal handler;
  static int EINTR = isBSD ? 4 : 4;

  /// The [sem_t] argument does not refer to a valid semaphore.
  /// [sem_t] is not a valid semaphore.
  static int EINVAL = isBSD ? 22 : 22;
}

class UnixSemOpenErrorUnixSemWaitOrTryWaitError extends UnixSemError {
  UnixSemOpenErrorUnixSemWaitOrTryWaitError(code, message, identifier, [critical = true])
      : super(code, message, identifier, critical);

  @override
  String toString() => 'UnixSemOpenErrorSemWaitOrTryWaitError: [Error: $identifier Code: $code]: $message';

  static UnixSemOpenErrorUnixSemWaitOrTryWaitError fromErrno(int errno) {
    if (errno == UnixSemWaitOrTryWaitMacros.EAGAIN)
      return UnixSemOpenErrorUnixSemWaitOrTryWaitError(
          errno,
          "The semaphore was already locked, so it cannot be immediately locked by the sem_trywait operation.",
          'EAGAIN');
    if (errno == UnixSemWaitOrTryWaitMacros.EDEADLK)
      return UnixSemOpenErrorUnixSemWaitOrTryWaitError(errno, "A deadlock condition was detected.", 'EDEADLK');
    if (errno == UnixSemWaitOrTryWaitMacros.EINTR)
      return UnixSemOpenErrorUnixSemWaitOrTryWaitError(errno, "A signal interrupted this function.", 'EINTR');
    if (errno == UnixSemWaitOrTryWaitMacros.EINVAL)
      return UnixSemOpenErrorUnixSemWaitOrTryWaitError(
          errno, "The sem_t argument does not refer to a valid semaphore.", 'EINVAL');
    else
      return UnixSemOpenErrorUnixSemWaitOrTryWaitError(errno, "Unknown error.", 'UNKNOWN');
  }
}

class UnixSemCloseMacros {
  static bool isBSD = Platform.isMacOS;

  /// [sem_t] is not a valid semaphore.
  static int EINVAL = isBSD ? 22 : 22;
}

class UnixSemCloseError extends UnixSemError {
  UnixSemCloseError(code, message, identifier, [critical = true]) : super(code, message, identifier, critical);

  @override
  String toString() => 'UnixSemCloseError: [Error: $identifier Code: $code]: $message';

  static UnixSemCloseError fromErrno(int errno) {
    if (errno == UnixSemCloseMacros.EINVAL)
      return UnixSemCloseError(errno, "sem_t is not a valid semaphore.", 'EINVAL');
    else
      return UnixSemCloseError(errno, "Unknown error.", 'UNKNOWN');
  }
}

class UnixSemUnlinkMacros {
  static bool isBSD = Platform.isMacOS;

  /// The named semaphore referred to by [name] does not exist.
  static int ENOENT = isBSD ? 2 : 2;

  /// The named semaphore referred to by [name] exists, but the caller does not have permission to unlink it.
  /// Permission is denied to unlink the named semaphore.
  static int EACCES = isBSD ? 13 : 13;

  /// [name] was too long.
  /// The length of the [name] argument exceeds [PATH_MAX] or a pathname component is longer than [NAME_MAX]
  static int ENAMETOOLONG = isBSD ? 63 : 36;
}

class UnixSemUnlinkError extends UnixSemError {
  UnixSemUnlinkError(code, message, identifier, [critical = true]) : super(code, message, identifier, critical);

  @override
  String toString() => 'UnixSemUnlinkError: [Error: $identifier Code: $code]: $message';

  static UnixSemUnlinkError fromErrno(int errno) {
    if (errno == UnixSemUnlinkMacros.ENOENT)
      return UnixSemUnlinkError(errno, "The named semaphore referred to by name does not exist.", 'ENOENT', false);
    if (errno == UnixSemUnlinkMacros.EACCES)
      return UnixSemUnlinkError(
          errno,
          "The named semaphore referred to by name exists, but the caller does not have permission to unlink it.",
          'EACCES');
    if (errno == UnixSemUnlinkMacros.ENAMETOOLONG)
      return UnixSemUnlinkError(
          errno,
          "The name was too long, or a pathname component is longer than NAME_MAX i.e. 30 character dart String including the leading slash.",
          'ENAMETOOLONG');
    else
      return UnixSemUnlinkError(errno, "Unknown error.", 'UNKNOWN');
  }
}

class UnixSemUnlockWithPostMacros {
  static bool isBSD = Platform.isMacOS;

  /// The semaphore referred to by [sem] is not a valid semaphore.
  static int EINVAL = isBSD ? 22 : 22;

  //  The maximum allowable value for a semaphore would be exceeded.
  static int EOVERFLOW = isBSD ? 84 : 75;
}

class UnixSemUnlockWithPostError extends UnixSemError {
  UnixSemUnlockWithPostError(code, message, identifier, [critical = true]) : super(code, message, identifier, critical);

  @override
  String toString() => 'UnixSemPostError: [Error: $identifier Code: $code]: $message';

  static UnixSemUnlockWithPostError fromErrno(int errno) {
    if (errno == UnixSemUnlockWithPostMacros.EINVAL)
      return UnixSemUnlockWithPostError(
          errno, "The semaphore referred to by sem is not a valid semaphore.", 'EINVAL  ');
    if (errno == UnixSemUnlockWithPostMacros.EOVERFLOW)
      return UnixSemUnlockWithPostError(
          errno, "The maximum allowable value for a semaphore would be exceeded.", 'EOVERFLOW');
    else
      return UnixSemUnlockWithPostError(errno, "Unknown error.", 'UNKNOWN');
  }
}
