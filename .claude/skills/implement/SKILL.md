---
name: implement
description: explore와 plan 결과, 프로젝트 규칙, TODO.md, 사용자 요청을 바탕으로 실제 구현을 수행한다.
disable-model-invocation: true
model: sonnet
effort: high
allowed-tools: Read, Glob, Grep, LS, Edit, MultiEdit, Write
argument-hint: [ 작업-요약 ]
---

# Implement

작업: $ARGUMENTS

이 단계는 실제 구현을 수행하는 단계다.  
이 단계에서는 `explore`에서 파악한 프로젝트 구조와 코드 스타일, `plan`에서 정리한 구현 계획, 그리고 현재 대화에 있는 사용자 요청을 바탕으로 실제 코드를 수정한다.

## 기본 원칙

1. 현재 대화에 존재하는 `explore` 결과와 `plan` 결과를 우선 입력으로 사용한다.
2. 프로젝트 root `CLAUDE.md`를 다시 확인한다.
3. 아래 규칙 파일을 반드시 확인한다.
    - `.claude/rules/00-project-overview.md`
    - `.claude/rules/10-architecture-and-boundaries.md`
    - `.claude/rules/20-team-conventions.md`
4. 프로젝트 root의 `TODO.md`를 반드시 읽는다.
5. 구현은 현재 프로젝트 구조, 기존 패턴, 코드 컨벤션에 맞게 진행한다.
6. 추가 탐색은 구현에 필요한 최소 범위에서만 수행한다.
7. 구현이 필요한 경우 실제로 파일을 수정해야 한다.

## 목표

1. `plan`에서 수립한 계획을 현재 프로젝트 구조에 맞게 실제 코드로 구현한다.
2. 기존 구현 패턴과 책임 분리 기준을 유지한다.
3. 불필요한 리팩터링 없이 작업 범위 내에서만 수정한다.
4. 다음 `review`, `test-code`, `test-result` 단계로 자연스럽게 이어질 수 있는 결과를 만든다.

## 반드시 확인할 입력

### 1. 현재 대화의 explore 결과

아래를 다시 참고한다.

- 프로젝트 구조
- 관련 파일
- 기존 패턴
- 코드 스타일
- 제약사항
- 위험 요소

### 2. 현재 대화의 plan 결과

아래를 구현의 직접 입력으로 사용한다.

- 구현 목표
- 변경 대상 파일
- 파일별 책임
- 구현 전략
- 제약사항
- 테스트 전략
- 구현 handoff

### 3. 프로젝트 규칙

반드시 아래를 기준으로 구현한다.

- root `CLAUDE.md`
- `.claude/rules/00-project-overview.md`
- `.claude/rules/10-architecture-and-boundaries.md`
- `.claude/rules/20-team-conventions.md`

### 4. TODO.md

`TODO.md`를 읽고 아래를 반영한다.

- 현재 작업과 직접 연결된 항목
- 구현 범위와 우선순위
- 이미 완료된 항목과 남은 항목의 관계

## 구현 원칙

- 구현은 반드시 현재 프로젝트 구조에 맞아야 한다.
- 기존 패턴이 있으면 우선 재사용한다.
- 새로운 추상화는 정말 필요한 경우에만 도입한다.
- 기능 범위를 넘어서는 변경은 하지 않는다.
- 공용 인프라나 공유 계층은 계획에서 명시되지 않았다면 건드리지 않는다.
- 코드만 탐색하고 끝내면 안 된다. 구현이 필요한 경우 실제 수정까지 진행해야 한다.

## 금지 사항

- 프로젝트 규칙을 무시하지 않는다.
- 현재 작업과 무관한 추측성 리팩터링을 하지 않는다.
- 계획 범위를 벗어난 변경을 하지 않는다.
- 기존 패턴이 있는데 새로운 패턴을 임의로 만들지 않는다.
- 구현이 필요한 상황에서 탐색만 하고 종료하지 않는다.

## 출력 규칙

반드시 아래 **정확한 구조**로 출력한다.

## Implement Result

### Objective

[이번 구현 내용을 1~2줄로 요약]

### Changed Files

- `path/file.ts` — 무엇을 변경했는지
- `path/file.tsx` — 무엇을 변경했는지

### What Was Implemented

- [구현한 내용]
- [추가한 로직]
- [수정한 동작]

### Notable Decisions

- [구현 중 내린 중요한 결정]
- [기존 패턴을 어떻게 재사용했는지]
- [왜 이런 방식으로 구현했는지]

### Scope Check

- [계획 범위 내에서만 수정했는지]
- [제외한 범위가 있다면 무엇인지]

### Follow-up Items

- [남은 이슈가 있다면 그것]
- [이후 작업할 내용이 있다면 작성]

### TODO.md 수정

- 작업한 내용에 대해서 TODO.md 목표 업데이트 및 간단하게 정리한다.
- 앞으로 해야할 작업에 대해서 TODO.md 에 간단하게 정리한다.

## 품질 기준

좋은 implement 결과는 아래를 만족해야 한다.

- plan 결과를 실제 코드 변경으로 연결했다.
- 현재 프로젝트 구조와 책임 경계를 유지했다.
- 기존 패턴과 코드 스타일을 재사용했다.
- 계획 범위를 벗어나지 않았다.
- review와 test 단계가 바로 이어질 수 있다.