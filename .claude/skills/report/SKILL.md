---
name: report
description: 현재 대화의 explore, plan, implement, review, test-result 결과와 프로젝트 규칙을 바탕으로 최종 보고서를 작성한다.
disable-model-invocation: true
model: sonnet
effort: high
allowed-tools: Read, Glob, Grep, LS, Bash, Write
argument-hint: [ 작업-요약 ]
---

# Report

작업: $ARGUMENTS

이 단계는 현재 대화에 존재하는 이전 단계 결과와 프로젝트 규칙을 바탕으로 최종 보고서를 작성하는 단계다.  
이 단계에서는 구현, 리뷰, 테스트 결과를 종합하여 `.report/` 디렉토리에 규칙에 맞는 보고서 파일을 작성한다.

## 기본 원칙

1. 현재 대화의 `explore`, `plan`, `implement`, `review`, `test-result` 결과를 우선 입력으로 사용한다.
2. 프로젝트 root `CLAUDE.md`를 확인한다.
3. 아래 규칙 파일을 반드시 읽는다.
    - `.claude/rules/40-delivery-and-review.md`
4. 프로젝트 root의 `TODO.md`가 존재하면 반드시 읽고 현재 작업과 연결되는 남은 이슈를 반영한다.
5. 보고서는 프로젝트 규칙에 정의된 위치, 파일명 규칙, 작성 스타일을 따라야 한다.
6. 보고서 작성 시 현재 작업과 직접 관련된 변경 파일만 분석한다.

## 목표

1. 현재 작업의 변경 목적, 구현 내용, 위험 요소, 검증 결과, 남은 이슈를 정리한다.
2. 프로젝트 규칙에 맞는 보고서 파일을 생성한다.
3. 후속 PR 작성이나 작업 공유에 바로 사용할 수 있는 수준으로 정리한다.

## 반드시 확인할 입력

### 1. 현재 대화의 이전 단계 결과

아래를 반드시 참고한다.

- `explore` 결과
- `plan` 결과
- `implement` 결과
- `review` 결과
- `test-result` 결과

### 2. 프로젝트 규칙

반드시 아래를 기준으로 작성한다.

- root `CLAUDE.md`
- `.claude/rules/40-delivery-and-review.md`

### 3. TODO.md

`TODO.md`가 존재하면 아래를 확인한다.

- 이번 작업과 연결되는 남은 이슈
- 후속 작업 필요 사항
- 아직 검증되지 않았거나 미완료 상태인 항목

## 보고서 작성 절차

1. `git status --short`를 한 번만 실행하여 변경 파일 목록을 확인한다.
2. 현재 작업과 직접 관련된 파일만 선별한다.
3. 선별된 파일을 직접 읽고 변경 내용을 분석한다.
4. 이전 단계 결과와 실제 변경 파일을 대조한다.
5. `.claude/rules/40-delivery-and-review.md`의 포맷과 규칙에 맞게 보고서를 작성한다.
6. `.report/` 디렉토리가 없으면 생성한다.
7. 규칙에 맞는 파일명으로 보고서 파일을 저장한다.

## 작성 원칙

- 작성자/작성일 필드를 넣지 않는다.
- AI 도구명은 절대 언급하지 않는다.
- 수동태보다 능동태, 키워드 중심 문장을 우선한다.
- 민감정보가 있으면 규칙에 맞게 마스킹한다.
- 실제로 검증된 내용만 적는다.
- 검증되지 않은 것은 검증되지 않았다고 명시한다.
- 위험 요소가 없으면 `없음`이라고 명시한다.

## 금지 사항

- 현재 작업과 무관한 변경 파일까지 분석 범위를 넓히지 않는다.
- 추가 git 명령을 남용하지 않는다.
- 검증되지 않은 성공을 보고하지 않는다.
- 규칙에 없는 섹션을 임의로 추가하지 않는다.
- 민감정보를 그대로 노출하지 않는다.

## 출력 규칙

반드시 아래 **정확한 구조**로 출력한다.

## Report Result

### Objective

[이번 보고서 작성 목적을 1~2줄로 요약]

### Selected Files For Analysis

- `path/file.ts`
- `path/file.tsx`

### Report File

- 경로: `.report/[YYYYMMDD]_[ISSUE#]_[간단한설명].md`

### Report Summary

- [무엇을 정리했는지]
- [어떤 단계 결과를 반영했는지]

### Included Findings

- [구현 목적]
- [주요 변경 파일]
- [검증 결과]
- [위험 요소]
- [남은 이슈]

### TODO Reflection

- [TODO.md에서 반영한 남은 이슈]
- [후속 작업으로 남긴 내용]

### Final Status

- REPORT_WRITTEN
- REPORT_BLOCKED

### Blocking Reason

- [보고서 작성이 막혔다면 그 이유]