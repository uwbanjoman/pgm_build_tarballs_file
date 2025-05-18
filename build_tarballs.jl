# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libpower_grid_model_c"
version = v"1.10.108"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/PowerGridModel/power-grid-model/releases/download/v$(version)/power_grid_model-$(version).tar.gz", "e7ca831fa3e13a2ad9a0d6a1e4b167dd711ab93aec55d98729be6c5b9312a7c6"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
cd power_grid_model-1.10.108/power_grid_model_c
apk del cmake
wget https://github.com/Kitware/CMake/releases/download/v3.31.2/cmake-3.31.2-linux-x86_64.sh
                                        chmod +x cmake-3.31.2-linux-x86_64.sh
                                        ./cmake-3.31.2-linux-x86_64.sh --prefix=/usr/local --exclude-subdir
                                        export PATH=/usr/local/cmake/bin:$PATH
export LD_LIBRARY_PATH="${PWD}/destdir/lib:${LD_LIBRARY_PATH}"
cmake -B build -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_CXX_STANDARD=20 -DCMAKE_CXX_FLAGS="$CXXFLAGS" -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel ${nproc}
cmake --install build
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
             Platform("x86_64", "linux"; libc = "glibc", cpu_target="x86_64_v3", cxxstring_abi=:cxx11),
             #Platform("x86_64", "windows"; cpu_target="x86_64_v3", cxxstring_abi=:cxx11, march="avx2"),
             #Platform("x86_64", "windows"; cpu_target="znver2", cxxstring_abi=:cxx11, march="avx2"),
             Platform("x86_64", "windows"; cpu_target="znver3", cxxstring_abi=:cxx11, march="avx2"),
             #Platform("x86_64", "linux"; libc="glibc", cpu_target="znver2", cxxstring_abi=:cxx11, march="avx2"),
             #Platform("x86_64", "linux"; libc="glibc", cpu_target="znver3", cxxstring_abi=:cxx20, march="avx2"),
             #Platform("x86_64", "windows"; cpu_target="x86_64_v4", cxxstring_abi=:cxx11, march="avx2"),       
             #Platform("x86_64", "windows"; cpu_target="x86_64_v4", cxxstring_abi=:cxx11, march="avx512"),
             #Platform("x86_64", "linux"; libc = "glibc", cpu_target="x86_64_v3", cxxstring_abi=:cxx11),
             #Platform("aarch64", "macos"; cpu_target="apple_m2") # fatal error: 'concepts' file not found (/include/power_grid_model/auxiliary/dataset_fwd.hpp:9:10: fatal error: 'concepts' file not found)
             #Platform("riscv64", "linux"; cpu_target="rv64gc") #, mabi=ip64d) # complaint about no-boost implementation
            ]
platforms = expand_cxxstring_abis(platforms)
#platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
            LibraryProduct("libpower_grid_model_c", :libpower_grid_model_c)
           ]

# Dependencies that must be installed before this package can be built
dependencies = [
                Dependency(PackageSpec(name="boost_jll", uuid="28df3c45-c428-5900-9ff8-a3135698ca75"))
                Dependency(PackageSpec(name="Eigen_jll", uuid="bc6bbf8a-a594-5541-9c57-10b0d0312c70"))
                Dependency(PackageSpec(name="nlohmann_json_jll", uuid="7c7c7bd4-5f1c-5db3-8b3f-fcf8282f06da"))
                Dependency(PackageSpec(name="msgpack_cxx_jll", uuid="b129c591-c9d9-59ef-8959-ff59aa278493"))
                Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
               ]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"13.2.0")

# julia +1.7 build_tarballs.jl --deploy-jll="local"
# julia +1.7 build_tarballs.jl --deploy="uwbanjoman/libpower_grid_model_c_jll.jl" # the github 'user/repository' names
