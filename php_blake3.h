#ifndef PHP_BLAKE3_H
#define PHP_BLAKE3_H

extern zend_module_entry blake3_module_entry;
#define phpext_blake3_ptr &blake3_module_entry

#define PHP_BLAKE3_VERSION "1.0.0"

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

/* 声明BLAKE3哈希函数 */
PHP_FUNCTION(blake3_hash);

/* 模块入口点声明 */
PHP_MINIT_FUNCTION(blake3);
PHP_MSHUTDOWN_FUNCTION(blake3);
PHP_MINFO_FUNCTION(blake3);

#endif /* PHP_BLAKE3_H */ 