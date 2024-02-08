git status --porcelain |findstr . && echo Commit your changes before releasing && pause && exit /B
grep 'config/version' project.godot
set /p "id=Enter version number: "
sed -i -b -E 's/config\/version=.+$/config\/version="%id%"/' project.godot
git add project.godot
git commit -m "Releasing %id%"
git push
del /S /Q ..\web_export\Keshiki\*
..\GodotSteam-451.exe --headless --quit-after 120 --export-debug Web ..\web_export\Keshiki\index.html
powershell Compress-Archive ..\web_export\Keshiki\ ..\web_export\Keshiki\index.zip
..\butler push ..\web_export\Keshiki\index.zip kevinhobbs/keshiki:web --userversion %id%

git tag %id% head
git push


echo "All done"
pause