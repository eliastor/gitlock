# Git-based locking

## Use-cases

- distributed git-only based CI
- terraform backend

## Flow

```mermaid
sequenceDiagram
    participant user1
    participant user2
    participant user3
    participant repo
    user1->>repo: pull tags
    user2->>repo: pull tags
    repo->>user1: tags
    repo->>user2: tags
    user1->>user1: make tag and notes/branches/locks
    user2->>user2: make tag and notes/branches/locks
    user1->repo: push tags
    activate repo
    user2->repo: push tags
    activate repo
    user1->>repo: pull tags
    user2->>repo: pull tags
    user1->>user1: compare tags:<br/> win:<br/>earlier time, higher priority, greater hash number, etc.
    user2->>user2: compare tags: lost
    user1->>repo: push notes/branches/locks
    activate user1
    user2->>repo: remove tags
    deactivate repo
    user1->user1: background work
    user1->user1: remove tags
    deactivate user1
    user1->>repo: remove tags
    deactivate repo

```
