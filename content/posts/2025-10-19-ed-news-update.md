---
title: 'An update to the Ed News service'
date: '2025-10-19T14:37:03-07:00'

slug: ed-news-update
tags: ["Ed News", "Vibe Coding"]

draft: false
---

For the past few years I've run [Ed News](https://ebardelli.com/ed-news/), a small site that aggregates education publications so I can stay informed without visiting multiple sources. The original site used the [Pluto gem](https://github.com/feedreader/pluto) to fetch RSS feeds and generate a static site. It worked well, but adding new features was difficult, so I decided to rebuild the backend.

## The New Release

With help from GitHub Copilot, I rewrote the backend to be more robust and flexible about where it pulls news from. The new version is live on [Ed News](https://ebardelli.com/ed-news/). It was a fun, low-stakes project and a good way to practice [*vibe coding*](https://x.com/karpathy/status/1886192184808149383): LLM-assisted, exploratory, low-pressure coding where the focus is on learning and tinkering rather than perfection.

The backend is now Python-based. The `ednews` module is the core: it pulls feeds, enriches research article metadata via CrossRef (adding structured information like DOIs, journal names, and publication dates), computes embeddings, and builds the static site. Currently, the service aggregates about 50 education-focused feeds and maintains a database of thousands of articles and headlines, making it a comprehensive resource for staying on top of the field.

The article recommendation engine is one of the features made possible with this rewrite. Technically, it's quite simple. It just uses a single SQL query over [Nomic AI's pre-computed embeddings](https://www.nomic.ai/blog/posts/nomic-embed-text-v1) to find semantically related articles. Under the hood, it uses [sqlite_vec](https://github.com/asg017/sqlite-vec) to interact with the vector embeddings. It is surprising to see how much SQLite can do with plain old SQL.

## Access to the Data

I also decided to share the item database through Parquet files so that the publication data is explorable. The two main databases are:

- [News headlines](https://ebardelli.com/ed-news/db/headlines.parquet)
- [Research articles](https://ebardelli.com/ed-news/db/articles.parquet)

These are queryable, for example, using DuckDB's `https` extension:

```sql
load https;
select title
from 'https://ebardelli.com/ed-news/db/headlines.parquet'
order by published desc
limit 10;
```

This query will return the latest 10 headlines in the database, letting you explore trends and topics without needing to access Ed News directly.

## What's Next

I have some more plans for this small service. Below are a few ideas I'm thinking about, feel free to tell me which ones you'd like to see.

- Move the database from the local `sqlite` file to an online service.
- Topic clustering and better tagging so related items are easier to find.
- Enrich articles further with CrossRef metadata (authors, DOIs, citations).
- Small UI tweaks: highlight new research, add author pages, improve pagination.

If you want to try the data yourself or file a bug/feature request, the repo is open on [GitHub](https://github.com/ebardelli/ed-news). For quick feedback, ping me on [BlueSky](https://bsky.app/profile/ebardelli.com).
