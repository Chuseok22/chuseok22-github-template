#!/usr/bin/env python3
# 체인지로그 파싱 스크립트
import re
import json
import html
import sys
import os
from datetime import datetime

def extract_items_from_section(html_content, section_title):
    """특정 섹션의 아이템들을 추출"""
    print(f"📋 '{section_title}' 섹션에서 아이템 추출 중...")

    # 다양한 패턴으로 섹션 찾기
    patterns = [
        f'<strong[^>]*>{re.escape(section_title)}[^<]*</strong>',
        f'<li[^>]*><strong[^>]*>{re.escape(section_title)}[^<]*</strong>',
        f'<p[^>]*><strong[^>]*>{re.escape(section_title)}[^<]*</strong></p>'
    ]

    section_match = None
    for pattern in patterns:
        section_match = re.search(pattern, html_content, re.IGNORECASE)
        if section_match:
            print(f"✅ 패턴 매치: {pattern[:50]}...")
            break

    if not section_match:
        print(f"❌ '{section_title}' 섹션을 찾을 수 없습니다")
        return []

    # 섹션 이후의 ul 태그 찾기
    after_section = html_content[section_match.end():]
    ul_match = re.search(r'<ul[^>]*>(.*?)</ul>', after_section, re.DOTALL)

    if not ul_match:
        print(f"❌ '{section_title}' 섹션 이후 ul 태그를 찾을 수 없습니다")
        return []

    # li 태그들에서 텍스트 추출
    ul_content = ul_match.group(1)
    li_items = re.findall(r'<li[^>]*>(.*?)</li>', ul_content, re.DOTALL)

    items = []
    for item in li_items:
        clean_text = re.sub(r'<[^>]*>', '', item)
        clean_text = html.unescape(clean_text).strip()
        if clean_text:
            items.append(clean_text)

    return items

def detect_categories(html_content):
    """HTML에서 동적으로 카테고리 감지"""
    print("🔍 HTML에서 카테고리 감지 시작...")
    detected_categories = {}

    # strong 태그 안의 카테고리 제목들 찾기
    strong_texts = re.findall(r'<strong[^>]*>([^<]+)</strong>', html_content, re.IGNORECASE)

    for strong_text in strong_texts:
        clean_text = strong_text.strip()
        items = extract_items_from_section(html_content, clean_text)
        if items:
            safe_key = re.sub(r'[^a-zA-Z0-9가-힣]', '_', clean_text.lower()).strip('_')
            if not safe_key:
                safe_key = f"category_{len(detected_categories)}"

            detected_categories[safe_key] = {
                'title': clean_text,
                'items': items
            }

    return detected_categories

def main():
    version = os.environ.get('VERSION')
    project_type = os.environ.get('PROJECT_TYPE')
    today = os.environ.get('TODAY')
    pr_number = int(os.environ.get('PR_NUMBER'))
    timestamp = os.environ.get('TIMESTAMP')

    try:
        with open('summary_section.html', 'r', encoding='utf-8') as f:
            html_content = f.read()

        categories = detect_categories(html_content)

        # Raw summary 읽기
        with open('summary_section.html', 'r', encoding='utf-8') as f:
            raw_summary = re.sub(r'<[^>]*>', '', f.read()).strip()

        # 새로운 릴리즈 엔트리 생성
        new_release = {
            "version": version,
            "project_type": project_type,
            "date": today,
            "pr_number": pr_number,
            "raw_summary": raw_summary,
            "parsed_changes": {}
        }

        # 동적 카테고리를 parsed_changes에 추가
        for key, value in categories.items():
            new_release["parsed_changes"][key] = value["items"]

        # CHANGELOG.json 업데이트
        try:
            with open('CHANGELOG.json', 'r', encoding='utf-8') as f:
                changelog_data = json.load(f)
        except (FileNotFoundError, json.JSONDecodeError):
            changelog_data = {
                "metadata": {
                    "lastUpdated": timestamp,
                    "currentVersion": version,
                    "projectType": project_type,
                    "totalReleases": 0
                },
                "releases": []
            }

        # 메타데이터 업데이트
        changelog_data["metadata"]["lastUpdated"] = timestamp
        changelog_data["metadata"]["currentVersion"] = version
        changelog_data["metadata"]["projectType"] = project_type
        changelog_data["metadata"]["totalReleases"] = len(changelog_data["releases"]) + 1

        # 새 릴리즈를 맨 앞에 추가
        changelog_data["releases"].insert(0, new_release)

        # 파일 저장
        with open('CHANGELOG.json', 'w', encoding='utf-8') as f:
            json.dump(changelog_data, f, indent=2, ensure_ascii=False)

        print("✅ CHANGELOG.json 업데이트 완료!")

    except Exception as e:
        print(f"❌ 파싱 오류: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
