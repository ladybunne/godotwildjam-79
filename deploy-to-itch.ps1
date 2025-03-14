cd Export\
del build-html5.zip
del build-windows.zip
del build-linux.zip
7z a -tzip build-html5.zip html5\*
7z a -tzip build-windows.zip windows\*
7z a -tzip build-linux.zip linux\*
butler push build-html5.zip ladybunne/godotwildjam-79:html5
butler push build-windows.zip ladybunne/godotwildjam-79:windows
butler push build-linux.zip ladybunne/godotwildjam-79:linux
Read-Host -Prompt "Should be done. Hit any key to close this prompt."