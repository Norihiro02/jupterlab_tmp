# syntax=docker/dockerfile:1
FROM python:3.12-slim

ARG USERNAME=jovyan
ARG UID=1000
ARG GID=1000

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    TZ=Asia/Tokyo \
    LANG=C.UTF-8

# システムパッケージ（日本語フォント含む）
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        git \
        curl \
        tini \
        tzdata \
        fonts-noto-cjk \
    && rm -rf /var/lib/apt/lists/*

# ホストと同じ UID/GID のユーザーを作成（マウントしたファイルの権限問題を回避）
RUN groupadd -g ${GID} ${USERNAME} \
    && useradd -m -s /bin/bash -u ${UID} -g ${GID} ${USERNAME}

# named volume の初期所有者をユーザーにするため事前に作成
RUN mkdir -p /home/${USERNAME}/.jupyter /home/${USERNAME}/work \
    && chown -R ${UID}:${GID} /home/${USERNAME}

# GPU 用パッケージ（PyTorch, CUDA ランタイム同梱）
# サイズが大きいので別レイヤーにし、requirements.txt を変えても再ダウンロードしないようにする
COPY requirements-gpu.txt /tmp/requirements-gpu.txt
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --upgrade pip \
    && pip install -r /tmp/requirements-gpu.txt

# Python パッケージ
COPY requirements.txt /tmp/requirements.txt
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r /tmp/requirements.txt

# JupyterLab 設定
COPY config/jupyter_server_config.py /etc/jupyter/jupyter_server_config.py

# matplotlib で日本語を表示するための設定
COPY config/matplotlibrc /etc/matplotlibrc
ENV MATPLOTLIBRC=/etc/matplotlibrc

USER ${USERNAME}
WORKDIR /home/${USERNAME}/work

EXPOSE 8888

ENTRYPOINT ["tini", "--"]
CMD ["jupyter", "lab"]
