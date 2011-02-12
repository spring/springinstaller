
springinstaller.exe: springinstaller.nsi plugins/*.dll
	makensis springinstaller.nsi

test: springinstaller.exe
	cp springinstaller.exe test.exe
	echo "SPRING:https://github.com/abma/springinstaller/raw/master/springinstaller.ini" >>test.exe
	wine test.exe
