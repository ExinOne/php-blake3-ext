# PHP BLAKE3 Extension

这是一个轻量级的PHP扩展，提供对BLAKE3密码学哈希函数的支持。

## 关于BLAKE3

BLAKE3是一个快速、安全的密码学哈希函数，由BLAKE2的作者设计。它提供了比SHA-2更好的性能，同时保持了高水平的安全性。

## 官方源码信息

本扩展使用官方BLAKE3 C实现：

- **上游仓库**: https://github.com/BLAKE3-team/BLAKE3
- **使用版本**: 1.8.2
- **固定Commit**: `df610ddc3b93841ffc59a87e3da659a15910eb46`
- **下载时间**: 基于上述commit固定版本

## Vendor策略

为了确保可重现的构建和安全性，本项目采用Vendor策略：

- 使用固定的官方commit，避免上游变更影响
- 所有源码文件都直接来自官方仓库的指定版本
- 支持离线构建和审计
- 保持官方源码文件完全不变

## 源码审计与验证

为了确保透明度和可信度，本项目提供了源码验证脚本，任何人都可以验证我们的BLAKE3源码确实来自官方仓库的指定commit。

### 验证脚本

项目包含 `verify-blake3-sources.sh` 脚本，可以自动比较本地源码与官方仓库：

```bash
# 运行验证脚本
./verify-blake3-sources.sh
```

### 脚本功能

该脚本会：

1. 从官方BLAKE3仓库克隆指定commit的代码
2. 逐个比较 `src/blake3/` 目录下的每个文件
3. 显示详细的比较结果
4. 自动清理临时文件

### 手动验证

如果您希望手动验证，可以使用以下Git命令：

```bash
# 1. 克隆官方仓库
git clone https://github.com/BLAKE3-team/BLAKE3.git /tmp/blake3-official

# 2. 切换到指定commit
cd /tmp/blake3-official
git checkout df610ddc3b93841ffc59a87e3da659a15910eb46

# 3. 比较文件（以blake3.c为例）
diff src/blake3/blake3.c /tmp/blake3-official/c/blake3.c

# 4. 或使用Git比较整个目录
cd /path/to/your/project
git diff --no-index src/blake3/ /tmp/blake3-official/c/
```

## 当前功能

本扩展目前提供最小功能集：

### blake3_hash()

```php
blake3_hash(string $data, bool $raw_output = false): string
```

**参数:**
- `$data`: 要哈希的输入数据
- `$raw_output`: 可选，默认`false`
  - `false`: 返回64字符的小写十六进制字符串
  - `true`: 返回32字节的原始二进制数据

**返回值:**
- 成功时返回BLAKE3哈希值（固定32字节）
- 失败时返回`false`

**特性:**
- 固定输出长度：32字节
- 不支持keyed hash
- 不支持derive key功能
- 不支持可变长度输出
- 不支持流式API

## 系统要求

- PHP 7.0+
- Linux或macOS系统
- GCC编译器

### 支持的CPU架构

本扩展支持多种CPU架构，并自动启用对应的硬件优化：

- **x86/x86_64**: 自动启用SSE2、SSE4.1、AVX2、AVX512优化
- **ARM64 (aarch64)**: 自动启用NEON优化
- **其他ARM架构**: 启用NEON优化（如果支持）
- **其他架构**: 使用portable实现

构建系统会自动检测CPU架构并选择合适的优化实现，无需手动配置。

**注意**: 当前版本不支持Windows，Windows支持将在后续版本中添加。

## 构建安装

### 1. 准备构建环境

```bash
# 确保安装了PHP开发包
# Ubuntu/Debian:
sudo apt-get install php-dev

# CentOS/RHEL:
sudo yum install php-devel

# macOS:
brew install php
```

### 2. 编译扩展

```bash
# 生成配置脚本
phpize

# 配置构建
./configure --enable-blake3

# 编译
make -j$(nproc)
```

### 3. 安装

```bash
# 安装到PHP扩展目录
sudo make install

# 或者手动复制
sudo cp modules/blake3.so $(php-config --extension-dir)/
```

### 4. 启用扩展

在`php.ini`中添加：

```ini
extension=blake3.so
```

或者在命令行中临时启用：

```bash
php -d extension=blake3.so your_script.php
```

## 使用示例

### 基本用法

```php
<?php
// 基本哈希（返回hex字符串）
$hash = blake3_hash('hello world');
echo $hash; // 输出64字符的小写十六进制字符串

// 获取原始二进制输出
$raw_hash = blake3_hash('hello world', true);
echo bin2hex($raw_hash); // 与上面的$hash相同
?>
```

### 快速测试

```bash
# 测试扩展是否正常工作
php -d extension=modules/blake3.so -r "echo blake3_hash('abc'), PHP_EOL;"

# 检查扩展信息
php -d extension=modules/blake3.so -m | grep blake3
```

## 许可证

本PHP扩展代码遵循PHP License。

官方BLAKE3 C实现遵循Apache 2.0 License或CC0 License（详见上游仓库）。


## 相关链接

- [BLAKE3官方网站](https://blake3.io/)
- [BLAKE3官方仓库](https://github.com/BLAKE3-team/BLAKE3)
- [BLAKE3规范](https://github.com/BLAKE3-team/BLAKE3-specs) 