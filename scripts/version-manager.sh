#!/bin/bash

# ===================================================================
# 범용 버전 관리 스크립트
# ===================================================================
#
# 이 스크립트는 다양한 프로젝트 타입에서 버전 정보를 추출하고 업데이트합니다.
# version.yml 파일의 설정에 따라 적절한 파일에서 버전을 읽고 업데이트합니다.
#
# 사용법:
# ./version-manager.sh [command] [options]
#
# Commands:
# - get: 현재 버전 가져오기
# - increment: patch 버전 증가 (x.x.x -> x.x.x+1)
# - set: 특정 버전으로 설정
# - validate: 버전 형식 검증
#
# ===================================================================

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수 (GitHub Actions 호환)
log_info() {
    if [ -n "$GITHUB_ACTIONS" ]; then
        echo "[INFO] $1"
    else
        echo -e "${BLUE}[INFO]${NC} $1"
    fi
}

log_success() {
    if [ -n "$GITHUB_ACTIONS" ]; then
        echo "[SUCCESS] $1"
    else
        echo -e "${GREEN}[SUCCESS]${NC} $1"
    fi
}

log_warning() {
    if [ -n "$GITHUB_ACTIONS" ]; then
        echo "[WARNING] $1"
    else
        echo -e "${YELLOW}[WARNING]${NC} $1"
    fi
}

log_error() {
    if [ -n "$GITHUB_ACTIONS" ]; then
        echo "[ERROR] $1"
    else
        echo -e "${RED}[ERROR]${NC} $1"
    fi
}

# version.yml에서 설정 읽기
read_version_config() {
    if [ ! -f "version.yml" ]; then
        log_error "version.yml 파일을 찾을 수 없습니다!"
        exit 1
    fi
    
    # yq가 없으면 기본 파싱 사용
    if command -v yq >/dev/null 2>&1; then
        PROJECT_TYPE=$(yq e '.project_type' version.yml)
        VERSION_FILE=$(yq e '.version_file' version.yml)
        CURRENT_VERSION=$(yq e '.version' version.yml)
        
        # 프로젝트 타입별 설정
        if [ "$PROJECT_TYPE" != "template" ]; then
            VERSION_FILE=$(yq e ".project_configs.${PROJECT_TYPE}.version_file" version.yml)
            if [ "$VERSION_FILE" = "null" ]; then
                VERSION_FILE="version.yml"
            fi
            VERSION_PATTERN=$(yq e ".project_configs.${PROJECT_TYPE}.version_pattern" version.yml)
            VERSION_FORMAT=$(yq e ".project_configs.${PROJECT_TYPE}.version_format" version.yml)
        fi
    else
        # yq 없이 기본 파싱
        PROJECT_TYPE=$(grep "^project_type:" version.yml | sed 's/project_type: *"\([^"]*\)".*/\1/')
        VERSION_FILE=$(grep "^version_file:" version.yml | sed 's/version_file: *"\([^"]*\)".*/\1/')
        CURRENT_VERSION=$(grep "^version:" version.yml | sed 's/version: *"\([^"]*\)".*/\1/')
        
        # 프로젝트 타입별 설정 (fallback)
        if [ "$PROJECT_TYPE" != "template" ]; then
            case "$PROJECT_TYPE" in
                "spring") VERSION_FILE="build.gradle" ;;
                "flutter") VERSION_FILE="pubspec.yaml" ;;
                "react"|"react-native"|"node") VERSION_FILE="package.json" ;;
                "python") VERSION_FILE="pyproject.toml" ;;
                *) VERSION_FILE="version.yml" ;;
            esac
        fi
    fi
    
    if [ -n "$GITHUB_ACTIONS" ]; then
        # GitHub Actions에서는 stderr로 로그 출력
        echo "[INFO] 프로젝트 타입: $PROJECT_TYPE" >&2
        echo "[INFO] 버전 파일: $VERSION_FILE" >&2
        echo "[INFO] 현재 버전: $CURRENT_VERSION" >&2
    else
        log_info "프로젝트 타입: $PROJECT_TYPE"
        log_info "버전 파일: $VERSION_FILE"
        log_info "현재 버전: $CURRENT_VERSION"
    fi
}

