FROM cruizba/ubuntu-dind:latest

ARG RUNNER_VERSION="2.321.0"

# 必要な依存パッケージをインストール
RUN apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
    curl jq build-essential libssl-dev libffi-dev python3 python3-venv python3-dev python3-pip \
    ca-certificates gnupg lsb-release libicu-dev iptables \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# GitHub CLI (gh) のインストール
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Actions Runner のインストール
RUN mkdir -p /home/docker/actions-runner \
    && cd /home/docker/actions-runner \
    && curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && chown -R root:root /home/docker/actions-runner \
    && /home/docker/actions-runner/bin/installdependencies.sh

# スクリプトのコピーと権限設定
COPY start.sh /home/docker/start.sh
COPY github_app_token.sh /home/docker/github_app_token.sh
RUN chmod +x /home/docker/start.sh /home/docker/github_app_token.sh

# 実行ユーザーの指定 (root のままで OK)
USER root

CMD ["/home/docker/start.sh"]
