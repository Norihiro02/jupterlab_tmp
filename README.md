# JupyterLab on Docker テンプレート

## 構成

```
.
├── Dockerfile                      # python:3.12-slim ベースのイメージ
├── docker-compose.yml
├── requirements.txt                # Python パッケージ（ここに追記）
├── requirements-gpu.txt            # GPU 用パッケージ（PyTorch）
├── config/
│   ├── jupyter_server_config.py    # JupyterLab のサーバー設定
│   └── matplotlibrc                # matplotlib の日本語フォント設定
├── .env.example                    # 環境変数のサンプル
├── Makefile                        # よく使うコマンド
└── work/                           # ノートブック置き場（コンテナの ~/work にマウント）
```

## 使い方

```bash
cp .env.example .env      # UID/GID・ポート・トークンを編集
docker compose up -d --build
```

ブラウザで http://localhost:8888 を開き、`.env` の `JUPYTER_TOKEN` を入力します。

| コマンド | 内容 |
|---|---|
| `make up` / `make down` | 起動 / 停止 |
| `make rebuild` | requirements.txt 変更後の再ビルド |
| `make logs` | ログ表示 |
| `make shell` | コンテナに入る |

## カスタマイズ

- **パッケージ追加**: `requirements.txt` に追記して `make rebuild`
- **apt パッケージ追加**: `Dockerfile` の `apt-get install` に追記
- **ポート変更**: `.env` の `JUPYTER_PORT`
- **権限**: `.env` の `UID`/`GID` をホストの `id -u` / `id -g` に合わせると、`work/` 内のファイル所有者がホストユーザーになります
- **公開範囲**: 既定では `127.0.0.1` のみで待ち受けます。LAN に公開する場合は `docker-compose.yml` の `127.0.0.1:` を外し、必ずトークンを設定してください

## GPU

`docker-compose.yml` で全 GPU をコンテナに割り当てています。PyTorch は CUDA ランタイムを同梱しているため、ベースイメージに CUDA は不要です。

ホスト側の前提:
- NVIDIA ドライバが読み込まれていること（ホストで `nvidia-smi` が動く）
- NVIDIA Container Toolkit がインストールされていること

### GPU 確認手順

`work/gpu_check.ipynb` を実行するか、以下を順に確認します。

1. **ホスト**: GPU とドライバが見えるか
   ```bash
   nvidia-smi
   docker info | grep -i runtime   # Runtimes に nvidia が含まれること
   ```
2. **コンテナ**: GPU がコンテナに渡っているか
   ```bash
   docker compose exec jupyterlab nvidia-smi
   ```
3. **PyTorch**: CUDA で計算できるか
   ```bash
   docker compose exec jupyterlab python -c "
   import torch
   print(torch.__version__, torch.version.cuda)
   print(torch.cuda.is_available(), torch.cuda.get_device_name(0))
   x = torch.randn(4000, 4000, device='cuda'); (x @ x).sum().item(); print('OK')
   "
   ```
   `True`・GPU 名・`OK` が表示されれば利用可能です。

うまくいかない場合:
- 手順 1 で失敗 → ホストのドライバ / NVIDIA Container Toolkit を確認（下記の注記も参照）
- 手順 2 で失敗 → `docker-compose.yml` の `deploy:` ブロックを確認し、`docker compose up -d` で再作成
- 手順 3 で `No module named 'torch'` → イメージが古いので `docker compose up -d --build` で再ビルド
- 手順 3 で `False` → ドライバの CUDA バージョン（`nvidia-smi` 右上）より PyTorch の CUDA が新しすぎる可能性。`requirements-gpu.txt` で `--extra-index-url https://download.pytorch.org/whl/cu130` などを指定して再ビルド

GPU のないマシンで使う場合は `docker-compose.yml` の `deploy:` ブロックを削除してください。

> カーネル更新後に `nvidia-smi` が失敗する場合は、新しいカーネル用のドライバモジュールが入っていない可能性があります:
> `sudo apt install linux-modules-nvidia-580-open-$(uname -r)` → 再起動
