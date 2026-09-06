# Chainguard Wolfi base, pinned by digest for reproducibility
FROM cgr.dev/chainguard/wolfi-base@sha256:918a593b8268c222afd4e2c4f06860ac984e60719b4697e4c71d796bc8fcd042

# Install Node.js/npm (to run the CLI) and git (used by Claude for repo operations)
RUN apk add --no-cache nodejs npm git ca-certificates

### Claude Code Env Vars ### 
# https://code.claude.com/docs/en/env-vars

# Disable self-update so the pinned version doesn't drift at runtime
ENV DISABLE_AUTOUPDATER=1
# Cut non-essential network calls (feature-flag fetching, Remote Control)
ENV CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
# Don't send telemetry or error reports out of this container
ENV DISABLE_TELEMETRY=1
ENV DISABLE_ERROR_REPORTING=1
# Keep config/state confined to the container's own home dir
ENV CLAUDE_CONFIG_DIR=/home/claude/.claude

# Install the latest Claude Code CLI globally
RUN npm install -g @anthropic-ai/claude-code@latest && npm cache clean --force

# Create a non-root user/group with fixed, reproducible IDs; the CLI refuses to run
# as root with --dangerously-skip-permissions
RUN addgroup -g 10001 claude && adduser -D -u 10001 -G claude claude

# Create the workspace and home config dir, and hand ownership to the non-root user
# before switching to it (npm/claude need to write config under CLAUDE_CONFIG_DIR)
RUN mkdir -p /workspace /home/claude/.claude && \
    chown -R claude:claude /workspace /home/claude
USER claude
WORKDIR /workspace

LABEL org.opencontainers.image.title="wolfi-claude-code" \
      org.opencontainers.image.description="Isolated Claude Code CLI sandbox on Chainguard Wolfi"

# Default to launching the CLI when the container starts
ENTRYPOINT ["claude"]
