#!/bin/bash
# ======================================================
# 乘风AI - 项目构建脚本 (macOS / Linux)
# 使用方法:
#   ./build.sh setup      - 安装XcodeGen
#   ./build.sh generate   - 生成 Xcode 项目
#   ./build.sh build      - 构建 Debug 版本
#   ./build.sh release    - 构建 Release 版本
#   ./build.sh archive    - 打包 Archive
#   ./build.sh test       - 运行单元测试
#   ./build.sh clean      - 清理构建产物
#   ./build.sh all        - 执行: setup -> generate -> build
# ======================================================

set -e

PROJECT_NAME="乘风AI"
SCHEME="乘风AI"
BUILD_DIR="build"
XCODEPROJ="${PROJECT_NAME}.xcodeproj"

# ---------- 颜色输出 ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}
log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}
log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}
log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ---------- 检查 macOS ----------
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "此脚本需要在 macOS 上运行 (iOS 项目构建必须使用 Xcode)"
        exit 1
    fi
}

# ---------- 检查 Xcode ----------
check_xcode() {
    if ! command -v xcodebuild &> /dev/null; then
        log_error "未找到 xcodebuild，请先安装 Xcode"
        exit 1
    fi
    log_info "Xcode 版本: $(xcodebuild -version | head -1)"
}

# ---------- Setup: 安装 XcodeGen ----------
setup() {
    log_info "检查并安装 XcodeGen..."
    if command -v xcodegen &> /dev/null; then
        log_success "XcodeGen 已安装: $(xcodegen --version)"
    else
        log_warn "未找到 XcodeGen，尝试通过 brew 安装..."
        if command -v brew &> /dev/null; then
            brew install xcodegen
            log_success "XcodeGen 安装完成"
        else
            log_error "未找到 brew，请先安装 Homebrew (https://brew.sh)"
            exit 1
        fi
    fi
}

# ---------- Generate: 生成 Xcode 项目 ----------
generate() {
    log_info "生成 Xcode 项目..."
    if [ -d "$XCODEPROJ" ]; then
        log_warn "移除旧的 $XCODEPROJ"
        rm -rf "$XCODEPROJ"
    fi
    xcodegen generate
    log_success "项目生成完成: $XCODEPROJ"
}

# ---------- Build: 构建 Debug ----------
build() {
    check_macos
    if [ ! -d "$XCODEPROJ" ]; then
        log_warn "项目未生成，先生成..."
        generate
    fi
    log_info "构建 Debug 版本..."
    xcodebuild \
        -project "$XCODEPROJ" \
        -scheme "$SCHEME" \
        -configuration Debug \
        -sdk iphonesimulator \
        -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' \
        -derivedDataPath "$BUILD_DIR" \
        build \
        CODE_SIGNING_ALLOWED=NO | xcpretty || true
    log_success "Debug 构建完成"
}

# ---------- Release: 构建 Release ----------
release() {
    check_macos
    if [ ! -d "$XCODEPROJ" ]; then
        log_warn "项目未生成，先生成..."
        generate
    fi
    log_info "构建 Release 版本..."
    xcodebuild \
        -project "$XCODEPROJ" \
        -scheme "$SCHEME" \
        -configuration Release \
        -sdk iphoneos \
        -derivedDataPath "$BUILD_DIR" \
        build \
        CODE_SIGNING_ALLOWED=NO | xcpretty || true
    log_success "Release 构建完成"
}

# ---------- Archive: 打包 Archive ----------
archive() {
    check_macos
    if [ ! -d "$XCODEPROJ" ]; then
        log_warn "项目未生成，先生成..."
        generate
    fi
    log_info "打包 Archive..."
    local ARCHIVE_PATH="$BUILD_DIR/${PROJECT_NAME}.xcarchive"
    mkdir -p "$BUILD_DIR"
    xcodebuild \
        -project "$XCODEPROJ" \
        -scheme "$SCHEME" \
        -configuration Release \
        -archivePath "$ARCHIVE_PATH" \
        archive \
        CODE_SIGNING_ALLOWED=NO | xcpretty || true
    log_success "Archive 完成: $ARCHIVE_PATH"
}

# ---------- Test: 运行单元测试 ----------
test() {
    check_macos
    if [ ! -d "$XCODEPROJ" ]; then
        log_warn "项目未生成，先生成..."
        generate
    fi
    log_info "运行单元测试..."
    xcodebuild \
        -project "$XCODEPROJ" \
        -scheme "$SCHEME" \
        -configuration Debug \
        -sdk iphonesimulator \
        -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' \
        -derivedDataPath "$BUILD_DIR" \
        test \
        CODE_SIGNING_ALLOWED=NO | xcpretty || true
    log_success "测试完成"
}

# ---------- Clean: 清理构建产物 ----------
clean() {
    log_info "清理构建产物..."
    rm -rf "$BUILD_DIR"
    rm -rf "$XCODEPROJ"
    rm -rf DerivedData
    rm -rf .build
    log_success "清理完成"
}

# ---------- All: 完整流程 ----------
all() {
    check_macos
    check_xcode
    setup
    generate
    build
}

# ---------- 主流程 ----------
case "${1:-build}" in
    setup)      setup ;;
    generate)   generate ;;
    build)      build ;;
    release)    release ;;
    archive)    archive ;;
    test)       test ;;
    clean)      clean ;;
    all)        all ;;
    *)
        echo "用法: $0 {setup|generate|build|release|archive|test|clean|all}"
        exit 1
        ;;
esac
