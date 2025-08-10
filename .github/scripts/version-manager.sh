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

# 간단한 로그 함수
echo_info() {
    echo "========================="
    echo "$1"
    echo "========================="
}

echo_success() {
    echo "✅ $1"
}

echo_error() {
    echo "❌ $1"
}

# version.yml에서 설정 읽기
read_version_config() {
    if [ ! -f "version.yml" ]; then
        echo_error "version.yml 파일을 찾을 수 없습니다!"
        exit 1
    fi
    
    # yq가 없으면 기본 파싱 사용
    if command -v yq >/dev/null 2>&1; then
        PROJECT_TYPE=$(yq e '.project_type' version.yml)
        VERSION_FILE=$(yq e '.version_file' version.yml)
        CURRENT_VERSION=$(yq e '.version' version.yml)
        
        # 프로젝트 타입별 설정
        if [ "$PROJECT_TYPE" != "basic" ]; then
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
        if [ "$PROJECT_TYPE" != "basic" ]; then
            case "$PROJECT_TYPE" in
                "spring") VERSION_FILE="build.gradle" ;;
                "flutter") VERSION_FILE="pubspec.yaml" ;;
                "react"|"node") VERSION_FILE="package.json" ;;
                "react-native") VERSION_FILE="ios/*/Info.plist" ;;
                "react-native-expo") VERSION_FILE="app.json" ;;
                *) VERSION_FILE="version.yml" ;;
            esac
        fi
    fi
    
    echo_info "프로젝트 정보"
    echo "프로젝트 타입: $PROJECT_TYPE"
    echo "버전 파일: $VERSION_FILE"  
    echo "현재 버전: $CURRENT_VERSION"
}

# 버전 비교 함수 (v1 > v2이면 1 반환, v1 < v2이면 -1 반환, 같으면 0 반환)
compare_versions() {
    local v1=$1
    local v2=$2
    
    # 버전을 배열로 분리
    IFS='.' read -ra v1_parts <<< "$v1"
    IFS='.' read -ra v2_parts <<< "$v2"
    
    # 각 부분을 비교
    for i in 0 1 2; do
        if [ "${v1_parts[$i]}" -gt "${v2_parts[$i]}" ]; then
            return 1  # v1이 더 큼
        elif [ "${v1_parts[$i]}" -lt "${v2_parts[$i]}" ]; then
            return -1  # v2가 더 큼
        fi
    done
    
    return 0  # 동일함
}

# 두 버전 중 높은 버전 반환
get_higher_version() {
    local v1=$1
    local v2=$2
    
    compare_versions "$v1" "$v2"
    result=$?
    
    if [ $result -eq 1 ] || [ $result -eq 0 ]; then
        echo "$v1"  # v1이 더 높거나 같음
    else
        echo "$v2"  # v2가 더 높음
    fi
}

