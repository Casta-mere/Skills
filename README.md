# Skills

Global [Claude Code](https://claude.ai/code) custom slash commands.

## Installation

```bash
git clone git@github.com:Casta-mere/Skills.git ~/Dev/Skills
~/Dev/Skills/setup.sh
```

Re-run `setup.sh` after adding new skill files to pick up changes. Other commands can be added directly to `~/.claude/commands/` without conflicting.

## Available Skills

| Skill | Description |
|-------|-------------|
| `/code [path]` | Open a directory in VS Code (defaults to `.`) |
| `/expense <name> <amount> [date] [category] [comment...]` | Log an expense to the Notion Finance Tracker (preview + confirm) |
| `/npm-add <domain> <host> <port> [opts]` | Add a proxy host to Nginx Proxy Manager via its REST API |

### `/npm-add` setup

Copy the example env file and fill in your Nginx Proxy Manager credentials:

```bash
cp ~/Dev/Skills/npm-add.env.example ~/Dev/Skills/npm-add.env
# then edit npm-add.env
```

`npm-add.env` is gitignored so your credentials are never committed.

### `/expense` setup

Requires the **claude.ai Notion** MCP connector — run `/mcp` in Claude Code and authenticate with Notion once. Arguments are order-independent: amount is the number, date defaults to today, category is inferred from the name (and your past entries) when omitted, leftover text becomes the comment. Entries are previewed for confirmation before being written to Notion.
