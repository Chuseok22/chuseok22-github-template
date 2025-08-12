#!/usr/bin/env python3
"""
changelog_manager.py

통합 체인지로그 매니저 스크립트.

서브커맨드:
  - update-from-summary: CodeRabbit Summary HTML을 파싱하여 CHANGELOG.json 갱신
  - generate-md        : CHANGELOG.json을 기반으로 CHANGELOG.md 재생성
  - export             : 특정 버전의 릴리즈 노트를 생성하여 stdout 또는 파일로 저장

사용 예:
  python3 changelog_manager.py update-from-summary
  python3 changelog_manager.py generate-md
  python3 changelog_manager.py export --version 0.0.2 --output release_notes.txt
"""

from __future__ import annotations

import argparse
import html
import json
import os
import re
import sys
import traceback
from html.parser import HTMLParser


# ----------------------------- 공통 유틸 -----------------------------

def _normalize_text(text: str) -> str:
    return html.unescape(text).strip()


# ------------------------- Summary HTML 파서 -------------------------

class _SummaryHTMLParser(HTMLParser):
    """CodeRabbit Summary 섹션 전용 HTML 파서"""

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.summary_triggered = False
        self.in_summary_list = False
        self.summary_ul_depth = 0
        self.current_tag_stack: list[str] = []

        # 카테고리 상태
        self.current_category_title_parts: list[str] = []
        self.collecting_category_title = False
        self.seen_nested_ul_in_category = False

        # 아이템 상태
        self.collecting_item = False
        self.current_item_parts: list[str] = []

        # 결과
        self.categories: list[dict] = []  # {title: str, items: [str]}

    def handle_starttag(self, tag, attrs):
        self.current_tag_stack.append(tag)
        if tag == 'ul':
            if self.summary_triggered and not self.in_summary_list:
                self.in_summary_list = True
                self.summary_ul_depth = 1
            elif self.in_summary_list:
                self.summary_ul_depth += 1
            if self.in_summary_list and self.collecting_category_title and not self.seen_nested_ul_in_category:
                self.seen_nested_ul_in_category = True
        if tag == 'li' and self.in_summary_list:
            if self.summary_ul_depth == 1:
                self.current_category_title_parts = []
                self.collecting_category_title = True
                self.seen_nested_ul_in_category = False
                self.categories.append({"title": "", "items": []})
            elif self.summary_ul_depth >= 2 and self.seen_nested_ul_in_category:
                self.collecting_item = True
                self.current_item_parts = []

    def handle_endtag(self, tag):
        if not self.current_tag_stack:
            return
        if tag == 'li' and self.in_summary_list:
            if self.collecting_item:
                item_text = _normalize_text(''.join(self.current_item_parts))
                if item_text:
                    self.categories[-1]["items"].append(item_text)
                self.collecting_item = False
                self.current_item_parts = []
            elif self.collecting_category_title:
                title_text = _normalize_text(''.join(self.current_category_title_parts))
                if title_text:
                    self.categories[-1]["title"] = title_text
                self.collecting_category_title = False
                self.current_category_title_parts = []
        if tag == 'ul' and self.in_summary_list:
            self.summary_ul_depth -= 1
            if self.summary_ul_depth == 0:
                self.in_summary_list = False
                self.summary_triggered = False
        if self.current_tag_stack and self.current_tag_stack[-1] == tag:
            self.current_tag_stack.pop()
        elif self.current_tag_stack:
            self.current_tag_stack.pop()

    def handle_data(self, data):
        text = _normalize_text(data)
        if not text:
            return
        if self.current_tag_stack and self.current_tag_stack[-1] == 'h2':
            if 'summary by coderabbit' in text.lower():
                self.summary_triggered = True
            return
        if self.in_summary_list:
            if self.collecting_item:
                self.current_item_parts.append(text)
            elif self.collecting_category_title and not self.seen_nested_ul_in_category:
                self.current_category_title_parts.append(text)


def _parse_summary_by_coderabbit(html_content: str) -> dict:
    parser = _SummaryHTMLParser()
    parser.feed(html_content)
    detected: dict[str, dict] = {}
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
            'items': items,
        }
    return detected


