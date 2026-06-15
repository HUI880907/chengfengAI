#!/bin/bash
# ======================================================
# 乘风AI - IPA 打包脚本（支持侧装 Sideload）
# 用法:
#   ./package_ipa.sh           - 完整打包（生成 -> 构建 -> 导出 IPA）
#   ./package_ipa.sh generate  - 仅生成 Xcode 项目
#   ./package_ipa.sh build     - 仅构建 & 导出 IPA
#   ./package_ipa.sh clean     - 清理
#
# 输出位置: ./output/乘风AI.ipa
#
# 说明:
#   在无 Apple Developer 账号时，使用 Payload 方式打包 IPA，
#   可通过 Sideloadly / AltStore 侧装到 iPhone。
# ======================================================

set -e

PROJECT_NAME="乘风AI"
SCHEME="乘风AI"
OUTPUT_DIR="output"
BUILD_DIR="build-ipa"
XCODEPROJ="${PROJECT_NAME}.xcodeproj"
ARCHIVE_PATH="${BUILD_DIR}/${PROJECT_NAME}.xcarchive"
IPA_PATH="${OUTPUT_DIR}/${PROJECT_NAME}.ipa"

# ---------- 颜色 ----------
RED='\033[0;31m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log_info(){ echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok(){ echo -e "${GREEN}[ OK ]${NC} $1"; }
log_warn(){ echo -e "${YELLOW}[WARN]${NC} $1"; }
log_err(){ echo -e "${RED}[FAIL]${NC} $1"; }

# ---------- 检查环境 ----------
check_env(){
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_err "此脚本必须在 macOS 上运行（Xcode 仅支持 macOS）"
        log_info "当前平台: $OSTYPE"
        exit 1
    fi
    if ! command -v xcodebuild &> /dev/null; then
        log_err "未找到 xcodebuild，请先安装 Xcode"
        exit 1
    fi
    log_info "Xcode 版本: $(xcodebuild -version | head -1)"
}

# ---------- 步骤 1: 生成 Xcode 项目 ----------
step_generate(){
    log_info ">>> 步骤 1/3: 生成 Xcode 项目"
    if ! command -v xcodegen &> /dev/null; then
        log_warn "未找到 xcodegen，尝试安装..."
        if command -v brew &> /dev/null; then
            brew install xcodegen
        else
            log_err "请先安装 Homebrew 和 XcodeGen"
            exit 1
        fi
    fi
    if [ -d "$XCODEPROJ" ]; then
        log_warn "移除旧项目: $XCODEPROJ"
        rm -rf "$XCODEPROJ"
    fi
    xcodegen generate
    log_ok "Xcode 项目已生成: $XCODEPROJ"
}

# ---------- 步骤 2: Archive ----------
step_archive(){
    log_info ">>> 步骤 2/3: Xcode Archive（真机）"
    if [ ! -d "$XCODEPROJ" ]; then
        log_err "未找到 $XCODEPROJ，请先运行: ./package_ipa.sh generate"
        exit 1
    fi
    mkdir -p "$BUILD_DIR"
    # 使用 iphoneos SDK，关闭代码签名以允许侧装
    xcodebuild \
        -project "$XCODEPROJ" \
        -scheme "$SCHEME" \
        -configuration Release \
        -sdk iphoneos \
        -archivePath "$ARCHIVE_PATH" \
        -derivedDataPath "$BUILD_DIR/derived" \
        archive \
        CODE_SIGNING_ALLOWED=NO \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGN_IDENTITY="" \
        ENABLE_HARDENED_RUNTIME=NO \
        ONLY_ACTIVE_ARCH=NO | xcpretty || true

    if [ ! -d "$ARCHIVE_PATH" ]; then
        log_err "Archive 失败 - 未生成: $ARCHIVE_PATH"
        exit 1
    fi
    log_ok "Archive 完成: $ARCHIVE_PATH"
}

# ---------- 步骤 3: 打包 IPA (Payload 方式 - 无需开发者账号) ----------
step_export_ipa(){
    log_info ">>> 步骤 3/3: 导出 IPA（Payload 方式，可侧装）"
    mkdir -p "$OUTPUT_DIR"

    APP_PATH=""
    # 从 .xcarchive/Products/Applications/ 下找到 .app
    if [ -d "$ARCHIVE_PATH/Products/Applications" ]; then
        for app in "$ARCHIVE_PATH/Products/Applications/"*.app; do
            APP_PATH="$app"
            break
        done
    fi

    if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
        log_err "未找到 .app 文件: $ARCHIVE_PATH"
        exit 1
    fi

    log_info "找到 App: $(basename "$APP_PATH")"

    # --- Payload 方式打包 IPA ---
    IPA_TEMP="${BUILD_DIR}/ipa_temp"
    rm -rf "$IPA_TEMP"
    mkdir -p "$IPA_TEMP/Payload"

    # 复制 .app 到 Payload
    cp -R "$APP_PATH" "$IPA_TEMP/Payload/"

    # 确保 .app 内可执行文件有执行权限
    EXEC_NAME=$(/usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" \
        "$IPA_TEMP/Payload/$(basename "$APP_PATH")/Info.plist" 2>/dev/null || echo "$PROJECT_NAME")
    chmod +x "$IPA_TEMP/Payload/$(basename "$APP_PATH")/$EXEC_NAME" 2>/dev/null || true

    # 添加 iTunesArtwork (可选)
    # echo "artwork placeholder" > "$IPA_TEMP/iTunesArtwork"

    # 生成基本的 SwiftSupport / 符号（简化：跳过，侧装工具会处理）

    # --- ZIP 为 IPA ---
    log_info "压缩 Payload -> IPA ..."
    (cd "$IPA_TEMP" && zip -qr "$(pwd)/${PROJECT_NAME}.ipa" .)
    mv "$IPA_TEMP/${PROJECT_NAME}.ipa" "$IPA_PATH"

    SIZE=$(du -h "$IPA_PATH" | cut -f1)
    log_ok "IPA 已生成: $IPA_PATH ($SIZE)"
}

# ---------- 清理 ----------
step_clean(){
    log_info "清理构建产物..."
    rm -rf "$BUILD_DIR"
    rm -rf "$OUTPUT_DIR"
    rm -rf "$XCODEPROJ"
    rm -rf "DerivedData"
    rm -rf ".build"
    log_ok "清理完成"
}

# ---------- 主流程 ----------
MODE="${1:-all}"
case "$MODE" in
    generate)
        check_env
        step_generate
        ;;
    build)
        check_env
        step_archive
        step_export_ipa
        ;;
    clean)
        step_clean
        ;;
    all|*)
        check_env
        step_generate
        step_archive
        step_export_ipa
        ;;
esac

echo ""
log_info "====================================="
log_info " 打包完成！"
log_info "  IPA: $IPA_PATH"
log_info " 安装方法: Sideloadly / AltStore / TrollStore"
log_info "====================================="
