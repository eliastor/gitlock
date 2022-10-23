# Git-based locking

## Use-cases

- distributed git-only based CI
- terraform backend

## Usage

Copy gitlock to your repository with configured origin repo.

You should be able to push tags to the origin.

Run `./gitlock exec <command> <args...>`

For example:

```
wget https://raw.githubusercontent.com/eliastor/gitlock/master/gitlock
chmod +x gitlock
./gitlock exec uname -a
```

In example above `uname -a` will be executed only after successful lock of repo in origin.
After execution gitlock will release the lock from origin.

To list current locks:

```
./gitlock list-locks
```

To get info about lock:

```
./gitlock show-lock <lock name>
```

To force release of the lock (DANGEROUS).
It must be used only when you are absolutely sure that particular lock is stuck.

```
./gitlock force-unlock <lock name>
```

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