# 실제 프로젝트 파일에서 버전 추출
get_version_from_project_file() {
    if [ "$PROJECT_TYPE" = "basic" ]; then
        echo "$CURRENT_VERSION"
        return
    fi
    
    # React Native의 경우 특별 처리
    if [ "$PROJECT_TYPE" = "react-native" ]; then
        # 직접 iOS/Android 파일에서 버전 추출
        IOS_PLIST=$(find ios -name "Info.plist" -type f | head -1)
        if [ -f "$IOS_PLIST" ]; then
            if command -v /usr/libexec/PlistBuddy >/dev/null 2>&1; then
                /usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$IOS_PLIST" 2>/dev/null || echo "$CURRENT_VERSION"
            else
                grep -A1 "CFBundleShortVersionString" "$IOS_PLIST" | tail -1 | grep -oP '>\K[^<]+' 2>/dev/null || echo "$CURRENT_VERSION"
            fi
            return
        else
            # iOS 없으면 Android 확인
            ANDROID_BUILD="android/app/build.gradle"
            if [ -f "$ANDROID_BUILD" ]; then
                grep -oP 'versionName *"\K[^"]+' "$ANDROID_BUILD" | head -1 || echo "$CURRENT_VERSION"
                return
            else
                echo "$CURRENT_VERSION"
                return
            fi
        fi
    fi
    
    if [ ! -f "$VERSION_FILE" ]; then
        echo "⚠️ $VERSION_FILE 파일을 찾을 수 없습니다. version.yml의 버전을 사용합니다."
        echo "$CURRENT_VERSION"
        return
    fi
    
    local PROJECT_VERSION=""
    
    case "$PROJECT_TYPE" in
        "spring")
            # build.gradle에서 버전 추출
            if grep -q "version = '" "$VERSION_FILE"; then
                PROJECT_VERSION=$(grep "version = '" "$VERSION_FILE" | sed "s/.*version = '\([^']*\)'.*/\1/" | head -1)
            elif grep -q "version = \"" "$VERSION_FILE"; then
                PROJECT_VERSION=$(grep "version = \"" "$VERSION_FILE" | sed 's/.*version = "\([^"]*\)".*/\1/' | head -1)
            elif grep -q "^version " "$VERSION_FILE"; then
                PROJECT_VERSION=$(grep "^version " "$VERSION_FILE" | sed 's/version[[:space:]]*=[[:space:]]*\x27\([^'"'"']*\)\x27.*/\1/' | head -1)
            else
                PROJECT_VERSION="$CURRENT_VERSION"
            fi
            ;;
        "flutter")
            # pubspec.yaml에서 버전 추출  
            if grep -q "version:" "$VERSION_FILE"; then
                PROJECT_VERSION=$(grep "^version:" "$VERSION_FILE" | sed 's/version: *\([0-9.]*\).*/\1/' | head -1)
            else
                PROJECT_VERSION="$CURRENT_VERSION"
            fi
            ;;
        "react"|"node")
            # package.json에서 버전 추출
            if command -v jq >/dev/null 2>&1; then
                PROJECT_VERSION=$(jq -r '.version' "$VERSION_FILE" 2>/dev/null || echo "$CURRENT_VERSION")
            else
                PROJECT_VERSION=$(grep '"version":' "$VERSION_FILE" | sed 's/.*"version": *"\([^"]*\)".*/\1/' | head -1 || echo "$CURRENT_VERSION")
            fi
            ;;
        "react-native")
            # iOS Info.plist 우선 확인
            IOS_PLIST=$(find ios -name "Info.plist" -type f | head -1)
            if [ -f "$IOS_PLIST" ]; then
                if command -v /usr/libexec/PlistBuddy >/dev/null 2>&1; then
                    PROJECT_VERSION=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$IOS_PLIST" 2>/dev/null || echo "$CURRENT_VERSION")
                else
                    PROJECT_VERSION=$(grep -A1 "CFBundleShortVersionString" "$IOS_PLIST" | tail -1 | grep -oP '>\K[^<]+' 2>/dev/null || echo "$CURRENT_VERSION")
                fi
            else
                # iOS 없으면 Android 확인
                ANDROID_BUILD="android/app/build.gradle"
                if [ -f "$ANDROID_BUILD" ]; then
                    PROJECT_VERSION=$(grep -oP 'versionName *"\K[^"]+' "$ANDROID_BUILD" | head -1 || echo "$CURRENT_VERSION")
                else
                    PROJECT_VERSION="$CURRENT_VERSION"
                fi
            fi
            ;;
        "react-native-expo")
            # app.json에서 expo.version 추출
            if command -v jq >/dev/null 2>&1; then
                PROJECT_VERSION=$(jq -r '.expo.version' "$VERSION_FILE" 2>/dev/null || echo "$CURRENT_VERSION")
            else
                PROJECT_VERSION=$(grep -oP '"version": *"\K[^"]+' "$VERSION_FILE" || echo "$CURRENT_VERSION")
            fi
            ;;

        *)
            PROJECT_VERSION="$CURRENT_VERSION"
            ;;
    esac
    
    # 프로젝트 파일 버전과 version.yml 버전 중 높은 버전 선택
    if [ -n "$PROJECT_VERSION" ] && [ "$PROJECT_VERSION" != "$CURRENT_VERSION" ]; then
        FINAL_VERSION=$(get_higher_version "$PROJECT_VERSION" "$CURRENT_VERSION")
        echo "버전 불일치 감지: 프로젝트($PROJECT_VERSION) vs version.yml($CURRENT_VERSION)"
        echo "✅ 높은 버전으로 동기화: $FINAL_VERSION"
        echo "$FINAL_VERSION"
    else
        echo "$PROJECT_VERSION"
    fi
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