def _detect_categories_legacy(html_content: str) -> dict:
    detected: dict[str, dict] = {}
    strong_texts = re.findall(r'<strong[^>]*>([^<]+)</strong>', html_content, re.IGNORECASE)
    for strong_text in strong_texts:
        clean_text = strong_text.strip()
        # 섹션 이후 ul > li 텍스트 추출
        section_match = None
        for pattern in [
            f'<strong[^>]*>{re.escape(clean_text)}[^<]*</strong>',
            f'<li[^>]*><strong[^>]*>{re.escape(clean_text)}[^<]*</strong>',
            f'<p[^>]*><strong[^>]*>{re.escape(clean_text)}[^<]*</strong></p>',
        ]:
            section_match = re.search(pattern, html_content, re.IGNORECASE)
            if section_match:
                break
        if not section_match:
            continue
        after_section = html_content[section_match.end():]
        ul_match = re.search(r'<ul[^>]*>(.*?)</ul>', after_section, re.DOTALL)
        if not ul_match:
            continue
        ul_content = ul_match.group(1)
        li_items = re.findall(r'<li[^>]*>(.*?)</li>', ul_content, re.DOTALL)
        items = []
        for item in li_items:
            clean = re.sub(r'<[^>]*>', '', item)
            clean = html.unescape(clean).strip()
            if clean:
                items.append(clean)
        if items:
            safe_key = re.sub(r'[^a-zA-Z0-9가-힣]', '_', clean_text.lower()).strip('_') or f"category_{len(detected)}"
            detected[safe_key] = {'title': clean_text, 'items': items}
    return detected


# ------------------------ 서브커맨드 구현부 ------------------------

def cmd_update_from_summary() -> int:
    """summary_section.html과 환경변수로부터 CHANGELOG.json을 갱신."""
    version = os.environ.get('VERSION')
    project_type = os.environ.get('PROJECT_TYPE')
    today = os.environ.get('TODAY')
    pr_number_raw = os.environ.get('PR_NUMBER')
    timestamp = os.environ.get('TIMESTAMP')
    try:
        pr_number = int(pr_number_raw) if pr_number_raw is not None else None
    except ValueError:
        pr_number = None

    try:
        with open('summary_section.html', 'r', encoding='utf-8') as f:
            html_content = f.read()

        categories = _parse_summary_by_coderabbit(html_content)
        if not categories:
            categories = _detect_categories_legacy(html_content)

        with open('summary_section.html', 'r', encoding='utf-8') as f:
            raw_summary = re.sub(r'<[^>]*>', '', f.read()).strip()

        new_release = {
            "version": version,
            "project_type": project_type,
            "date": today,
            "pr_number": pr_number,
            "raw_summary": raw_summary,
            "parsed_changes": {},
        }
        for key, value in (categories or {}).items():
            new_release["parsed_changes"][key] = value

        try:
            with open('CHANGELOG.json', 'r', encoding='utf-8') as f:
                changelog_data = json.load(f)
        except (FileNotFoundError, json.JSONDecodeError):
            changelog_data = {
                "metadata": {
                    "lastUpdated": timestamp,
                    "currentVersion": version,
                    "projectType": project_type,
                    "totalReleases": 0,
                },
                "releases": [],
            }

        changelog_data["metadata"]["lastUpdated"] = timestamp
        changelog_data["metadata"]["currentVersion"] = version
        changelog_data["metadata"]["projectType"] = project_type
        changelog_data["metadata"]["totalReleases"] = len(changelog_data.get("releases", [])) + 1

        changelog_data.setdefault("releases", []).insert(0, new_release)

        with open('CHANGELOG.json', 'w', encoding='utf-8') as f:
            json.dump(changelog_data, f, indent=2, ensure_ascii=False)

        print("✅ CHANGELOG.json 업데이트 완료!")
        return 0
    except Exception as e:
        print(f"❌ update-from-summary 실패: {e}")
        traceback.print_exc()
        return 1


