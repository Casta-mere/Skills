---
allowed-tools: Bash(code:*)
description: Open a directory in VS Code (defaults to the current directory)
---

Open a directory in VS Code. If an argument is provided, open that path relative to the current directory. Otherwise open the current directory.

```bash
code ${1:-.}
```
