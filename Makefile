
springinstaller.exe: springinstaller.nsi plugins/*.dll
	makensis -V3 springinstaller.nsi

test: springinstaller.exe
	cp springinstaller.exe test.exe
	echo "SPRING:https://github.com/abma/springinstaller/raw/master/springinstaller.ini" >>test.exe
	wine test.exe

release: springinstaller.exe
	mkdir -p springinstaller
	cp springinstaller.exe springinstaller
	rm -f springinstaller.7z
	7z a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on springinstaller.7z springinstaller

clean:
	rm -f springinstaller.exe
