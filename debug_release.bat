del /S /Q ..\web_export\Keshiki\*
..\GodotSteam-451.exe --headless --quit --export-debug Web ..\web_export\Keshiki\index.html
powershell Compress-Archive ..\web_export\Keshiki\ ..\web_export\Keshiki\index.zip
..\butler push ..\web_export\Keshiki\index.zip kevinhobbs/keshiki:debug
set /p "done=Finished uploading"