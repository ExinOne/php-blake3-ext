# PHP BLAKE3 Extension

**Language**: **English** | [中文](README_cn.md)

A lightweight PHP extension providing support for the BLAKE3 cryptographic hash function.

## About BLAKE3

BLAKE3 is a fast, secure cryptographic hash function designed by the authors of BLAKE2. It offers better performance than SHA-2 while maintaining high security standards.

## Official Source Code Information

This extension uses the official BLAKE3 C implementation:

- **Upstream Repository**: https://github.com/BLAKE3-team/BLAKE3
- **Version**: 1.8.2
- **Fixed Commit**: `df610ddc3b93841ffc59a87e3da659a15910eb46`
- **Download Time**: Based on the above commit for fixed version

## Vendor Strategy

To ensure reproducible builds and security, this project adopts a vendor strategy:

- Uses a fixed official commit to avoid upstream changes
- All source files come directly from the specified version of the official repository
- Supports offline builds and auditing
- Keeps official source files completely unchanged

## Source Code Audit and Verification

To ensure transparency and trustworthiness, this project provides source verification scripts that anyone can use to verify our BLAKE3 sources actually come from the official repository's specified commit.

### Verification Script

The project includes a `verify-blake3-sources.sh` script that can automatically compare local sources with the official repository:

```bash
# Run verification script
./verify-blake3-sources.sh
```

### Script Functions

The script will:

1. Clone the specified commit code from the official BLAKE3 repository
2. Compare each file in the `src/blake3/` directory individually
3. Display detailed comparison results
4. Automatically clean up temporary files

### Manual Verification

If you prefer manual verification, you can use the following Git commands:

```bash
# 1. Clone official repository
git clone https://github.com/BLAKE3-team/BLAKE3.git /tmp/blake3-official

# 2. Switch to specified commit
cd /tmp/blake3-official
git checkout df610ddc3b93841ffc59a87e3da659a15910eb46

# 3. Compare files (using blake3.c as example)
diff src/blake3/blake3.c /tmp/blake3-official/c/blake3.c

# 4. Or use Git to compare entire directory
cd /path/to/your/project
git diff --no-index src/blake3/ /tmp/blake3-official/c/
```

### SHA256 Verification

You can also verify file integrity using SHA256:

```bash
# Calculate SHA256 of local files
find src/blake3 -name "*.c" -o -name "*.h" | sort | xargs sha256sum

# Compare with official repository
cd /tmp/blake3-official
find c -name "*.c" -o -name "*.h" | sort | xargs sha256sum
```

## Current Features

This extension provides BLAKE3 hash functionality with support for variable-length output and keyed hashing:

### blake3_hash()

```php
blake3_hash(string $data, int $output_size = 32, string $key = '', bool $raw_output = false): string
```

**Parameters:**
- `$data`: Input data to hash (required)
- `$output_size`: Optional, output length in bytes, default 32, range 1-65536
- `$key`: Optional, 32-byte key for keyed hash, default empty (regular hash)
- `$raw_output`: Optional, default `false`
  - `false`: Return lowercase hexadecimal string
  - `true`: Return raw binary data

**Return Value:**
- Returns BLAKE3 hash value on success
- Throws exception on failure

**Features:**
- ✅ Variable output length: 1 to 65536 bytes
- ✅ Keyed hash support: using 32-byte keys
- ✅ Multiple output formats: hex string or raw binary
- ✅ Complete parameter validation and error handling

## System Requirements

- PHP 7.0+
- Linux or macOS systems
- GCC compiler

### Supported CPU Architectures

This extension supports multiple CPU architectures and automatically enables corresponding hardware optimizations:

- **x86/x86_64**: Automatically enables SSE2, SSE4.1, AVX2, AVX512 optimizations
- **ARM64 (aarch64)**: Automatically enables NEON optimizations
- **Other ARM architectures**: Enables NEON optimizations (if supported)
- **Other architectures**: Uses portable implementation

The build system automatically detects CPU architecture and selects appropriate optimized implementations without manual configuration.

**Note**: Windows support is not currently available and will be added in future versions.

## Build and Installation

### 1. Prepare Build Environment

```bash
# Ensure PHP development packages are installed
# Ubuntu/Debian:
sudo apt-get install php-dev

# CentOS/RHEL:
sudo yum install php-devel

# macOS:
brew install php
```

### 2. Compile Extension

```bash
# Generate configuration script
phpize

# Configure build
./configure --enable-blake3

# Compile
make -j$(nproc)
```

### 3. Install

```bash
# Install to PHP extension directory
sudo make install

# Or manually copy
sudo cp modules/blake3.so $(php-config --extension-dir)/
```

### 4. Enable Extension

Add to `php.ini`:

```ini
extension=blake3.so
```

Or enable temporarily on command line:

```bash
php -d extension=blake3.so your_script.php
```

## Usage Examples

### Basic Hashing

```php
<?php
// Basic hash (default 32-byte output)
$hash = blake3_hash('hello world');
echo $hash; // d74981efa70a0c880b8d8c1985d075dbcbf679b99a5f9914e5aaf96b831a9e24

// Specify output length
$hash16 = blake3_hash('hello world', 16);
echo $hash16; // d74981efa70a0c880b8d8c1985d075db

// Get raw binary output
$raw_hash = blake3_hash('hello world', 32, '', true);
echo bin2hex($raw_hash); // Same as first example
?>
```

### Variable Length Output

```php
<?php
// Different length outputs
echo blake3_hash('test', 8) . "\n";   // 16-char hex (8 bytes)
echo blake3_hash('test', 32) . "\n";  // 64-char hex (32 bytes, default)
?>
```

### Keyed Hash

```php
<?php
// Generate 32-byte key
$key = random_bytes(32);

// Hash with key
$keyed_hash = blake3_hash('message', 32, $key);
echo $keyed_hash;

// Same message and key always produce same hash
$verify_hash = blake3_hash('message', 32, $key);
echo ($keyed_hash === $verify_hash) ? "✅ Verification success" : "❌ Verification failed";

// Different keys produce different hashes
$different_key = random_bytes(32);
$different_hash = blake3_hash('message', 32, $different_key);
echo ($keyed_hash !== $different_hash) ? "✅ Key effective" : "❌ Key invalid";
?>
```

### Quick Testing

```bash
# Test if extension works properly
php -d extension=modules/blake3.so -r "echo blake3_hash('test', 32, str_repeat('k', 32)), PHP_EOL;"
```

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

The official BLAKE3 C implementation is also licensed under Apache 2.0 License or CC0 License (see upstream repository for details).

## Related Links

- [BLAKE3 Official Website](https://blake3.io/)
- [BLAKE3 Official Repository](https://github.com/BLAKE3-team/BLAKE3)
- [BLAKE3 Specification](https://github.com/BLAKE3-team/BLAKE3-specs) 