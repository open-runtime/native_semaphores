import 'dart:ffi' show Int32, IntPtr, Native, Pointer, Uint32;
import 'package:ffi/ffi.dart' show Utf16;

typedef HANDLE = IntPtr;
typedef LONG = Int32;
typedef BOOL = Uint32;
typedef DWORD = Uint32;

@Native<HANDLE Function(IntPtr lpSecurityAttributes, LONG lInitialCount, LONG lMaximumCount, Pointer<Utf16> lpName)>()
external int CreateSemaphoreW(int lpSecurityAttributes, int lInitialCount, int lMaximumCount, Pointer<Utf16> lpName);

@Native<Uint32 Function(HANDLE hHandle, DWORD dwMilliseconds)>()
external int WaitForSingleObject(int hHandle, int dwMilliseconds);

@Native<BOOL Function(HANDLE hSemaphore, LONG lReleaseCount, Pointer<LONG> lpPreviousCount)>()
external int ReleaseSemaphore(int hSemaphore, int lReleaseCount, Pointer<LONG> lpPreviousCount);

@Native<BOOL Function(HANDLE hObject)>()
external int CloseHandle(int hObject);

@Native<Uint32 Function()>()
external int GetLastError();
