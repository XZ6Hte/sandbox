# Sandbox for agentic software development.
#
# PHP 8.5 (Laravel) + Node 22 + Bun + GitHub CLI + OpenCode + Claude Code.
# Everything the model needs lives inside this image; the only host directory
# it can reach is the bind-mounted ./workspace.

FROM php:8.5-cli-bookworm

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# --- base tools, PHP build deps and common PHP extensions -------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        wget \
        gnupg \
        git \
        jq \
        less \
        make \
        unzip \
        zip \
        sudo \
        ripgrep \
        openssh-client \
        procps \
        sqlite3 \
        libicu-dev \
        libzip-dev \
        libpng-dev \
        libjpeg62-turbo-dev \
        libfreetype6-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" bcmath gd intl pdo_mysql zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# --- Composer ---------------------------------------------------------------
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

# --- Node.js 22 (npm, npx) --------------------------------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# --- GitHub CLI -------------------------------------------------------------
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# --- Bun --------------------------------------------------------------------
ENV BUN_INSTALL=/usr/local
RUN curl -fsSL https://bun.sh/install | bash

# --- Claude Code ------------------------------------------------------------
RUN npm install -g @anthropic-ai/claude-code

# --- unprivileged user ------------------------------------------------------
ARG USER_UID=1000
ARG USER_GID=1000

RUN groupadd --gid "$USER_GID" dev \
    && useradd --uid "$USER_UID" --gid "$USER_GID" --create-home --shell /bin/bash dev \
    && echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev \
    && chmod 0440 /etc/sudoers.d/dev \
    && mkdir -p \
        /workspace \
        /home/dev/.claude \
        /home/dev/.config/opencode \
        /home/dev/.config/composer \
        /home/dev/.local/share/opencode \
        /home/dev/.cache/composer \
        /home/dev/.npm \
        /home/dev/.bun \
    && chown -R dev:dev /workspace /home/dev

# --- OpenCode 2 (as dev, so the installer uses the right home) --------------
# OpenCode 1 and 2 have separate installers; https://opencode.ai/install
# refuses to install a 2.x version. Pin the v2 line explicitly.
ENV HOME=/home/dev
USER dev
RUN curl -fsSL https://opencode.ai/v2/install | bash -s -- \
        --version 2.2.5 \
        --no-modify-path
USER root
RUN ln -sf /home/dev/.opencode/bin/opencode /usr/local/bin/opencode \
    && ln -sf /home/dev/.opencode/bin/opencode /usr/local/bin/opencode2

# Let `npm install -g` work without sudo inside the container.
ENV NPM_CONFIG_PREFIX=/home/dev/.local \
    PATH=/home/dev/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin

# Git uses the gh token for HTTPS clones/pushes without touching credentials.
RUN git config --system credential."https://github.com".helper "!gh auth git-credential"

COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /workspace
USER dev

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["sleep", "infinity"]