def cmd_generate_md() -> int:
    """CHANGELOG.json을 기반으로 CHANGELOG.md 재생성."""
    try:
        with open('CHANGELOG.json', 'r', encoding='utf-8') as f:
            data = json.load(f)

        with open('CHANGELOG.md', 'w', encoding='utf-8') as f:
            f.write("# Changelog\n\n")

            metadata = data.get('metadata', {})
            current_version = metadata.get('currentVersion', 'Unknown')
            last_updated = metadata.get('lastUpdated', 'Unknown')

            f.write(f"**현재 버전:** {current_version}  \n")
            f.write(f"**마지막 업데이트:** {last_updated}  \n\n")
            f.write("---\n\n")

            for release in data.get('releases', []):
                f.write(f"## [{release.get('version')}] - {release.get('date')}\n\n")
                pr_number = release.get('pr_number')
                if pr_number is not None:
                    f.write(f"**PR:** #{pr_number}  \n\n")

                parsed = release.get('parsed_changes') or {}
                for _, items in parsed.items():
                    if not items:
                        continue
                    if isinstance(items, dict) and 'items' in items:
                        actual_items = items.get('items') or []
                        title = items.get('title') or ''
                    else:
                        actual_items = items
                        title = _normalize_text(_)
                    f.write(f"**{title}**\n")
                    for item in actual_items:
                        f.write(f"- {item}\n")
                    f.write("\n")

                f.write("---\n\n")

        print("✅ CHANGELOG.md 재생성 완료!")
        return 0
    except Exception as e:
        print(f"❌ CHANGELOG.md 생성 실패: {e}")
        return 1


def cmd_export_release_notes(version: str, output_path: str | None) -> int:
    """CHANGELOG에서 해당 버전 릴리즈 노트를 생성."""
    notes_text = ""
    # 1) CHANGELOG.json 시도
    try:
        if os.path.isfile('CHANGELOG.json'):
            with open('CHANGELOG.json', 'r', encoding='utf-8') as f:
                changelog = json.load(f)
            releases = changelog.get('releases') or []
            matched = next((r for r in releases if str(r.get('version')) == str(version)), None)
            if matched:
                header = f"버전 {matched.get('version')} 업데이트\n\n"
                parsed_changes = matched.get('parsed_changes') or {}
                if parsed_changes:
                    category_blocks: list[str] = []
                    for _, value in parsed_changes.items():
                        title = (value.get('title') or '').strip()
                        items = [it for it in (value.get('items') or []) if it]
                        if title and items:
                            block = "**" + title + "**\n" + "\n".join("- " + it for it in items)
                            category_blocks.append(block)
                    body = "\n\n".join(category_blocks) if category_blocks else (matched.get('raw_summary') or '').strip()
                else:
                    body = (matched.get('raw_summary') or '').strip()
                notes_text = (header + (body or "")).strip()
    except Exception:
        pass

    # 2) CHANGELOG.md 폴백
    if not notes_text and os.path.isfile('CHANGELOG.md'):
        try:
            with open('CHANGELOG.md', 'r', encoding='utf-8') as f:
                md = f.read()
            pattern = re.compile(rf"^## \[{re.escape(str(version))}\].*$", re.MULTILINE)
            m = pattern.search(md)
            if m:
                start = m.end()
                next_m = re.search(r"^## \\[", md[start:], re.MULTILINE)
                section = md[start: start + next_m.start()] if next_m else md[start:]
                body = section.strip()
                notes_text = (f"버전 {version} 업데이트\n\n" + body).strip()
        except Exception:
            pass

    # 3) 최종 폴백
    if not notes_text:
        notes_text = f"버전 {version} 업데이트\n앱 안정성 및 사용자 경험이 개선되었습니다."

    if output_path:
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(notes_text)
    else:
        sys.stdout.write(notes_text + "\n")
    return 0


# ------------------------------- CLI -------------------------------

def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog='changelog_manager', add_help=True)
    sub = parser.add_subparsers(dest='command', required=True)

    sub.add_parser('update-from-summary')
    sub.add_parser('generate-md')
    p_export = sub.add_parser('export')
    p_export.add_argument('--version', required=True)
    p_export.add_argument('--output')

    args = parser.parse_args(argv)

    if args.command == 'update-from-summary':
        return cmd_update_from_summary()
    if args.command == 'generate-md':
        return cmd_generate_md()
    if args.command == 'export':
        return cmd_export_release_notes(args.version, args.output)
    return 2


if __name__ == '__main__':
    sys.exit(main())


