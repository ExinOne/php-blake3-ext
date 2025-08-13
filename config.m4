PHP_ARG_ENABLE(blake3, whether to enable blake3,
[  --enable-blake3           Enable blake3], no)

if test "$PHP_BLAKE3" != "no"; then
  AC_DEFINE(HAVE_BLAKE3, 1, [Whether you have BLAKE3])
  
  # Base source files (required for all architectures) - only these go in BLAKE3_SOURCES
  BLAKE3_SOURCES="php_blake3.c src/blake3/blake3.c src/blake3/blake3_dispatch.c src/blake3/blake3_portable.c"
  
  # Detect CPU architecture and test for SIMD support
  case "$host_cpu" in
    x86_64|i*86)
      AC_MSG_RESULT([Detected x86/x86_64 architecture, checking SIMD support])
      
      # Test for SSE2 support
      AC_MSG_CHECKING([if compiler supports SSE2])
      saved_CFLAGS="$CFLAGS"
      CFLAGS="$CFLAGS -msse2"
      AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
        #include <emmintrin.h>
      ]], [[
        __m128i x = _mm_setzero_si128();
        return 0;
      ]])], [
        AC_MSG_RESULT([yes])
        BLAKE3_SSE2_CFLAGS="-msse2"
        blake3_have_sse2=yes
      ], [
        AC_MSG_RESULT([no])
        AC_MSG_WARN([SSE2 not supported by compiler, skipping blake3_sse2.c])
        blake3_have_sse2=no
      ])
      CFLAGS="$saved_CFLAGS"
      
      # Test for SSE4.1 support  
      AC_MSG_CHECKING([if compiler supports SSE4.1])
      saved_CFLAGS="$CFLAGS"
      CFLAGS="$CFLAGS -msse4.1 -mssse3"
      AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
        #include <smmintrin.h>
      ]], [[
        __m128i x = _mm_setzero_si128();
        x = _mm_shuffle_epi8(x, x);
        return 0;
      ]])], [
        AC_MSG_RESULT([yes])
        BLAKE3_SSE41_CFLAGS="-msse4.1 -mssse3"
        blake3_have_sse41=yes
      ], [
        AC_MSG_RESULT([no])
        AC_MSG_WARN([SSE4.1 not supported by compiler, skipping blake3_sse41.c])
        blake3_have_sse41=no
      ])
      CFLAGS="$saved_CFLAGS"
      
      # Test for AVX2 support
      AC_MSG_CHECKING([if compiler supports AVX2])
      saved_CFLAGS="$CFLAGS"
      CFLAGS="$CFLAGS -mavx2"
      AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
        #include <immintrin.h>
      ]], [[
        __m256i x = _mm256_setzero_si256();
        return 0;
      ]])], [
        AC_MSG_RESULT([yes])
        BLAKE3_AVX2_CFLAGS="-mavx2"
        blake3_have_avx2=yes
      ], [
        AC_MSG_RESULT([no])
        AC_MSG_WARN([AVX2 not supported by compiler, skipping blake3_avx2.c])
        blake3_have_avx2=no
      ])
      CFLAGS="$saved_CFLAGS"
      
      # Test for AVX512 support
      AC_MSG_CHECKING([if compiler supports AVX512])
      saved_CFLAGS="$CFLAGS"
      CFLAGS="$CFLAGS -mavx512f -mavx512vl"
      AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
        #include <immintrin.h>
      ]], [[
        __m512i x = _mm512_setzero_si512();
        return 0;
      ]])], [
        AC_MSG_RESULT([yes])
        BLAKE3_AVX512_CFLAGS="-mavx512f -mavx512vl"
        blake3_have_avx512=yes
      ], [
        AC_MSG_RESULT([no])
        AC_MSG_WARN([AVX512 not supported by compiler, skipping blake3_avx512.c])
        blake3_have_avx512=no
      ])
      CFLAGS="$saved_CFLAGS"
      ;;
      
    aarch64|arm64)
      # ARM64 architecture: add NEON optimizations
      AC_MSG_CHECKING([if compiler supports NEON])
      AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
        #include <arm_neon.h>
      ]], [[
        uint32x4_t x = vdupq_n_u32(0);
        return 0;
      ]])], [
        AC_MSG_RESULT([yes])
        blake3_have_neon=yes
        AC_MSG_RESULT([Detected ARM64 architecture, NEON optimizations enabled])
      ], [
        AC_MSG_RESULT([no])
        AC_MSG_WARN([NEON not supported, using portable implementation only])
        blake3_have_neon=no
      ])
      ;;
      
    arm*)
      # Other ARM architectures: check if NEON is supported
      AC_MSG_CHECKING([if compiler supports NEON])
      saved_CFLAGS="$CFLAGS"
      CFLAGS="$CFLAGS -mfpu=neon"
      AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
        #include <arm_neon.h>
      ]], [[
        uint32x4_t x = vdupq_n_u32(0);
        return 0;
      ]])], [
        AC_MSG_RESULT([yes])
        BLAKE3_NEON_CFLAGS="-mfpu=neon"
        blake3_have_neon=yes
        AC_MSG_RESULT([Detected ARM architecture, NEON optimizations enabled])
      ], [
        AC_MSG_RESULT([no])
        AC_MSG_WARN([NEON not supported, using portable implementation only])
        blake3_have_neon=no
      ])
      CFLAGS="$saved_CFLAGS"
      ;;
      
    *)
      # Other architectures: use portable implementation only
      AC_MSG_RESULT([Unknown/unsupported architecture ($host_cpu), using portable implementation only])
      ;;
  esac
  
  # Create extension with base sources only
  PHP_NEW_EXTENSION(blake3, $BLAKE3_SOURCES, $ext_shared)
  PHP_ADD_INCLUDE([$ext_srcdir/src/blake3])
  
  # Add SIMD optimizations with specific compiler flags (these won't duplicate)
  if test "$blake3_have_sse2" = "yes"; then
    PHP_ADD_SOURCES_X(src/blake3, blake3_sse2.c, $BLAKE3_SSE2_CFLAGS, shared_objects_blake3)
  fi
  if test "$blake3_have_sse41" = "yes"; then
    PHP_ADD_SOURCES_X(src/blake3, blake3_sse41.c, $BLAKE3_SSE41_CFLAGS, shared_objects_blake3)
  fi
  if test "$blake3_have_avx2" = "yes"; then
    PHP_ADD_SOURCES_X(src/blake3, blake3_avx2.c, $BLAKE3_AVX2_CFLAGS, shared_objects_blake3)
  fi
  if test "$blake3_have_avx512" = "yes"; then
    PHP_ADD_SOURCES_X(src/blake3, blake3_avx512.c, $BLAKE3_AVX512_CFLAGS, shared_objects_blake3)
  fi
  if test "$blake3_have_neon" = "yes"; then
    PHP_ADD_SOURCES_X(src/blake3, blake3_neon.c, $BLAKE3_NEON_CFLAGS, shared_objects_blake3)
  fi
fi 