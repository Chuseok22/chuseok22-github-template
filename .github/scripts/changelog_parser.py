#!/usr/bin/env python3
# 체인지로그 파싱 스크립트
import re
import json
import html
import sys
import os
from datetime import datetime
from html.parser import HTMLParser
import traceback

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
    """HTML에서 동적으로 카테고리 감지 (레거시 strong 기반)"""
    print("🔍 HTML에서 카테고리 감지 시작 (strong 기반)...")
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


class _SummaryHTMLParser(HTMLParser):
    """CodeRabbit Summary 섹션 전용 HTML 파서

    구조 가정:
    <h2>Summary by CodeRabbit</h2>
    <ul>
      <li>카테고리 제목
        <ul>
          <li>항목 1</li>
          <li>항목 2</li>
        </ul>
      </li>
      ...
    </ul>
    """

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.summary_triggered = False  # h2 텍스트를 만난 후, 다음 ul이 요약 ul
        self.in_summary_list = False    # 요약 ul 내부
        self.summary_ul_depth = 0       # 요약 ul 기준 depth 추적

        self.current_tag_stack = []

        # 카테고리 상태
        self.current_category_title_parts = []
        self.collecting_category_title = False
        self.seen_nested_ul_in_category = False

        # 아이템 상태
        self.collecting_item = False
        self.current_item_parts = []

        # 결과
        self.categories = []  # {"title": str, "items": [str, ...]}

    def handle_starttag(self, tag, attrs):
        self.current_tag_stack.append(tag)

        if tag == 'h2':
            # 다음 handle_data에서 텍스트 확인
            pass

        if tag == 'ul':
            if self.summary_triggered and not self.in_summary_list:
                # h2 직후 첫 번째 ul을 Summary 리스트로 간주
                self.in_summary_list = True
                self.summary_ul_depth = 1
            elif self.in_summary_list:
                self.summary_ul_depth += 1

            # 최상위 li 안에서 처음 등장하는 ul은 카테고리의 항목 영역 시작
            if self.in_summary_list and self.collecting_category_title and not self.seen_nested_ul_in_category:
                self.seen_nested_ul_in_category = True

        if tag == 'li' and self.in_summary_list:
            # summary_ul_depth == 1 인 상태에서 만나는 li는 카테고리 시작
            if self.summary_ul_depth == 1:
                # 카테고리 새로 시작
                self.current_category_title_parts = []
                self.collecting_category_title = True
                self.seen_nested_ul_in_category = False
                self.categories.append({"title": "", "items": []})
            elif self.summary_ul_depth >= 2 and self.seen_nested_ul_in_category:
                # 항목 수집 시작
                self.collecting_item = True
                self.current_item_parts = []

    def handle_endtag(self, tag):
        if not self.current_tag_stack:
            return

        # li 종료 처리 먼저
        if tag == 'li' and self.in_summary_list:
            if self.collecting_item:
                # 아이템 마감
                item_text = self._normalize_text(''.join(self.current_item_parts))
                if item_text:
                    self.categories[-1]["items"].append(item_text)
                self.collecting_item = False
                self.current_item_parts = []
            elif self.collecting_category_title:
                # 카테고리 타이틀 마감 (nested ul 전에 나온 텍스트만)
                title_text = self._normalize_text(''.join(self.current_category_title_parts))
                if title_text:
                    self.categories[-1]["title"] = title_text
                self.collecting_category_title = False
                self.current_category_title_parts = []

        if tag == 'ul':
            if self.in_summary_list:
                self.summary_ul_depth -= 1
                if self.summary_ul_depth == 0:
                    # Summary 리스트 종료
                    self.in_summary_list = False
                    self.summary_triggered = False

        # h2 종료는 별도 처리 불필요

        # 스택 팝
        if self.current_tag_stack and self.current_tag_stack[-1] == tag:
            self.current_tag_stack.pop()
        elif self.current_tag_stack:
            # 비정상 구조 방어적 팝
            self.current_tag_stack.pop()

    def handle_data(self, data):
        text = self._normalize_text(data)
        if not text:
            return

        # h2 텍스트에서 Summary by CodeRabbit 감지
        if self.current_tag_stack and self.current_tag_stack[-1] == 'h2':
            if 'summary by coderabbit' in text.lower():
                self.summary_triggered = True
            return

        # Summary 리스트 내 수집 로직
        if self.in_summary_list:
            if self.collecting_item:
                self.current_item_parts.append(text)
            elif self.collecting_category_title and not self.seen_nested_ul_in_category:
                # nested ul이 나오기 전까지의 텍스트가 카테고리 제목
                self.current_category_title_parts.append(text)

    @staticmethod
    def _normalize_text(text: str) -> str:
        return html.unescape(text).strip()


def parse_summary_by_coderabbit(html_content: str) -> dict:
    """Summary by CodeRabbit 섹션을 파싱하여 {safe_key: [items]} 딕셔너리 반환"""
    parser = _SummaryHTMLParser()
    parser.feed(html_content)

    detected = {}
    for idx, cat in enumerate(parser.categories):
        title = (cat.get("title") or "").strip()
        items = [it for it in (cat.get("items") or []) if it]
        if not title and not items:
            continue
        safe_key = re.sub(r'[^a-zA-Z0-9가-힣]', '_', title.lower()).strip('_') if title else f"category_{idx}"
        if not safe_key:
            safe_key = f"category_{idx}"
        detected[safe_key] = {
            'title': title or f"Category {idx}",
            'items': items
        }

    if not detected:
        print("⚠️ Summary by CodeRabbit 섹션을 파싱하지 못했습니다 (빈 결과)")
    else:
        print(f"✅ Summary 카테고리 {len(detected)}개 감지")

    return detected

def main():
    version = os.environ.get('VERSION')
    project_type = os.environ.get('PROJECT_TYPE')
    today = os.environ.get('TODAY')
    pr_number = int(os.environ.get('PR_NUMBER'))
    timestamp = os.environ.get('TIMESTAMP')

    try:
        with open('summary_section.html', 'r', encoding='utf-8') as f:
            html_content = f.read()

        # 1) CodeRabbit Summary 전용 파싱 시도
        categories = parse_summary_by_coderabbit(html_content)
        # 2) 폴백: 레거시 strong 기반 파싱 시도
        if not categories:
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

        # 동적 카테고리를 parsed_changes에 추가 (title + items 구조)
        for key, value in categories.items():
            new_release["parsed_changes"][key] = value

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
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
