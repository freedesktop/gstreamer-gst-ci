[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;

git config --global user.email "gst-build@gstreamer.net"
git config --global user.name "Gstbuild Runner"

# Download gst-build and all its subprojects
git clone https://gitlab.freedesktop.org/gstreamer/gst-build.git C:\gst-build

# download the subprojects to try and cache them
meson subprojects download --sourcedir C:\gst-build

# Remove files that will conflict with a fresh clone on the runner side
Remove-Item -Force 'C:/gst-build/subprojects/*.wrap'
Remove-Item -Recurse -Force 'C:/gst-build/subprojects/win-nasm'
Remove-Item -Recurse -Force 'C:/gst-build/subprojects/win-flex-bison-binaries'

Move-Item C:\gst-build\subprojects C:\subprojects
Remove-Item -Recurse -Force C:\gst-build