# 실제 프로젝트 파일에서 버전 추출
get_version_from_project_file() {
    if [ "$PROJECT_TYPE" = "template" ]; then
        echo "$CURRENT_VERSION"
        return
    fi
    
    if [ ! -f "$VERSION_FILE" ]; then
        if [ -z "$GITHUB_ACTIONS" ]; then
            log_warning "$VERSION_FILE 파일을 찾을 수 없습니다. version.yml의 버전을 사용합니다."
        fi
        echo "$CURRENT_VERSION"
        return
    fi
    
    case "$PROJECT_TYPE" in
        "spring")
            # build.gradle에서 버전 추출
            if grep -q "version = '" "$VERSION_FILE"; then
                grep "version = '" "$VERSION_FILE" | sed "s/.*version = '\([^']*\)'.*/\1/" | head -1
            elif grep -q "version = \"" "$VERSION_FILE"; then
                grep "version = \"" "$VERSION_FILE" | sed 's/.*version = "\([^"]*\)".*/\1/' | head -1
            elif grep -q "^version " "$VERSION_FILE"; then
                grep "^version " "$VERSION_FILE" | sed 's/version[[:space:]]*=[[:space:]]*\x27\([^'"'"']*\)\x27.*/\1/' | head -1
            else
                echo "$CURRENT_VERSION"
            fi
            ;;
        "flutter")
            # pubspec.yaml에서 버전 추출  
            if grep -q "version:" "$VERSION_FILE"; then
                grep "^version:" "$VERSION_FILE" | sed 's/version: *\([0-9.]*\).*/\1/' | head -1
            else
                echo "$CURRENT_VERSION"
            fi
            ;;
        "react"|"react-native"|"node")
            # package.json에서 버전 추출
            if command -v jq >/dev/null 2>&1; then
                jq -r '.version' "$VERSION_FILE" 2>/dev/null || echo "$CURRENT_VERSION"
            else
                grep '"version":' "$VERSION_FILE" | sed 's/.*"version": *"\([^"]*\)".*/\1/' | head -1 || echo "$CURRENT_VERSION"
            fi
            ;;
        "python")
            # pyproject.toml에서 버전 추출
            if grep -q 'version = ' "$VERSION_FILE"; then
                grep 'version = ' "$VERSION_FILE" | sed 's/.*version = *"\([^"]*\)".*/\1/' | head -1
            else
                echo "$CURRENT_VERSION"
            fi
            ;;
        *)
            echo "$CURRENT_VERSION"
            ;;
    esac
}

# 버전 형식 검증
validate_version() {
    local version=$1
    if [[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}

# patch 버전 증가
increment_patch_version() {
    local version=$1
    local major=$(echo "$version" | cut -d. -f1)
    local minor=$(echo "$version" | cut -d. -f2)
    local patch=$(echo "$version" | cut -d. -f3)
    
    patch=$((patch + 1))
    echo "${major}.${minor}.${patch}"
}

# React Native 특별 처리 함수들
update_react_native_android_build() {
    local new_version=$1
    local android_build_file="android/app/build.gradle"
    
    if [ -f "$android_build_file" ]; then
        # versionName 업데이트
        if grep -q "versionName" "$android_build_file"; then
            sed -i.bak "s/versionName \".*\"/versionName \"$new_version\"/" "$android_build_file"
            rm -f "${android_build_file}.bak"
            log_info "Android versionName 업데이트: $new_version"
        fi
        
        # versionCode 증가 (옵션)
        if grep -q "versionCode" "$android_build_file"; then
            current_code=$(grep "versionCode" "$android_build_file" | sed 's/.*versionCode *\([0-9]*\).*/\1/')
            new_code=$((current_code + 1))
            sed -i.bak "s/versionCode $current_code/versionCode $new_code/" "$android_build_file"
            rm -f "${android_build_file}.bak"
            log_info "Android versionCode 증가: $current_code → $new_code"
        fi
    fi
}

update_react_native_ios_version() {
    local new_version=$1
    
    # iOS Info.plist 파일들 찾기
    find ios -name "Info.plist" -type f | while read plist_file; do
        if [ -f "$plist_file" ]; then
            # CFBundleShortVersionString 업데이트
            if grep -q "CFBundleShortVersionString" "$plist_file"; then
                # CFBundleShortVersionString 키 다음 줄의 string 값 업데이트
                sed -i.bak '/CFBundleShortVersionString/{n;s/<string>[^<]*<\/string>/<string>'$new_version'<\/string>/;}' "$plist_file"
                rm -f "${plist_file}.bak"
                log_info "iOS 버전 업데이트: $plist_file"
            fi
        fi
    done
}

# 프로젝트 파일의 버전 업데이트
update_project_file() {
    local new_version=$1
    
    if [ "$PROJECT_TYPE" = "template" ]; then
        # version.yml 업데이트
        if command -v yq >/dev/null 2>&1; then
            yq e ".version = \"$new_version\"" -i version.yml
        else
            sed -i.bak "s/version: \".*\"/version: \"$new_version\"/" version.yml
            rm -f version.yml.bak
        fi
        return
    fi
    
    if [ ! -f "$VERSION_FILE" ]; then
        log_warning "$VERSION_FILE 파일을 찾을 수 없습니다. version.yml만 업데이트합니다."
        update_version_yml "$new_version"
        return
    fi
    
    case "$PROJECT_TYPE" in
        "spring")
            # build.gradle 업데이트
            sed -i.bak "s/version = '.*'/version = '$new_version'/" "$VERSION_FILE"
            rm -f "${VERSION_FILE}.bak"
            ;;
        "flutter")
            # pubspec.yaml 업데이트 (빌드 번호는 유지)
            if grep -q "version:" "$VERSION_FILE"; then
                current_line=$(grep "^version:" "$VERSION_FILE")
                if [[ $current_line =~ \+[0-9]+ ]]; then
                    build_number=$(echo "$current_line" | sed 's/.*+\([0-9]*\).*/\1/')
                    sed -i.bak "s/^version:.*/version: $new_version+$build_number/" "$VERSION_FILE"
                else
                    sed -i.bak "s/^version:.*/version: $new_version+1/" "$VERSION_FILE"
                fi
            else
                echo "version: $new_version+1" >> "$VERSION_FILE"
            fi
            rm -f "${VERSION_FILE}.bak"
            ;;
        "react"|"node")
            # package.json 업데이트
            if command -v jq >/dev/null 2>&1; then
                jq ".version = \"$new_version\"" "$VERSION_FILE" > tmp.json && mv tmp.json "$VERSION_FILE"
            else
                sed -i.bak "s/\"version\": *\"[^\"]*\"/\"version\": \"$new_version\"/" "$VERSION_FILE"
                rm -f "${VERSION_FILE}.bak"
            fi
            ;;
        "react-native")
            # package.json 업데이트
            if command -v jq >/dev/null 2>&1; then
                jq ".version = \"$new_version\"" "$VERSION_FILE" > tmp.json && mv tmp.json "$VERSION_FILE"
            else
                sed -i.bak "s/\"version\": *\"[^\"]*\"/\"version\": \"$new_version\"/" "$VERSION_FILE"
                rm -f "${VERSION_FILE}.bak"
            fi
            
            # React Native 특별 처리
            log_info "React Native 플랫폼별 버전 업데이트 중..."
            update_react_native_android_build "$new_version"
            update_react_native_ios_version "$new_version"
            ;;
        "python")
            # pyproject.toml 업데이트
            sed -i.bak "s/version = \".*\"/version = \"$new_version\"/" "$VERSION_FILE"
            rm -f "${VERSION_FILE}.bak"
            ;;
    esac
    
    # version.yml도 함께 업데이트
    update_version_yml "$new_version"
}

