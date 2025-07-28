#ifndef PHP_BLAKE3_H
#define PHP_BLAKE3_H

extern zend_module_entry blake3_module_entry;
#define phpext_blake3_ptr &blake3_module_entry

#define PHP_BLAKE3_VERSION "2.0.0"

#ifdef PHP_WIN32
#   define PHP_BLAKE3_API __declspec(dllexport)
#elif defined(__GNUC__) && __GNUC__ >= 4
#   define PHP_BLAKE3_API __attribute__ ((visibility("default")))
#else
#   define PHP_BLAKE3_API
#endif

#ifdef ZTS
#include "TSRM.h"
#endif

/* Declaration of BLAKE3 hash function */
PHP_FUNCTION(blake3_hash);

/* Module entry point declarations */
PHP_MINIT_FUNCTION(blake3);
PHP_MSHUTDOWN_FUNCTION(blake3);
PHP_MINFO_FUNCTION(blake3);

#endif /* PHP_BLAKE3_H */ 