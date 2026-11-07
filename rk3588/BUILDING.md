# Building

The release binary is built natively on an RK3588 inside an Ubuntu 22.04 arm64 environment with clang 17.

1. Get the source of the release: `git clone -b v<version> https://github.com/Matheus290/ARMSX2-RK3588` (or the source archive attached to the release).
2. Build the dependencies (SDL3 and the rest) into a prefix with the upstream script: `.github/workflows/scripts/linux/build-dependencies-runner.sh` (packages it needs are listed in `.github/workflows/linux_build_sdl.yml`).
3. Configure and build:

```sh
cmake -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
  -DCMAKE_PREFIX_PATH=/path/to/deps \
  -DCMAKE_C_COMPILER=clang-17 -DCMAKE_CXX_COMPILER=clang++-17 \
  -DCMAKE_EXE_LINKER_FLAGS_INIT=-fuse-ld=lld-17 \
  -DENABLE_QT_UI=OFF -DENABLE_SDL_FRONTEND=ON -DENABLE_GSRUNNER=OFF \
  -DENABLE_TESTS=OFF -DUSE_BACKTRACE=OFF \
  -DX11_API=OFF -DWAYLAND_API=ON -DENABLE_SETCAP=OFF \
  -DHOST_PAGE_SIZE=4096 -DHOST_CACHE_LINE_SIZE=64 \
  -DARMSX2_VERSION=rk3588-<version>
ninja -C build pcsx2-sdl
```

The binary is `build/bin/armsx2-sdl`, with its `resources` folder next to it. `patches.zip` (widescreen and other game patches) comes from the official ARMSX2 release.

**Profile-guided optimization (optional).** Release builds also pass `-DCMAKE_CXX_FLAGS="-fprofile-use=<file>.profdata -Wno-profile-instr-unprofiled -Wno-profile-instr-out-of-date"`. To record your own profile:

1. Build once with `-DCMAKE_CXX_FLAGS=-fprofile-generate`.
2. Play a few games with `LLVM_PROFILE_FILE=/some/dir/%p.profraw` set.
3. Merge the results: `llvm-profdata-17 merge -o armsx2.profdata /some/dir/*.profraw`.

Without a profile, the build works the same, just a few percent slower.