# version.yml 업데이트
update_version_yml() {
    local new_version=$1
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local user=${GITHUB_ACTOR:-$(whoami)}
    
    if command -v yq >/dev/null 2>&1; then
        yq e ".version = \"$new_version\"" -i version.yml
        yq e ".metadata.last_updated = \"$timestamp\"" -i version.yml
        yq e ".metadata.last_updated_by = \"$user\"" -i version.yml
    else
        sed -i.bak "s/version: \".*\"/version: \"$new_version\"/" version.yml
        sed -i.bak "s/last_updated: \".*\"/last_updated: \"$timestamp\"/" version.yml
        sed -i.bak "s/last_updated_by: \".*\"/last_updated_by: \"$user\"/" version.yml
        rm -f version.yml.bak
    fi
}

# 메인 함수
main() {
    local command=${1:-get}
    
    # 설정 읽기
    read_version_config
    
    case "$command" in
        "get")
            local version=$(get_version_from_project_file)
            if [ -n "$GITHUB_ACTIONS" ]; then
                # GitHub Actions에서는 로그와 결과를 분리
                echo "[INFO] 현재 버전: $version" >&2
                echo "$version"
            else
                log_info "현재 버전: $version"
                echo "$version"
            fi
            ;;
        "increment")
            local current_version=$(get_version_from_project_file)
            if ! validate_version "$current_version"; then
                log_error "잘못된 버전 형식: $current_version"
                exit 1
            fi
            
            local new_version=$(increment_patch_version "$current_version")
            log_info "버전 업데이트: $current_version -> $new_version"
            
            update_project_file "$new_version"
            log_success "버전 업데이트 완료: $new_version"
            echo "$new_version"
            ;;
        "set")
            local new_version=$2
            if [ -z "$new_version" ]; then
                log_error "새 버전을 지정해주세요: ./version-manager.sh set 1.2.3"
                exit 1
            fi
            
            if ! validate_version "$new_version"; then
                log_error "잘못된 버전 형식: $new_version (x.x.x 형식이어야 합니다)"
                exit 1
            fi
            
            log_info "버전 설정: $new_version"
            update_project_file "$new_version"
            log_success "버전 설정 완료: $new_version"
            echo "$new_version"
            ;;
        "validate")
            local version=${2:-$(get_version_from_project_file)}
            if validate_version "$version"; then
                log_success "유효한 버전 형식입니다: $version"
                exit 0
            else
                log_error "잘못된 버전 형식입니다: $version"
                exit 1
            fi
            ;;
        *)
            echo "사용법: $0 {get|increment|set|validate} [version]"
            echo ""
            echo "Commands:"
            echo "  get       - 현재 버전 가져오기"
            echo "  increment - patch 버전 증가"
            echo "  set       - 특정 버전으로 설정"
            echo "  validate  - 버전 형식 검증"
            echo ""
            echo "Examples:"
            echo "  $0 get"
            echo "  $0 increment"
            echo "  $0 set 1.2.3"
            echo "  $0 validate 1.2.3"
            exit 1
            ;;
    esac
}

# 스크립트 실행
main "$@"