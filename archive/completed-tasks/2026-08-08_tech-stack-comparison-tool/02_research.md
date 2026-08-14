# Stage 02 — Research

## Findings

### Five Tech Stacks (Final List)

**1. React + Node.js**
- Learning curve: 2/5 (easy, huge community, tons of tutorials)
- Performance: 3/5 (good for most applications, not compiled)
- Community: 5/5 (largest in web)
- Job market: 5/5 (ubiquitous)
- Cost: 5/5 (free, open-source)
- Deployment: 4/5 (many hosting options, straightforward)
- Best for: Web apps, startups, full-stack JavaScript

**2. Python + FastAPI**
- Learning curve: 1/5 (easiest language, great for beginners, ML-friendly)
- Performance: 4/5 (fast for interpreted, good async support)
- Community: 4/5 (huge in data science, growing in web)
- Job market: 4/5 (strong in startups, data science, ML)
- Cost: 5/5 (free, open-source)
- Deployment: 4/5 (simple, Docker-friendly)
- Best for: Beginners, ML projects, rapid prototyping, data science

**3. Go + Gin**
- Learning curve: 3/5 (simple syntax, compiled complexity)
- Performance: 5/5 (blazingly fast, compiled, excellent concurrency)
- Community: 3/5 (growing, especially in DevOps/cloud)
- Job market: 3/5 (niche but growing; popular at cloud companies)
- Cost: 5/5 (free, open-source)
- Deployment: 5/5 (single binary, minimal dependencies)
- Best for: High-performance services, cloud infrastructure, DevOps

**4. Rust + Actix**
- Learning curve: 5/5 (steepest, complex ownership model, but teaches solid fundamentals)
- Performance: 5/5 (fastest compiled language, zero-cost abstractions)
- Community: 3/5 (growing, tight-knit, strong in systems)
- Job market: 2/5 (niche, elite roles)
- Cost: 5/5 (free, open-source)
- Deployment: 5/5 (single binary, minimal runtime)
- Best for: Performance-critical systems, embedded, aerospace, finance

**5. TypeScript + Bun**
- Learning curve: 2/5 (TypeScript is learnable, Bun is drop-in Node compatible)
- Performance: 4/5 (2–3.5x faster than Node/Express, fastest JS runtime in 2026)
- Community: 3/5 (rapidly growing, adopted by Anthropic for Claude Code CLI)
- Job market: 2/5 (emerging, not yet mainstream; fewer jobs than Node but growing)
- Cost: 5/5 (free, open-source)
- Deployment: 5/5 (single binary, zero-config TypeScript, fastest cold starts)
- Best for: Performance-critical JS apps, TypeScript-first projects, serverless/edge

### Comparison Dimensions (6 chosen)
1. **Learning Curve** (1=easiest for a beginner, 5=hardest)
2. **Performance** (1=slow/interpreted, 5=blazingly fast/compiled)
3. **Community Size** (1=tiny, 5=massive)
4. **Job Market** (1=niche/rare, 5=everywhere)
5. **Cost** (1=expensive/licensed, 5=free open-source)
6. **Deployment Ease** (1=complex, 5=simple)

### Sources (verified, session 2 — Aug 2026)
- Stack Overflow 2024 & 2025 Developer Survey (survey.stackoverflow.co) — usage, admiration, FastAPI/Rust trend data
- Rust vs Go 2026 comparisons (reintech.io, javacodegeeks.com, danilchenko.dev) — job market size, salary data
- Node vs Bun vs Deno 2026 runtime comparisons (medium.com/@moksh45, daily.dev) — Deno adoption ~2.4% vs Node 42.65%
- FastAPI vs Express/Node performance benchmarks (kunalganglani.com, index.dev, fastapi GitHub discussions) — mixed results, workload-dependent

### Verification notes (session 2)
- Core ratings for Rust, Go, Python/FastAPI held up against current 2026 data — no numeric corrections needed.
- **Swap applied:** Replaced TypeScript+Deno with TypeScript+Bun. Bun is the more prominent "modern JS runtime" as of 2026 (2–3.5x faster than Node/Express, adopted by Anthropic for Claude Code CLI tooling). Deno adoption stuck at ~2.4% while Bun gained rapid traction.
- Original sources list was generic/unlinked; replaced with actual citations above.

### Notes for 03_build
- Use a 5-point scoring system (1-5 bars or dots)
- Color code: green (5) → yellow (3) → red (1) for quick visual scanning
- Order stacks by learning curve difficulty (easy to hard) as default
- Include a toggle or filter to sort by any dimension
- Show one-line use case for each stack ("Best for: ...")
