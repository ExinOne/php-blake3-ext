PHP_ARG_ENABLE(blake3, whether to enable blake3,
[  --enable-blake3           Enable blake3], no)

if test "$PHP_BLAKE3" != "no"; then
  AC_DEFINE(HAVE_BLAKE3, 1, [Whether you have BLAKE3])
  
  # Base source files (required for all architectures)
  BLAKE3_SOURCES="php_blake3.c src/blake3/blake3.c src/blake3/blake3_dispatch.c src/blake3/blake3_portable.c"
  
  # Detect CPU architecture and add corresponding optimized implementations
  case "$host_cpu" in
    x86_64|i*86)
      # x86/x86_64 architecture: add SSE and AVX optimizations
      BLAKE3_SOURCES="$BLAKE3_SOURCES src/blake3/blake3_sse2.c src/blake3/blake3_sse41.c src/blake3/blake3_avx2.c src/blake3/blake3_avx512.c"
      AC_MSG_RESULT([Detected x86/x86_64 architecture, enabling SSE/AVX optimizations])
      ;;
    aarch64|arm64)
      # ARM64 architecture: add NEON optimizations
      BLAKE3_SOURCES="$BLAKE3_SOURCES src/blake3/blake3_neon.c"
      AC_MSG_RESULT([Detected ARM64 architecture, enabling NEON optimizations])
      ;;
    arm*)
      # Other ARM architectures: check if NEON is supported
      BLAKE3_SOURCES="$BLAKE3_SOURCES src/blake3/blake3_neon.c"
      AC_MSG_RESULT([Detected ARM architecture, enabling NEON optimizations])
      ;;
    *)
      # Other architectures: use portable implementation only
      AC_MSG_RESULT([Unknown architecture ($host_cpu), using portable implementation only])
      ;;
  esac
  
  PHP_NEW_EXTENSION(blake3, $BLAKE3_SOURCES, $ext_shared)
  PHP_ADD_INCLUDE([$ext_srcdir/src/blake3])
fi 