import os

c = get_config()  # noqa: F821

c.ServerApp.ip = "0.0.0.0"
c.ServerApp.port = 8888
c.ServerApp.open_browser = False
c.ServerApp.allow_root = False
c.ServerApp.root_dir = os.path.expanduser("~/work")

# 認証トークン: .env の JUPYTER_TOKEN で指定（空ならトークン無効）
token = os.environ.get("JUPYTER_TOKEN")
if token is not None:
    c.IdentityProvider.token = token
