
springinstaller.exe: springinstaller.nsi plugins/*.dll include/*.nsh
	makensis -V3 -DVERSION=$(git describe) springinstaller.nsi

spring-setup.exe: springinstaller.exe
	cp springinstaller.exe spring-setup.exe
	echo "SPRING:https://github.com/spring/springinstaller/raw/master/repo/springinstaller.ini" >>spring-setup.exe

release: springinstaller.exe spring-setup.exe
	mkdir -p springinstaller
	cp springinstaller.exe springinstaller
	rm -f springinstaller.7z
	7z a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on springinstaller.7z springinstaller

clean:
	rm -f springinstaller.exe
