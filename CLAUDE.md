# WorkSpace — Stable Diffusion モデル管理リポジトリ

画像生成（SDXL / Illustrious系）のチェックポイントモデルを選定・管理する
ためのリポジトリ。モデルの実体ファイルは管理せず、「どのモデルを・どこから・
どの設定で使うか」だけをコードとして管理する。

ユーザーはWindows + PowerShell環境。やり取りは日本語で行うこと。
専門用語は必要最小限にし、手順は1行ずつコピペできる形で示す。

## 構成

- `models/checkpoints.yml` — モデル登録簿（single source of truth）。
  CivitaiのモデルID・バージョン名・推奨設定・選定理由のメモを持つ
- `models/download.sh` — bash版DLスクリプト（要 curl/jq/yq）
- `models/download.ps1` — PowerShell版DLスクリプト（Windows標準機能のみで動く）。
  **冒頭のモデルテーブルは checkpoints.yml の複製。yml を変えたら必ず ps1 も同期すること**
- `models/checkpoints/` — DL先。gitignore済み（.gitkeepのみ管理）

## この環境の制約（重要・回避不可）

- **civitai.com / huggingface.co へのアクセスはネットワークポリシーで遮断されている**
  （プロキシが403を返す）。モデル本体のDLやCivitai APIの直接呼び出しは
  この環境では絶対にできない。試すだけ無駄なのでユーザーのローカル実行に誘導する
- WebFetchも同じプロキシを通るため同様にブロックされる。
  **WebSearchだけはAPI側で実行されるため使える** — Civitaiのモデル情報を
  調べたいときはWebSearchで検索結果のURL（modelVersionId等）から情報を拾う
- GitHubへのpushは Claude GitHub App 経由。権限は Contents: write のみで、
  リポジトリ設定の変更（デフォルトブランチ変更等）は403になる

## Gitの運用

- 履歴は `main` と作業ブランチの両方に置いている。作業が済んだら
  `git push origin <branch>:refs/heads/main` で main も更新する
  （リポジトリは元々空で作られたため、PRベースの運用はしていない）
- デフォルトブランチは歴史的経緯で `claude/model-evaluation-download-3fi6to`
  のままになっていることがある。変更はユーザーにしかできない

## モデル追加の手順

1. WebSearchでCivitaiのモデルページを特定し、URLから `model_id` を確認
2. `models/checkpoints.yml` にエントリ追加（id / name / role / source /
   filename / notes / recommended_settings）
3. `models/download.ps1` のモデルテーブルにも同じエントリを追加
4. バージョンIDが検索で確定できない場合は `version_id: null` でよい —
   スクリプトが実行時にCivitai APIへ `version_name` を問い合わせて解決する
5. コミットして作業ブランチとmainの両方へpush

## ユーザー側でのDL実行（案内用）

```powershell
git clone https://github.com/oozoro/WorkSpace.git
cd WorkSpace
$env:CIVITAI_API_KEY = "APIキー"
.\models\download.ps1
```

- APIキーは https://civitai.com/user/account の「API Keys」で発行
- 実行ポリシーで弾かれたら
  `powershell -ExecutionPolicy Bypass -File .\models\download.ps1`
- JANKU v6.0はEarly Access配布の場合があり、403になったら
  Civitaiのモデルページで先にアンロックが必要
