#!/usr/bin/env python3
# 체인지로그 마크다운 생성 스크립트
import json
import sys

try:
    with open('CHANGELOG.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    with open('CHANGELOG.md', 'w', encoding='utf-8') as f:
        f.write("# Changelog\n\n")

        # 메타데이터 정보 추가
        metadata = data.get('metadata', {})
        current_version = metadata.get('currentVersion', 'Unknown')
        last_updated = metadata.get('lastUpdated', 'Unknown')

        f.write(f"**현재 버전:** {current_version}  \n")
        f.write(f"**마지막 업데이트:** {last_updated}  \n\n")
        f.write("---\n\n")

        for release in data['releases']:
            f.write(f"## [{release['version']}] - {release['date']}\n\n")

            # PR 번호 표시
            if 'pr_number' in release:
                f.write(f"**PR:** #{release['pr_number']}  \n\n")

            for category_key, items in release['parsed_changes'].items():
                if items:
                    if isinstance(items, dict) and 'items' in items:
                        actual_items = items['items']
                        title = items['title']
                    else:
                        actual_items = items
                        title = category_key.replace('_', ' ').title()

                    f.write(f"**{title}**\n")

                    for item in actual_items:
                        f.write(f"- {item}\n")
                    f.write("\n")

            f.write("---\n\n")

    print("✅ CHANGELOG.md 재생성 완료!")

except Exception as e:
    print(f"❌ CHANGELOG.md 생성 실패: {e}")
    exit(1)
