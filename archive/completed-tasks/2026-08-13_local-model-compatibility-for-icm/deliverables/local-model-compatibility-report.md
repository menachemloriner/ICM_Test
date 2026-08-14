# Local & Alternative Model Compatibility for ICM

**Task:** `tasks/2026-08-13_local-model-compatibility-for-icm`  
**Date:** 2026-08-13  
**Stage:** 03_review — revised after review

## What ICM actually needs

The session driver must be able to:

1. read `WORKSPACE_PROTOCOL.md` and the active stage contract;
2. use a local or remote filesystem/file-editing tool;
3. follow multi-step instructions before changing files; and
4. leave an inspectable trail.

MCP support alone does not prove instruction-following reliability. No option below
has been formally tested against this workspace's protocol file unless explicitly
marked otherwise.

## Hosted options

### ChatGPT Desktop

- **MCP/file-tool support:** Yes. OpenAI's MCP documentation says the ChatGPT
  desktop app supports MCP, including local STDIO servers, and shares MCP
  configuration with Codex clients. ([official MCP documentation](https://learn.chatgpt.com/docs/extend/mcp))
- **Concrete setup:** In ChatGPT Desktop, open **Settings → MCP servers → Add
  server**; choose **STDIO** or **Streamable HTTP**; enter the same command/URL,
  arguments, and allowed workspace used by Max's working filesystem server; save,
  restart, then type `/mcp` to confirm the server appears. The exact existing
  configuration is project-confirmed, not independently inspected in this task.
- **Setup difficulty:** Low for Max because a working filesystem setup already
  exists.
- **Reads instructions reliably:** **Untested** against `WORKSPACE_PROTOCOL.md`.
  The official docs establish support for MCP server instructions, not reliable
  adherence to this workspace's full protocol.
- **Cost/privacy:** Hosted model; the filesystem tool can be local, but model/data
  handling follows the selected ChatGPT account and workspace settings.

### Grok Build

- **MCP/file-tool support:** Yes. The official Grok Build documentation supports
  local STDIO MCP servers, remote HTTP servers, `~/.grok/config.toml`, and
  compatibility loading from `~/.claude.json`, `.cursor/mcp.json`, and project
  `.mcp.json` files. ([official MCP server documentation](https://docs.x.ai/build/features/mcp-servers))
- **Concrete setup:** Install Grok Build; keep or copy the filesystem server entry
  into the existing project `.mcp.json`/compatible Claude config; run `grok inspect`
  to see its origin; then run `grok mcp doctor <name>` to test connectivity. The
  official docs also support `grok mcp add filesystem -- <server-command> ...`.
- **Setup difficulty:** Low if Max's existing server is already represented in a
  compatible `.mcp.json`; otherwise moderate because the server command and path
  must be checked.
- **Reads instructions reliably:** **Untested** against `WORKSPACE_PROTOCOL.md`.
- **Cost/privacy:** Hosted model; local STDIO execution does not make the model
  itself local. xAI's separate Remote MCP API requires an HTTP/SSE `server_url`, so
  do not confuse that API path with Grok Build's local-server support. ([Remote MCP API documentation](https://docs.x.ai/developers/tools/remote-mcp))

### Gemini CLI

- **MCP/file-tool support:** Yes. Gemini CLI reads an `mcpServers` object from
  `settings.json` and supports STDIO, SSE, and Streamable HTTP transports. ([official Gemini CLI MCP documentation](https://google-gemini.github.io/gemini-cli/docs/tools/mcp-server.html))
- **Concrete setup:** Add the same local filesystem server command and arguments
  to `~/.gemini/settings.json` or `.gemini/settings.json`, or use
  `gemini mcp add <name> <command> [args...]`; run `gemini mcp list` and perform a
  read-only test of `WORKSPACE_PROTOCOL.md` before permitting edits.
- **Setup difficulty:** Low to moderate; the MCP entry is familiar, but it uses a
  Gemini-specific settings location.
- **Reads instructions reliably:** **Untested** against this workspace protocol.
- **Cost/privacy:** Hosted model through Gemini; local STDIO tool execution does
  not make the model local.

## Local and self-hosted options

### Goose

- **MCP/file-tool support:** Yes. Goose extensions are MCP servers, and its docs
  show adding local STDIO or remote Streamable HTTP extensions. ([extensions documentation](https://goose-docs.ai/docs/getting-started/using-extensions/))
- **Local model support:** Yes, including Ollama. Goose's provider documentation
  says locally installed Ollama models appear in the model selector. ([provider documentation](https://goose-docs.ai/docs/getting-started/providers/))
- **Concrete setup:** Install Goose, run `goose configure`, configure Ollama or
  another provider, then add the filesystem server as an extension or in the
  shared extension configuration. Start with a read-only task that asks Goose to
  read `WORKSPACE_PROTOCOL.md`, `STATUS.md`, and the active `CONTEXT.md`.
- **Setup difficulty:** Low to moderate.
- **Reads instructions reliably:** **Untested** against ICM. Goose Recipes package
  prompts, extensions, and settings into reusable workflows, which is a structural
  fit for ICM but not proof of reliable protocol adherence. ([Recipes documentation](https://goose-docs.ai/docs/guides/recipes/))
- **Cost/privacy:** Can be fully local with Ollama; privacy and cost change if a
  hosted provider is selected.

### LM Studio

- **MCP/file-tool support:** Yes. LM Studio supports MCP through its API using
  ephemeral servers or preconfigured `mcp.json` servers. ([official MCP documentation](https://lmstudio.ai/docs/developer/core/mcp))
- **Local model support:** Yes; LM Studio is primarily the local model runner and
  exposes local APIs. ([official developer documentation](https://lmstudio.ai/docs/developer))
- **Concrete setup:** Install LM Studio, load a tool-capable local model, enable
  the Developer/API server, add the filesystem server to `mcp.json`, enable the
  setting that permits calls to configured MCP servers, and test a read-only file
  request. For autonomous ICM work, pair it with an agent layer such as Goose or
  Cline rather than treating the model runner as the workflow controller.
- **Setup difficulty:** Low for model serving; moderate for secure MCP configuration.
- **Reads instructions reliably:** **Untested**; depends heavily on the selected
  model's tool-calling behavior.
- **Cost/privacy:** Local model execution can be private and avoids per-token API
  charges, subject to hardware and model-download choices.

### Cline

- **MCP/file-tool support:** Yes. Cline documents local STDIO and remote HTTP/SSE
  MCP servers, with configuration in the IDE or CLI. ([official MCP documentation](https://docs.cline.bot/mcp/mcp-overview))
- **Local model support:** Yes, through local providers such as Ollama and LM
  Studio's OpenAI-compatible endpoints. ([provider documentation](https://docs.cline.bot/provider-config/openai-compatible))
- **Concrete setup:** Install Cline in VS Code, open **MCP Servers**, add the local
  filesystem server under `mcpServers`, verify that its tools appear, and start in
  the approval-gated mode. Read the protocol files before allowing a write.
- **Setup difficulty:** Low if Max already works in VS Code.
- **Reads instructions reliably:** **Untested** against ICM. Approval gates reduce
  execution risk but do not prove that the model read the protocol first.
- **Cost/privacy:** Can use local models privately, or hosted models through the
  same provider configuration.

### Continue

- **MCP/file-tool support:** Yes, but MCP is available in Continue's Agent mode.
  Its documentation supports copying JSON MCP configurations into
  `.continue/mcpServers/` and using local servers. ([MCP setup documentation](https://docs.continue.dev/customize/deep-dives/mcp))
- **Local model support:** Continue's current CLI and documentation cover local
  model workflows, including Ollama and self-hosting guides. ([Continue guides](https://docs.continue.dev/guides/overview))
- **Concrete setup:** Create `.continue/mcpServers/`, place a filesystem MCP
  configuration there, start Continue in Agent mode, confirm the server is listed,
  and run a read-only protocol-file test.
- **Setup difficulty:** Moderate; the MCP config format and Agent-mode requirement
  add another layer.
- **Reads instructions reliably:** **Untested** against ICM. Agent mode can use
  tools, but that does not establish reliable protocol-first behavior.
- **Cost/privacy:** Can be local/private with an appropriate local model; hosted
  providers remain an option.

### Aider

- **MCP/file-tool support:** **Unverified for this report.** Aider's official
  documentation confirms broad model/provider support and local editing workflows,
  but the current official documentation checked here does not establish native
  MCP support. Treat third-party claims that Aider “speaks MCP” as unconfirmed
  until tested or documented by Aider. ([Aider documentation](https://aider.chat/docs/))
- **Local model support:** Yes, including local-provider workflows documented by
  Aider. ([Aider documentation](https://aider.chat/docs/))
- **Setup difficulty:** Low to moderate for its terminal workflow, but unknown for
  ICM until MCP compatibility is established.
- **Reads instructions reliably:** **Untested**.
- **Cost/privacy:** Can use local models; its git-oriented workflow may add useful
  history, but that is separate from MCP compatibility.
- **ICM decision:** Do not make Aider the first trial until its filesystem-tool path
  is verified.

### OpenHands

- **MCP/file-tool support:** Yes. OpenHands documents MCP configuration in the SDK
  and CLI, including local STDIO servers. ([MCP SDK documentation](https://docs.openhands.dev/sdk/guides/mcp), [CLI MCP documentation](https://docs.openhands.dev/openhands/usage/cli/mcp-servers))
- **Local model support:** Yes, including Ollama and other OpenAI-compatible local
  backends. ([local LLM documentation](https://docs.openhands.dev/openhands/usage/llms/local-llms))
- **Setup difficulty:** High relative to the other options because the documented
  setup commonly involves a browser UI, Docker or another workspace backend, and
  explicit LLM configuration. ([local setup documentation](https://docs.openhands.dev/openhands/usage/run-openhands/local-setup))
- **Reads instructions reliably:** **Untested** against ICM. The platform's MCP
  and workspace abstractions are not evidence of protocol-first behavior.
- **Cost/privacy:** Can run with a local model, but the runtime and infrastructure
  overhead are higher.
- **ICM decision:** Worth knowing about, but likely overkill for Max's current
  single-user workspace.

## Comparison table

| Option | Type | MCP/file-tool support | Local models | Setup | Reads ICM instructions reliably | Cost/privacy fit |
|---|---|---|---|---|---|---|
| ChatGPT Desktop | Hosted, desktop | Yes; local STDIO supported | No | Low for existing setup | Untested | Hosted model; local tool possible |
| Grok Build | Hosted, CLI | Yes; local STDIO and remote HTTP | No | Low–moderate | Untested | Hosted model; local tool possible |
| Gemini CLI | Hosted, CLI | Yes; STDIO/SSE/HTTP | No | Low–moderate | Untested | Hosted model; local tool possible |
| Goose | Local/hybrid agent | Yes; MCP extensions | Yes, including Ollama | Low–moderate | Untested | Strongest private/local fit |
| LM Studio | Local model runner | Yes; MCP via API/config | Yes | Low–moderate | Untested | Strong private/local fit |
| Cline | Local/hybrid IDE agent | Yes; local and remote MCP | Yes | Low in VS Code | Untested | Flexible; approval-gated |
| Continue | Local/hybrid IDE/CLI | Yes in Agent mode | Yes | Moderate | Untested | Flexible; verify model/tool loop |
| Aider | Local/hybrid CLI | Unverified | Yes | Low–moderate | Untested | Do not select until MCP verified |
| OpenHands | Local/hybrid platform | Yes; SDK and CLI MCP | Yes, including Ollama | High | Untested | Private possible, infrastructure-heavy |

## Recommendation: start here

**Start with Goose plus Ollama**, subject to Max's hardware. This is an inference
from the documented combination of MCP-based extensions, local-provider support,
and reusable Recipes—not a claim that Goose will automatically follow ICM's
protocol. The first trial should be deliberately read-only:

1. Configure Goose with Ollama and the filesystem MCP server.
2. Ask it to read `WORKSPACE_PROTOCOL.md`, the task `STATUS.md`, and the active
   stage contract.
3. Ask it to report the active task and stage without editing anything.
4. Only then permit a small, reversible file update.

**Second choice:** Cline if Max already works in VS Code and wants approval gates.

**Not first:** OpenHands is likely too infrastructure-heavy; Aider's MCP path is
not established by the current official documentation; Continue is viable but
requires Agent mode and a separate validation pass.

## Hardware question

Hardware specs were not gathered. A specific local-model recommendation (for
example, a 7B, 14B, or 32B model) should wait for GPU/RAM information rather than
being guessed.

## Evidence boundary

All “reads ICM instructions reliably” ratings are **Untested**. Tool support and
configuration documentation establish that an agent can access tools; they do not
establish that a particular model will read the protocol before acting. The first
Goose trial should produce that evidence.
