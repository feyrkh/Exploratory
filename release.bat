git status --porcelain |findstr . && echo Commit your changes before releasing && exit /B
grep 'config/version' project.godot
set /p "id=Enter version number: "
sed -i -b -E 's/config\/version=.+$/config\/version="%id%"/' project.godot
del /S /Q ..\web_export\Keshiki\*
..\GodotSteam-451.exe --headless --quit --export-debug Web ..\web_export\Keshiki\index.html
powershell Compress-Archive ..\web_export\Keshiki\ ..\web_export\Keshiki\index.zip
..\butler push ..\web_export\Keshiki\index.zip kevinhobbs/keshiki:web --userversion %id%

set /p "done=Finished uploading"