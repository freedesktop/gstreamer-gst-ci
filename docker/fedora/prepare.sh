set -eu

dnf install -y git ninja-build dnf-plugins-core

# Configure git for various usage
git config --global user.email "gst-build@gstreamer.net"
git config --global user.name "Gstbuild Runner"

# Add rpm fusion repositories in order to access all of the gst plugins
dnf install -y "http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-29.noarch.rpm" \
  "http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-29.noarch.rpm"

rpm --import "/etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-nonfree-fedora-29"
rpm --import "/etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-free-fedora-29"
dnf upgrade -y

# Enable the cisco openh264 repo
dnf config-manager --set-enabled fedora-cisco-openh264

# install rest of the extra deps
dnf install -y ccache \
    cmake \
    elfutils \
    gcc \
    gcc-c++ \
    gdb \
    gtk3 \
    gtk3-devel \
    ffmpeg \
    ffmpeg-libs \
    ffmpeg-devel \
    procps-ng \
    patch \
    redhat-rpm-config \
    json-glib \
    json-glib-devel \
    libnice \
    libnice-devel \
    libunwind \
    libunwind-devel \
    opencv \
    opencv-devel \
    openjpeg2 \
    openjpeg2-devel \
    openh264 \
    openh264-devel \
    x264 \
    x264-libs \
    x264-devel \
    python3-gobject \
    python3-cairo \
    python3-cairo-devel \
    vulkan \
    vulkan-devel \
    xorg-x11-server-utils \
    xorg-x11-server-Xvfb

pip3 install meson
# Add the pip3 installation to the path
export PATH="$PATH:/usr/local/lib/python3.7/site-packages"

# Install the dependencies of gstreamer
dnf builddep -y gstreamer1 \
    gstreamer1-plugins-base \
    gstreamer1-plugins-good \
    gstreamer1-plugins-good-extras \
    gstreamer1-plugins-ugly \
    gstreamer1-plugins-ugly-free \
    gstreamer1-plugins-bad-nonfree \
    gstreamer1-plugins-bad-free \
    gstreamer1-plugins-bad-free-extras \
    gstreamer1-plugins-bad-freeworld \
    gstreamer1-libav \
    gstreamer1-rtsp-server  \
    gstreamer1-vaapi \
    python3-gstreamer1 \
    -x meson

# Remove gst-devel packages installed by builddep above
dnf remove -y "gstreamer1*devel"

# get gst-build and make all subprojects available
git clone git://anongit.freedesktop.org/gstreamer/gst-build /gst-build/
cd /gst-build && meson build/ && rm -rf build/