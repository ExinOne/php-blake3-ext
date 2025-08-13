PHP_ARG_ENABLE(blake3, whether to enable blake3,
[  --enable-blake3           Enable blake3], no)

if test "$PHP_BLAKE3" != "no"; then
  AC_DEFINE(HAVE_BLAKE3, 1, [Whether you have BLAKE3])
  
  # Base source files (required for all architectures)
  BLAKE3_SOURCES="php_blake3.c src/blake3/blake3.c src/blake3/blake3_dispatch.c src/blake3/blake3_portable.c"
  
  # Detect CPU architecture and add corresponding optimized implementations safely
  case "$host_cpu" in
    x86_64|i*86)
      AC_MSG_RESULT([Detected x86/x86_64 architecture. Probing SIMD flags...])
      SIMD_CFLAGS=""
      HAVE_SSE2=no
      HAVE_SSSE3=no
      HAVE_SSE41=no
      HAVE_AVX2=no
      HAVE_BMI2=no
      HAVE_AVX512F=no
      HAVE_AVX512VL=no
      HAVE_AVX512BW=no

      dnl Use ax_check_compile_flag (available via phpize build helpers)
      AX_CHECK_COMPILE_FLAG([-msse2],   [HAVE_SSE2=yes;   SIMD_CFLAGS="$SIMD_CFLAGS -msse2"]) 
      AX_CHECK_COMPILE_FLAG([-mssse3],  [HAVE_SSSE3=yes;  SIMD_CFLAGS="$SIMD_CFLAGS -mssse3"]) 
      AX_CHECK_COMPILE_FLAG([-msse4.1], [HAVE_SSE41=yes;  SIMD_CFLAGS="$SIMD_CFLAGS -msse4.1"]) 
      AX_CHECK_COMPILE_FLAG([-mavx2],   [HAVE_AVX2=yes;   SIMD_CFLAGS="$SIMD_CFLAGS -mavx2"]) 
      AX_CHECK_COMPILE_FLAG([-mbmi2],   [HAVE_BMI2=yes;   SIMD_CFLAGS="$SIMD_CFLAGS -mbmi2"]) 
      AX_CHECK_COMPILE_FLAG([-mavx512f],[HAVE_AVX512F=yes;SIMD_CFLAGS="$SIMD_CFLAGS -mavx512f"]) 
      AX_CHECK_COMPILE_FLAG([-mavx512vl],[HAVE_AVX512VL=yes;SIMD_CFLAGS="$SIMD_CFLAGS -mavx512vl"]) 
      AX_CHECK_COMPILE_FLAG([-mavx512bw],[HAVE_AVX512BW=yes;SIMD_CFLAGS="$SIMD_CFLAGS -mavx512bw"]) 

      if test "x$HAVE_SSE2" = "xyes"; then
        BLAKE3_SOURCES="$BLAKE3_SOURCES src/blake3/blake3_sse2.c"
      else
        AC_MSG_RESULT([SSE2 not supported by compiler. Skipping blake3_sse2.c])
      fi

      if test "x$HAVE_SSSE3" = "xyes" && test "x$HAVE_SSE41" = "xyes"; then
        BLAKE3_SOURCES="$BLAKE3_SOURCES src/blake3/blake3_sse41.c"
      else
        AC_MSG_RESULT([SSSE3/SSE4.1 not fully supported. Skipping blake3_sse41.c])
      fi

      if test "x$HAVE_AVX2" = "xyes" && test "x$HAVE_BMI2" = "xyes"; then
        BLAKE3_SOURCES="$BLAKE3_SOURCES src/blake3/blake3_avx2.c"
      else
        AC_MSG_RESULT([AVX2/BMI2 not fully supported. Skipping blake3_avx2.c])
      fi

      if test "x$HAVE_AVX512F" = "xyes" && test "x$HAVE_AVX512VL" = "xyes" && test "x$HAVE_AVX512BW" = "xyes"; then
        BLAKE3_SOURCES="$BLAKE3_SOURCES src/blake3/blake3_avx512.c"
      else
        AC_MSG_RESULT([AVX512(F/VL/BW) not fully supported. Skipping blake3_avx512.c])
      fi

      if test -n "$SIMD_CFLAGS"; then
        AC_MSG_RESULT([Enabling SIMD CFLAGS: $SIMD_CFLAGS])
        CFLAGS="$CFLAGS $SIMD_CFLAGS"
      fi
      ;;

    aarch64|arm64)
      AC_MSG_RESULT([Detected ARM64 architecture. Enabling NEON implementation])
      BLAKE3_SOURCES="$BLAKE3_SOURCES src/blake3/blake3_neon.c"
      ;;

    arm*)
      AC_MSG_RESULT([Detected ARM (32-bit). Probing NEON support...])
      NEON_CFLAGS=""
      HAVE_NEON=no
      AX_CHECK_COMPILE_FLAG([-mfpu=neon],[HAVE_NEON=yes; NEON_CFLAGS="$NEON_CFLAGS -mfpu=neon"]) 
      if test "x$HAVE_NEON" = "xyes"; then
        BLAKE3_SOURCES="$BLAKE3_SOURCES src/blake3/blake3_neon.c"
        CFLAGS="$CFLAGS $NEON_CFLAGS"
      else
        AC_MSG_RESULT([NEON not supported by compiler. Using portable only])
      fi
      ;;

    *)
      AC_MSG_RESULT([Unknown architecture ($host_cpu), using portable implementation only])
      ;;
  esac
  
  PHP_NEW_EXTENSION(blake3, $BLAKE3_SOURCES, $ext_shared)
  PHP_ADD_INCLUDE([$ext_srcdir/src/blake3])
fi 