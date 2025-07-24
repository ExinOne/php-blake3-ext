PHP_ARG_ENABLE(blake3, whether to enable blake3,
[  --enable-blake3           Enable blake3], no)

if test "$PHP_BLAKE3" != "no"; then
  AC_DEFINE(HAVE_BLAKE3, 1, [Whether you have BLAKE3])
  
  PHP_NEW_EXTENSION(blake3, php_blake3.c \
    src/blake3/blake3.c \
    src/blake3/blake3_dispatch.c \
    src/blake3/blake3_portable.c \
    src/blake3/blake3_sse2.c \
    src/blake3/blake3_sse41.c \
    src/blake3/blake3_avx2.c \
    src/blake3/blake3_avx512.c \
    src/blake3/blake3_neon.c, $ext_shared)
    
  PHP_ADD_INCLUDE([$ext_srcdir/src/blake3])
fi 