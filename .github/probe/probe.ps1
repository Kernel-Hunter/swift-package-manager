Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class Probe {
  [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
  public struct SHFILEINFOW { public IntPtr hIcon; public int iIcon; public uint dwAttributes;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)] public string szDisplayName;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 80)] public string szTypeName; }
  [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
  public static extern IntPtr SHGetFileInfoW(string pszPath, uint attr, IntPtr psfi, uint cb, uint flags);
  public static long ExeType(string p) { return SHGetFileInfoW(p, 0, IntPtr.Zero, 0, 0x2000).ToInt64() & 0xFFFF; }
}
"@
[byte[]]$tiny = 0x4d,0x5a,0x00,0x00,0x50,0x45,0x00,0x00,0x4c,0x01,0x01,0x00,0x6a,0x2a,0x58,0xc3,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x04,0x00,0x03,0x01,0x0b,0x01,0x08,0x00,0x04,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x04,0x00,0x00,0x00,0x0c,0x00,0x00,0x00,0x04,0x00,0x00,0x00,0x0c,0x00,0x00,0x00,0x00,0x00,0x40,0x00,0x04,0x00,0x00,0x00,0x04,0x00,0x00,0x00,0x04,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x04,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x68,0x00,0x00,0x00,0x64,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x02
$d = Join-Path $env:RUNNER_TEMP probe; New-Item -ItemType Directory $d | Out-Null
[IO.File]::WriteAllBytes("$d\tiny-noext", $tiny)
[IO.File]::WriteAllBytes("$d\tiny.exe", $tiny)
$padded = New-Object byte[] 1024; [Array]::Copy($tiny, $padded, $tiny.Length)
[IO.File]::WriteAllBytes("$d\tiny-padded", $padded)
[IO.File]::WriteAllBytes("$d\tiny-padded.exe", $padded)
Copy-Item C:\Windows\System32\where.exe "$d\where-noext"
Copy-Item C:\Windows\System32\where.exe "$d\where-copy.exe"
Set-Content "$d\text" "best"
New-Item -ItemType SymbolicLink -Path "$d\where-sym" -Target "$d\where-noext" | Out-Null
New-Item -ItemType SymbolicLink -Path "$d\tiny-sym" -Target "$d\tiny-noext" | Out-Null
New-Item -ItemType SymbolicLink -Path "$d\tiny-sym.exe" -Target "$d\tiny.exe" | Out-Null
New-Item -ItemType SymbolicLink -Path "$d\tiny-sym-noext" -Target "$d\tiny.exe" | Out-Null
foreach ($f in Get-ChildItem $d) { "{0,-18} size={1,-7} SHGFI_EXETYPE=0x{2:X}" -f $f.Name, $f.Length, [Probe]::ExeType($f.FullName) }
"where.exe size: " + (Get-Item C:\Windows\System32\where.exe).Length
