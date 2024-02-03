git status --porcelain |findstr . && echo Commit your changes before releasing && exit /B
grep 'config/version' project.godot
set /p "id=Enter version number: "
sed -i -b -E 's/config\/version=.+$/config\/version="%id%"/' project.godot
git add project.godot
git commit -m "Releasing %id%"
git push
del /S /Q ..\web_export\Keshiki\*
..\GodotSteam-451.exe --headless --quit --export Web ..\web_export\Keshiki\index.html
powershell Compress-Archive ..\web_export\Keshiki\ ..\web_export\Keshiki\index.zip
..\butler push ..\web_export\Keshiki\index.zip kevinhobbs/keshiki:web --userversion %id%

del /S /Q ..\web_export\Keshiki\*
..\GodotSteam-451.exe --headless --quit --export Windows ..\web_export\Keshiki\Keshiki.exe
powershell Compress-Archive ..\web_export\Keshiki\ ..\web_export\Keshiki\Keshiki.zip
..\butler push ..\web_export\Keshiki\Keshiki.zip kevinhobbs/keshiki:windows --userversion %id%

git tag %id% head
git push
set /p "done=Finished uploading"