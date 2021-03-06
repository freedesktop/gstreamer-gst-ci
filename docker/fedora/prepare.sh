set -eux

dnf install -y git-core ninja-build dnf-plugins-core python3-pip

# Configure git for various usage
git config --global user.email "gst-build@gstreamer.net"
git config --global user.name "Gstbuild Runner"

# Add rpm fusion repositories in order to access all of the gst plugins
sudo dnf install -y \
  "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
  "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

dnf upgrade -y

# install rest of the extra deps
dnf install -y \
    aalib-devel \
    aom \
    bat \
    libaom \
    libaom-devel \
    libcaca-devel \
    libdav1d \
    libdav1d-devel \
    ccache \
    cmake \
    clang-devel \
    elfutils \
    elfutils-libs \
    elfutils-devel \
    gcc \
    gcc-c++ \
    gdb \
    git-lfs \
    glslc \
    gtk3 \
    gtk3-devel \
    graphene \
    graphene-devel \
    gsl \
    gsl-devel \
    faac-devel \
    ffmpeg \
    ffmpeg-libs \
    ffmpeg-devel \
    flex \
    flite \
    flite-devel \
    mono-devel \
    procps-ng \
    patch \
    redhat-rpm-config \
    intel-mediasdk-devel \
    json-glib \
    json-glib-devel \
    libnice \
    libnice-devel \
    libsodium-devel \
    libunwind \
    libunwind-devel \
    libyaml-devel \
    libxml2-devel \
    libxslt-devel \
    llvm-devel \
    log4c-devel \
    make \
    neon \
    neon-devel \
    nunit \
    npm \
    opencv \
    opencv-devel \
    openjpeg2 \
    openjpeg2-devel \
    SDL2 \
    SDL2-devel \
    sbc \
    sbc-devel \
    x264 \
    x264-libs \
    x264-devel \
    python3 \
    python3-devel \
    python3-libs \
    python3-gobject \
    python3-cairo \
    python3-cairo-devel \
    valgrind \
    vulkan \
    vulkan-devel \
    mesa-omx-drivers \
    mesa-libGL \
    mesa-libGL-devel \
    mesa-libGLU \
    mesa-libGLU-devel \
    mesa-libGLES \
    mesa-libGLES-devel \
    mesa-libOpenCL \
    mesa-libOpenCL-devel \
    mesa-libgbm \
    mesa-libgbm-devel \
    mesa-libd3d \
    mesa-libd3d-devel \
    mesa-libOSMesa \
    mesa-libOSMesa-devel \
    mesa-vulkan-drivers \
    wpewebkit \
    wpewebkit-devel \
    xorg-x11-server-utils \
    xorg-x11-server-Xvfb

# Install common debug symbols
dnf debuginfo-install -y gtk3 \
    glib2 \
    glibc \
    freetype \
    openjpeg \
    gobject-introspection \
    python3 \
    python3-libs \
    python3-gobject \
    libappstream-glib-devel \
    libjpeg-turbo \
    glib-networking \
    libcurl \
    libsoup \
    nasm \
    nss \
    nss-softokn \
    nss-softokn-freebl \
    nss-sysinit \
    nss-util \
    openssl \
    openssl-libs \
    openssl-pkcs11 \
    brotli \
    bzip2-libs \
    gpm-libs \
    harfbuzz \
    harfbuzz-icu \
    json-c \
    json-glib \
    libbabeltrace \
    libffi \
    libsrtp \
    libunwind \
    mpg123-libs \
    neon \
    orc-compiler \
    orc \
    pixman \
    pulseaudio-libs \
    pulseaudio-libs-glib2 \
    wavpack \
    webrtc-audio-processing \
    ffmpeg \
    ffmpeg-libs \
    faad2-libs \
    libavdevice \
    libmpeg2 \
    faac \
    fdk-aac \
    x264 \
    x264-libs \
    x265 \
    x265-libs \
    xz \
    xz-libs \
    zip \
    zlib

pip3 install meson==0.53.1 hotdoc

# Install the dependencies of gstreamer
dnf builddep -y gstreamer1 \
    gstreamer1-plugins-base \
    gstreamer1-plugins-good \
    gstreamer1-plugins-good-extras \
    gstreamer1-plugins-ugly \
    gstreamer1-plugins-ugly-free \
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

# Remove Qt5 devel packages as we haven't tested building it and
# it leads to build issues in examples.
dnf remove -y "qt5-qtbase-devel"

# FIXME: Why does installing directly with dnf doesn't actually install
# the documentation files?
dnf download glib2-doc gdk-pixbuf2-devel*x86_64* gtk3-devel-docs
rpm -i --reinstall *.rpm
rm -f *.rpm

# Install Rust
RUSTUP_VERSION=1.21.0
RUST_VERSION=1.40.0
RUST_ARCH="x86_64-unknown-linux-gnu"

dnf install -y wget
RUSTUP_URL=https://static.rust-lang.org/rustup/archive/$RUSTUP_VERSION/$RUST_ARCH/rustup-init
wget $RUSTUP_URL
dnf remove -y wget

chmod +x rustup-init;
./rustup-init -y --no-modify-path --profile minimal --default-toolchain $RUST_VERSION;
rm rustup-init;
chmod -R a+w $RUSTUP_HOME $CARGO_HOME

rustup --version
cargo --version
rustc --version

# get gst-build and make all subprojects available
git clone -b ${DEFAULT_BRANCH} https://gitlab.freedesktop.org/gstreamer/gst-build.git /gst-build/
cd /gst-build
meson subprojects download
