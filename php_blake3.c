#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "php.h"
#include "php_ini.h"
#include "ext/standard/info.h"
#include "zend_exceptions.h"
#include "php_blake3.h"

/* Include official BLAKE3 C implementation */
#include "src/blake3/blake3.h"

/* BLAKE3 output length limits */
#define BLAKE3_MIN_OUT_LEN 1
#define BLAKE3_MAX_OUT_LEN 65536  /* 64KB should be large enough */

/* Argument information for blake3_hash function */
ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(arginfo_blake3_hash, 0, 1, IS_STRING, 0)
	ZEND_ARG_TYPE_INFO(0, data, IS_STRING, 0)
	ZEND_ARG_TYPE_INFO(0, output_size, IS_LONG, 1)
	ZEND_ARG_TYPE_INFO(0, key, IS_STRING, 1)
	ZEND_ARG_TYPE_INFO(0, raw_output, _IS_BOOL, 1)
ZEND_END_ARG_INFO()

/* Module function table */
const zend_function_entry blake3_functions[] = {
	PHP_FE(blake3_hash, arginfo_blake3_hash)
	PHP_FE_END
};

/* Module entry definition */
zend_module_entry blake3_module_entry = {
	STANDARD_MODULE_HEADER,
	"blake3",
	blake3_functions,
	PHP_MINIT(blake3),
	PHP_MSHUTDOWN(blake3),
	NULL,
	NULL,
	PHP_MINFO(blake3),
	PHP_BLAKE3_VERSION,
	STANDARD_MODULE_PROPERTIES
};

#ifdef COMPILE_DL_BLAKE3
#ifdef ZTS
ZEND_TSRMLS_CACHE_DEFINE()
#endif
ZEND_GET_MODULE(blake3)
#endif

/* Convert binary data to lowercase hexadecimal string */
static void php_blake3_bin2hex(unsigned char *bin, size_t bin_len, char *hex)
{
	static const char hexits[17] = "0123456789abcdef";
	size_t i;
	
	for (i = 0; i < bin_len; i++) {
		hex[i * 2] = hexits[bin[i] >> 4];
		hex[i * 2 + 1] = hexits[bin[i] & 0x0F];
	}
	hex[bin_len * 2] = '\0';
}

/* BLAKE3 hash function implementation */
PHP_FUNCTION(blake3_hash)
{
	char *data;
	size_t data_len;
	zend_long output_size = BLAKE3_OUT_LEN; /* Default 32 bytes */
	char *key = NULL;
	size_t key_len = 0;
	zend_bool raw_output = 0; /* Default return hex string */
	
	/* Parse function parameters: data required, others optional */
	if (zend_parse_parameters(ZEND_NUM_ARGS(), "s|lsb", &data, &data_len, &output_size, &key, &key_len, &raw_output) == FAILURE) {
		RETURN_FALSE;
	}
	
	/* Validate output length parameter */
	if (output_size < BLAKE3_MIN_OUT_LEN || output_size > BLAKE3_MAX_OUT_LEN) {
		zend_throw_exception_ex(NULL, 0, "Output size must be between %d and %d bytes", BLAKE3_MIN_OUT_LEN, BLAKE3_MAX_OUT_LEN);
		RETURN_FALSE;
	}
	
	/* Validate key length (if key is provided) */
	if (key != NULL && key_len != 0 && key_len != BLAKE3_KEY_LEN) {
		zend_throw_exception_ex(NULL, 0, "Key must be exactly %d bytes long", BLAKE3_KEY_LEN);
		RETURN_FALSE;
	}
	
	/* Dynamically allocate output buffer */
	unsigned char *output = emalloc(output_size);
	if (!output) {
		zend_throw_exception(NULL, "Memory allocation failed", 0);
		RETURN_FALSE;
	}
	
	/* Initialize BLAKE3 hasher */
	blake3_hasher hasher;
	if (key != NULL && key_len == BLAKE3_KEY_LEN) {
		/* Initialize with key (keyed hash) */
		blake3_hasher_init_keyed(&hasher, (const uint8_t *)key);
	} else {
		/* Regular hash initialization */
		blake3_hasher_init(&hasher);
	}
	
	/* Update hasher and compute final hash value */
	blake3_hasher_update(&hasher, data, data_len);
	blake3_hasher_finalize(&hasher, output, output_size);
	
	/* Return appropriate format based on raw_output parameter */
	if (raw_output) {
		/* Return raw binary data */
		zend_string *result = zend_string_init((char *)output, output_size, 0);
		efree(output);
		RETURN_STR(result);
	} else {
		/* Return lowercase hexadecimal string */
		char *hex_output = emalloc(output_size * 2 + 1);
		if (!hex_output) {
			efree(output);
			zend_throw_exception(NULL, "Memory allocation failed", 0);
			RETURN_FALSE;
		}
		
		php_blake3_bin2hex(output, output_size, hex_output);
		zend_string *result = zend_string_init(hex_output, output_size * 2, 0);
		
		efree(output);
		efree(hex_output);
		RETURN_STR(result);
	}
}

/* Module initialization */
PHP_MINIT_FUNCTION(blake3)
{
	return SUCCESS;
}

/* Module shutdown */
PHP_MSHUTDOWN_FUNCTION(blake3)
{
	return SUCCESS;
}

/* Module information */
PHP_MINFO_FUNCTION(blake3)
{
	php_info_print_table_start();
	php_info_print_table_header(2, "BLAKE3 support", "enabled");
	php_info_print_table_row(2, "Author", "ExinOne Team");
	php_info_print_table_row(2, "Extension Version", PHP_BLAKE3_VERSION);
	php_info_print_table_row(2, "BLAKE3 Implementation", "Official C implementation");
	php_info_print_table_row(2, "BLAKE3 Version", "1.8.2 (commit: df610ddc)");
	php_info_print_table_row(2, "Variable Output Length", "1-65536 bytes");
	php_info_print_table_row(2, "Keyed Hash Support", "Yes (32-byte keys)");
	php_info_print_table_row(2, "Output Formats", "Hex string, Raw binary");
	php_info_print_table_end();
} 