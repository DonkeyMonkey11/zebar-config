Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "pwsh.exe -WindowStyle Hidden -NonInteractive -ExecutionPolicy Bypass -File """ & WScript.Arguments(0) & """", 0, False
