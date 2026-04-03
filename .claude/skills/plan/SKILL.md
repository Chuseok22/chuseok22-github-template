---
name: plan
description: explore 결과, 프로젝트 규칙, TODO.md, 사용자 요청을 바탕으로 현재 프로젝트 구조에 맞는 구현 계획을 짧고 실행 가능하게 정리한다.
disable-model-invocation: true
model: opus
effort: max
allowed-tools: Read, Glob, Grep, LS
argument-hint: [ 작업-요약 ]
---

# Plan

작업: $ARGUMENTS

이 단계는 구현을 수행하는 단계가 아니다.  
이 단계의 목적은 `explore` 결과와 프로젝트 규칙, `TODO.md`, 사용자 요청을 바탕으로 **사용자가 이해할 수 있는 짧은 계획 요약**과 **다음 `implement` 단계가 바로 사용할 수 있는 구현 handoff**를 만드는 것이다.

## 기본 원칙

1. 현재 대화에 존재하는 `explore` 결과를 우선 입력으로 사용한다.
2. 프로젝트 root `CLAUDE.md`를 확인한다.
3. 아래 규칙 파일을 반드시 확인한다.
    - `.claude/rules/00-project-overview.md`
    - `.claude/rules/10-architecture-and-boundaries.md`
    - `.claude/rules/20-team-conventions.md`
4. 프로젝트 root `TODO.md`를 반드시 읽는다.
5. 사용자 요청과 `TODO.md`를 함께 고려하여 현재 프로젝트 구조에 맞는 구현 계획을 세운다.
6. 불필요한 리팩터링이나 범위 확장은 계획에 포함하지 않는다.

## 반드시 확인할 내용

### 1. explore 결과

- 작업 목적
- 관련 파일
- 기존 패턴
- 구조 / 책임 경계
- 제약사항
- 위험 / 미확인 사항

### 2. TODO.md

- 현재 작업과 직접 연결된 TODO 항목
- 이번 계획에 포함해야 할 범위
- 제외해야 할 범위

### 3. 사용자 요청

- 반드시 구현해야 하는 것
- 구현하지 말아야 하는 것
- 우선순위
- 기대 결과

## 금지 사항

- 파일을 수정하지 않는다.
- 구현 코드를 작성하지 않는다.
- 최종 코드 예시를 출력하지 않는다.
- 기존 패턴이 있는데 새로운 구조를 우선 제안하지 않는다.
- 근거 없이 계획을 확정하지 않는다.
- 불필요하게 긴 계획 문서를 출력하지 않는다.

## 출력 규칙

반드시 아래 **정확한 구조**로 출력한다.

## Plan Result

### User Summary

- 목표: [이번 작업 목표를 1줄로 요약]
- 변경 범위: [핵심 변경 범위를 1~2줄로 요약]
- 구현 방향: [어떤 방식으로 구현할지 1~2줄로 요약]
- 주의사항: [사용자가 알아야 할 핵심 제약 또는 위험 1~2개]

### Files To Change

- `path/file.ts` — 변경 이유
- `path/file.tsx` — 변경 이유
- 필요한 경우만 최대 7개까지 작성

### Constraints

- [반드시 지켜야 하는 프로젝트 규칙]
- [구조 / 책임 경계 제약]
- [코드 스타일 / 팀 규칙 제약]

### Risks

- [구현 전에 주의할 위험]
- [미확인 사항]

### Open Questions

- [계획 또는 구현 전에 확인이 필요한 질문이 있다면 작성]
- [없으면 `없음`이라고 작성]

### Implementation Handoff

- **Goal**: [구현 목표]
- **Scope**: [이번 구현에서 다뤄야 할 범위]
- **Files**: [정확히 수정해야 할 파일]
- **Responsibilities**: [파일별 책임]
- **Patterns**: [재사용할 패턴]
- **Constraints**: [구현 시 지켜야 할 제약]
- **Verification**: [이후 확인해야 할 테스트 / 검증]
- **Risks / Open Questions**: [주의사항]

## 출력 제한

- `User Summary`는 사용자가 빠르게 이해할 수 있도록 짧게 작성한다.
- 나머지 섹션은 다음 `implement` 단계가 바로 사용할 수 있도록 AI 친화적으로 작성한다.
- 각 섹션은 짧고 압축적으로 작성한다.
- 불필요한 설명을 길게 쓰지 않는다.
- 파일 목록은 핵심 파일만 작성한다.
- 전체 결과는 사용자에게는 간결해야 하고, implement 단계에는 충분해야 한다.