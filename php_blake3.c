#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "php.h"
#include "php_ini.h"
#include "ext/standard/info.h"
#include "php_blake3.h"

/* 包含官方BLAKE3 C实现 */
#include "src/blake3/blake3.h"

/* BLAKE3输出长度固定为32字节 */
#define BLAKE3_OUT_LEN 32

/* blake3_hash函数的参数信息 */
ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(arginfo_blake3_hash, 0, 1, IS_STRING, 0)
    ZEND_ARG_TYPE_INFO(0, data, IS_STRING, 0)
    ZEND_ARG_TYPE_INFO(0, raw_output, _IS_BOOL, 0)
ZEND_END_ARG_INFO()

/* 模块函数表 */
const zend_function_entry blake3_functions[] = {
    PHP_FE(blake3_hash, arginfo_blake3_hash)
    PHP_FE_END
};

/* 模块入口定义 */
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

/* 将二进制数据转换为小写十六进制字符串 */
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

/* BLAKE3哈希函数实现 */
PHP_FUNCTION(blake3_hash)
{
    char *data;
    size_t data_len;
    zend_bool raw_output = 0; /* 默认返回hex字符串 */
    
    /* 解析函数参数 */
    if (zend_parse_parameters(ZEND_NUM_ARGS(), "s|b", &data, &data_len, &raw_output) == FAILURE) {
        RETURN_FALSE;
    }
    
    /* 分配输出缓冲区 */
    unsigned char output[BLAKE3_OUT_LEN];
    
    /* 调用BLAKE3官方C实现进行哈希计算 */
    blake3_hasher hasher;
    blake3_hasher_init(&hasher);
    blake3_hasher_update(&hasher, data, data_len);
    blake3_hasher_finalize(&hasher, output, BLAKE3_OUT_LEN);
    
    /* 根据raw_output参数返回相应格式 */
    if (raw_output) {
        /* 返回原始32字节二进制数据 */
        RETURN_STRINGL((char *)output, BLAKE3_OUT_LEN);
    } else {
        /* 返回小写十六进制字符串（64个字符 + 终止符） */
        char hex_output[BLAKE3_OUT_LEN * 2 + 1];
        php_blake3_bin2hex(output, BLAKE3_OUT_LEN, hex_output);
        RETURN_STRING(hex_output);
    }
}

/* 模块初始化 */
PHP_MINIT_FUNCTION(blake3)
{
    return SUCCESS;
}

/* 模块关闭 */
PHP_MSHUTDOWN_FUNCTION(blake3)
{
    return SUCCESS;
}

/* 模块信息 */
PHP_MINFO_FUNCTION(blake3)
{
    php_info_print_table_start();
    php_info_print_table_header(2, "BLAKE3 support", "enabled");
    php_info_print_table_row(2, "Extension Version", PHP_BLAKE3_VERSION);
    php_info_print_table_row(2, "BLAKE3 Implementation", "Official C implementation");
    php_info_print_table_row(2, "BLAKE3 Version", "1.8.2 (commit: df610ddc)");
    php_info_print_table_row(2, "Output Length", "32 bytes (fixed)");
    php_info_print_table_end();
} 