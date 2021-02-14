#!/usr/bin/bash
#

clear_vendor_checksums() {
	sed -i 's/\("files":{\)[^}]*/\1/' vendor/$1/.cargo-checksum.json
}

main() {
	local CWD="$PWD"
	local STUFF="$CWD/stuff"
	local BUILD="$CWD/build"
	local RUSTVER="1.50.0"
	local ATAROOT="$1"

	ATAROOT="$(realpath $ATAROOT)"

	if [ -z "$ATAROOT" ]; then
		echo "Ataraxia Linux directory is not set or not found"
		exit 1
	fi

	for i in amd64 x86 arm64 armv7l mips64 mips64el mipsel mips; do
		if [ ! -f "$ATAROOT/OUT.${i}/.toolchain_stamp" ]; then
			echo "Toolchain for $i is not found"
			exit 1
		fi
	done

	rm -rf "$BUILD"
	mkdir -p "$BUILD"

	cd "$BUILD"
	curl -C - -L -O https://static.rust-lang.org/dist/rustc-$RUSTVER-src.tar.gz
	bsdtar -xvf rustc-$RUSTVER-src.tar.gz

	cd rustc-$RUSTVER-src
	patch -Np1 -i "$STUFF"/rust/0001-LLVM-clang-build.patch
	patch -Np1 -i "$STUFF"/rust/0002-linux-musl-disable-crt-static.patch
	patch -Np1 -i "$STUFF"/rust/0003-mips-and-mipsel-disable-soft-float-for-musl-libc.patch
	patch -Np1 -i "$STUFF"/rust/0004-openssl-src-add-more-linux-musl-targets.patch

	clear_vendor_checksums openssl-src

	cat >> config.toml <<-EOF
		[llvm]
		optimize = true
		release-debuginfo = false
		assertions = false
		static-libstdcpp = true
		ninja = true
		targets = "AArch64;ARM;Mips;X86"
		experimental-targets = ""

		[build]
		host = [
			"x86_64-unknown-linux-musl",
			"i686-unknown-linux-musl",
			"aarch64-unknown-linux-musl",
			"armv7-unknown-linux-musleabihf",
			"mips64-unknown-linux-muslabi64",
			"mips64el-unknown-linux-muslabi64",
			"mips-unknown-linux-musl",
			"mipsel-unknown-linux-musl"
		]
		cargo-native-static = true
		compiler-docs  = false
		docs = false
		extended = true
		full-bootstrap = false
		locked-deps = true
		profiler = false
		python = "$(which python3)"
		rustc = "$(which rustc)"
		rustfmt = "$(which rustfmt)"
		cargo = "$(which cargo)"
		sanitizers = false
		submodules = false
		vendor = true

		[rust]
		backtrace = false
		channel = "stable"
		codegen-tests = false
		codegen-units = 1
		debug = false
		debug-assertions = false
		debuginfo-level = 0
		jemalloc = false
		llvm-libunwind = "system"
		rpath = true

		[target.x86_64-unknown-linux-musl]
		cc = "$ATAROOT/OUT.amd64/tools/bin/x86_64-linux-musl-clang"
		cxx = "$ATAROOT/OUT.amd64/tools/bin/x86_64-linux-musl-clang++"
		linker = "$ATAROOT/OUT.amd64/tools/bin/x86_64-linux-musl-clang"
		musl-root = "$ATAROOT/OUT.amd64/rootfs/usr"
		crt-static = false

		[target.i686-unknown-linux-musl]
		cc = "$ATAROOT/OUT.x86/tools/bin/i386-linux-musl-clang"
		cxx = "$ATAROOT/OUT.x86/tools/bin/i386-linux-musl-clang++"
		linker = "$ATAROOT/OUT.x86/tools/bin/i386-linux-musl-clang"
		musl-root = "$ATAROOT/OUT.x86/rootfs/usr"
		crt-static = false

		[target.aarch64-unknown-linux-musl]
		cc = "$ATAROOT/OUT.arm64/tools/bin/aarch64-linux-musl-clang"
		cxx = "$ATAROOT/OUT.arm64/tools/bin/aarch64-linux-musl-clang++"
		linker = "$ATAROOT/OUT.arm64/tools/bin/aarch64-linux-musl-clang"
		musl-root = "$ATAROOT/OUT.arm64/rootfs/usr"
		crt-static = false

		[target.armv7-unknown-linux-musleabihf]
		cc = "$ATAROOT/OUT.armv7l/tools/bin/armv7l-linux-musleabihf-clang"
		cxx = "$ATAROOT/OUT.armv7l/tools/bin/armv7l-linux-musleabihf-clang++"
		linker = "$ATAROOT/OUT.armv7l/tools/bin/armv7l-linux-musleabihf-clang"
		musl-root = "$ATAROOT/OUT.armv7l/rootfs/usr"
		crt-static = false

		[target.mips64-unknown-linux-muslabi64]
		cc = "$ATAROOT/OUT.mips64/tools/bin/mips64-linux-musl-clang"
		cxx = "$ATAROOT/OUT.mips64/tools/bin/mips64-linux-musl-clang++"
		linker = "$ATAROOT/OUT.mips64/tools/bin/mips64-linux-musl-clang"
		musl-root = "$ATAROOT/OUT.mips64/rootfs/usr"
		crt-static = false

		[target.mips64el-unknown-linux-muslabi64]
		cc = "$ATAROOT/OUT.mips64el/tools/bin/mips64el-linux-musl-clang"
		cxx = "$ATAROOT/OUT.mips64el/tools/bin/mips64el-linux-musl-clang++"
		linker = "$ATAROOT/OUT.mips64el/tools/bin/mips64el-linux-musl-clang"
		musl-root = "$ATAROOT/OUT.mips64el/rootfs/usr"
		crt-static = false

		[target.mips-unknown-linux-musl]
		cc = "$ATAROOT/OUT.mips/tools/bin/mips-linux-musl-clang"
		cxx = "$ATAROOT/OUT.mips/tools/bin/mips-linux-musl-clang++"
		linker = "$ATAROOT/OUT.mips/tools/bin/mips-linux-musl-clang"
		musl-root = "$ATAROOT/OUT.mips/rootfs/usr"
		crt-static = false

		[target.mipsel-unknown-linux-musl]
		cc = "$ATAROOT/OUT.mipsel/tools/bin/mipsel-linux-musl-clang"
		cxx = "$ATAROOT/OUT.mipsel/tools/bin/mipsel-linux-musl-clang++"
		linker = "$ATAROOT/OUT.mipsel/tools/bin/mipsel-linux-musl-clang"
		musl-root = "$ATAROOT/OUT.mipsel/rootfs/usr"
		crt-static = false
	EOF
}

main "$@"

exit 0

