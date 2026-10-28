---
allowed-tools: ToolSearch, mcp__claude_ai_Notion__notion-fetch, mcp__claude_ai_Notion__notion-query-data-sources, mcp__claude_ai_Notion__notion-create-pages
description: Log an expense to the Notion Finance Tracker (yearly Accounting page)
---

## Your task

The user invoked `/expense` with the following arguments: $ARGUMENTS

Add one or more expense entries to the Notion Finance Tracker. Preview first, create only after the user confirms.

## Step 0 — Load Notion tools

Load via ToolSearch: `mcp__claude_ai_Notion__notion-query-data-sources`, `mcp__claude_ai_Notion__notion-create-pages` (and `notion-fetch` only if year discovery is needed, see Step 3). If the Notion MCP server is not connected, tell the user to run `/mcp` and select **claude.ai Notion**, then stop.

## Step 1 — Parse arguments

Tokens are order-independent. Classify each token:

- **Amount** (required): a number, optionally prefixed with `¥`. If missing, ask the user for it and stop.
- **Date**: `YYYY-MM-DD`, `MM-DD`, `M/D`, `今天`/`today`, `昨天`/`yesterday`, `前天`. No year → current year. Omitted entirely → today. Get today with `date +%F` if unsure.
- **Category**: token matching a category name (case-insensitive) or alias:
  | Category | Aliases |
  |---|---|
  | Food | food, 餐饮, 吃饭, 吃的 |
  | Dine Out | dineout, dine-out, 下馆子 |
  | Grocery | grocery, 买菜 |
  | Transportation | transport, 交通, 打车 |
  | Entertainment | ent, 娱乐 |
  | Game | game, 游戏 |
  | Subscription | sub, 订阅, 会员 |
  | Rent/Debt/Bill | rent, bill, 房租, 账单 |
  | Saving | saving, 存钱 |
  | Clothes | clothes, 衣服 |
  | Medical | medical, 医疗 |
  | Study | study, 学习 |
  | Hotel | hotel, 酒店 |
  | Gift | gift, 礼品, 送礼 |
- **Name**: the first remaining token (usually a Chinese merchant/item name like 酱香饼, 盒马, 话费).
- **comment**: any leftover text after Name is taken.

**Batch**: entries may be separated by newlines or `;` / `；`. Parse each independently; shared trailing options do NOT carry over.

## Step 2 — Infer category when omitted

Priority order:

1. **History**: query the year's Expense data source for the same Name and reuse the most recent Category:
   ```sql
   SELECT "Category", "date:Date:start" FROM "<expense collection url>"
   WHERE "Name" = ? AND "Category" IS NOT NULL
   ORDER BY "date:Date:start" DESC LIMIT 3
   ```
2. **Semantic guess** using the user's observed conventions:
   - Meals, restaurants, snacks, drinks, bakeries, and supermarkets (盒马, 山姆) → `Food` — the user uses Food broadly; `Dine Out` and `Grocery` are rarely used, prefer Food unless explicitly told
   - 话费 / 水费 / 电费 / 房租 / 还款 → `Rent/Debt/Bill`
   - App/service subscriptions & memberships (Apple Music, Apple Care, DeepSeek, 医保) → `Subscription`
   - 彩票, movies, shows, events → `Entertainment`
   - Game purchases / in-game spending → `Game`
   - 小荷包 / transfers to savings → `Saving`
   - Taxi / metro / train / fuel → `Transportation`
   - Clothing → `Clothes`; medicine/hospital → `Medical`; courses/books → `Study`; lodging → `Hotel`
   - `Gift` = presents for parents/relatives/friends only (中秋/春节礼盒, 送礼). Gifts between the user and their girlfriend (Jellycat etc.) stay `Entertainment`. Never assign `Gift` on your own — when the recipient is unclear, ask the user. 红包 stays `Entertainment`. (Option added 2026-10-14 on the 2026 DB only; older years lack it.)
3. Mark every inferred category as `(inferred)` in the preview and final report. Category may only be one of the 14 exact option names above — never invent a new option.

## Step 3 — Resolve year → database

The Accounting page has one page per year, each with its OWN database IDs (duplicated from a template).

**2026 (hardcoded):**
- Expense data source: `collection://64656e86-c0b2-8340-add4-070f70360a1c`
- Month page URLs (for the `Month` relation), Jan→Dec:
  1. `https://app.notion.com/6e856e86c0b2833bab1b810399bac088`
  2. `https://app.notion.com/dc156e86c0b283cfa15b8184edafe52a`
  3. `https://app.notion.com/07d56e86c0b28385abc081d6474abfed`
  4. `https://app.notion.com/f1056e86c0b2832b8bd1017d36a30c22`
  5. `https://app.notion.com/2dd56e86c0b2836fbce80189ce2d9fba`
  6. `https://app.notion.com/dd256e86c0b28321bad481e2cf59f8db`
  7. `https://app.notion.com/65256e86c0b283ad9aed01a3154b8188`
  8. `https://app.notion.com/ae056e86c0b2825ca7a381e8abb9556b`
  9. `https://app.notion.com/3e556e86c0b2832092c8816052abece9`
  10. `https://app.notion.com/92056e86c0b2820b8202010cb564761d`
  11. `https://app.notion.com/23356e86c0b28265802781ae6235586b`
  12. `https://app.notion.com/24656e86c0b28297b39701bc67b81c12`

**Any other year** (discovery procedure):
1. Fetch the Accounting page `6a52559cf99445888f9863b8b2651904` and find the year's child page.
2. Fetch the year page; the Expense inline database is the one with icon `arrow-up_blue` — read its `data-source-url` (`collection://...`). The Total database has icon `currency_red`.
3. Query the Total data source for `url, "Name", "Month #"` to get the 12 month page URLs.
4. After a successful add, offer to append the discovered year mapping to this skill file (`~/Dev/Skills/expense.md`) so future calls skip discovery.

If the year page does not exist yet, tell the user and offer to duplicate the `Template` page (`2e056e86c0b28097966dfb7262ec43be`) via `notion-duplicate-page` and rename it — do NOT do this without confirmation.

## Step 4 — Preview and confirm (mandatory)

Show the parsed entries as a table:

| Name | Amount | Date | Category | Month | comment |
|---|---|---|---|---|---|
| 酱香饼 | ¥19.5 | 2026-07-06 | Food (inferred) | July | — |

Then use AskUserQuestion: **Add** / **Cancel** (user can also reply with corrections — re-preview after applying them). **NEVER create pages before the user confirms.**

## Step 5 — Create

Call `notion-create-pages` with `parent: {"data_source_id": "<year expense collection id>"}` and one page per entry (batch in a single call):

```json
{
  "properties": {
    "Name": "酱香饼",
    "Amount": 19.5,
    "Category": "Food",
    "date:Date:start": "2026-07-06",
    "Month": "[\"<month page url>\"]",
    "comment": "..."
  }
}
```

- `Month` is a JSON string containing a single-element array with the month page URL matching the entry's date. It is **required** — the monthly rollups in the Total database depend on it.
- Omit `comment` if empty. Do not set page content or icon.

## Step 6 — Report

Print one line per created entry: Name, ¥Amount, Date, Category (re-flag `(inferred)`), Month, and the created page URL. On API failure, print the full error.

## Notes

- Amounts are CNY (yuan).
- Notion connector: claude.ai Notion MCP (authenticate via `/mcp` if tools are missing).
- Income logging is out of scope — the Income database is a separate data source per year.