# React Native Bare 업데이트 함수
update_react_native_bare() {
    local new_version=$1
    
    # iOS 우선 업데이트
    echo "🍎 iOS 버전 업데이트 중..."
    find ios -name "Info.plist" -type f | while read plist_file; do
        if [ -f "$plist_file" ]; then
            if grep -q "CFBundleShortVersionString" "$plist_file"; then
                sed -i.bak '/CFBundleShortVersionString/{n;s/<string>[^<]*<\/string>/<string>'$new_version'<\/string>/;}' "$plist_file"
                rm -f "${plist_file}.bak"
                echo "  ✅ $plist_file"
            fi
        fi
    done
    
    # Android 업데이트
    echo "📱 Android 버전 업데이트 중..."
    local android_build_file="android/app/build.gradle"
    if [ -f "$android_build_file" ]; then
        # versionName 업데이트
        if grep -q "versionName" "$android_build_file"; then
            sed -i.bak "s/versionName \".*\"/versionName \"$new_version\"/" "$android_build_file"
            rm -f "${android_build_file}.bak"
            echo "  ✅ versionName: $new_version"
        fi
        
        # versionCode 증가 (옵션)
        if grep -q "versionCode" "$android_build_file"; then
            current_code=$(grep "versionCode" "$android_build_file" | sed 's/.*versionCode *\([0-9]*\).*/\1/')
            new_code=$((current_code + 1))
            sed -i.bak "s/versionCode $current_code/versionCode $new_code/" "$android_build_file"
            rm -f "${android_build_file}.bak"
            echo "  ✅ versionCode: $current_code → $new_code"
        fi
    fi
}

# React Native Expo 업데이트 함수
update_react_native_expo() {
    local new_version=$1
    local app_json="app.json"
    
    echo "📱 Expo 버전 업데이트 중..."
    if [ -f "$app_json" ]; then
        if command -v jq >/dev/null 2>&1; then
            jq ".expo.version = \"$new_version\"" "$app_json" > tmp.json && mv tmp.json "$app_json"
            echo "  ✅ expo.version: $new_version"
        else
            # jq 없는 경우 sed 사용
            sed -i.bak 's/"version": *"[^"]*"/"version": "'$new_version'"/' "$app_json"
            rm -f "${app_json}.bak"
            echo "  ✅ expo.version: $new_version (sed)"
        fi
    fi
}

# 프로젝트 파일의 버전 업데이트
update_project_file() {
    local new_version=$1
    
    if [ "$PROJECT_TYPE" = "basic" ]; then
        # version.yml 업데이트
        if command -v yq >/dev/null 2>&1; then
            yq e ".version = \"$new_version\"" -i version.yml
        else
            sed -i.bak "s/version: \".*\"/version: \"$new_version\"/" version.yml
            rm -f version.yml.bak
        fi
        return
    fi
    
    # React Native 케이스는 특별 처리
    if [ "$PROJECT_TYPE" = "react-native" ]; then
        echo_info "React Native Bare 프로젝트 업데이트"
        update_react_native_bare "$new_version"
        # version.yml도 프로젝트 실제 버전과 동기화
        update_version_yml "$new_version"
        return
    elif [ "$PROJECT_TYPE" = "react-native-expo" ]; then
        echo_info "React Native Expo 프로젝트 업데이트" 
        update_react_native_expo "$new_version"
        # version.yml도 프로젝트 실제 버전과 동기화
        update_version_yml "$new_version"
        return
    fi
    
    if [ ! -f "$VERSION_FILE" ]; then
        echo "⚠️ $VERSION_FILE 파일을 찾을 수 없습니다. version.yml만 업데이트합니다."
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
            echo_success "현재 버전: $version"
            echo "$version"
            ;;
        "increment")
            # 실제 프로젝트 파일에서 현재 버전 가져오기
            local current_version=$(get_version_from_project_file)
            if ! validate_version "$current_version"; then
                echo_error "잘못된 버전 형식: $current_version"
                exit 1
            fi
            
            local new_version=$(increment_patch_version "$current_version")
            echo_info "버전 업데이트: $current_version → $new_version"
            
            # 프로젝트 파일과 version.yml 모두 업데이트
            update_project_file "$new_version"
            echo_success "버전 업데이트 완료: $new_version"
            echo "$new_version"
            ;;
        "set")
            local new_version=$2
            if [ -z "$new_version" ]; then
                echo_error "새 버전을 지정해주세요: ./version-manager.sh set 1.2.3"
                exit 1
            fi
            
            if ! validate_version "$new_version"; then
                echo_error "잘못된 버전 형식: $new_version (x.x.x 형식이어야 합니다)"
                exit 1
            fi
            
            echo_info "버전 설정: $new_version"
            update_project_file "$new_version"
            echo_success "버전 설정 완료: $new_version"
            echo "$new_version"
            ;;
        "validate")
            local version=${2:-$(get_version_from_project_file)}
            if validate_version "$version"; then
                echo_success "유효한 버전 형식입니다: $version"
                exit 0
            else
                echo_error "잘못된 버전 형식입니다: $version"
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