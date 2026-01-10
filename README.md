# AWSシークレット管理
以下の記事を参考に、direnvを使ってprofileを指定している。

https://qiita.com/Hikosaburou/items/1d3765d85d5398e3763f#direnv%E3%81%A7%E3%83%87%E3%82%A3%E3%83%AC%E3%82%AF%E3%83%88%E3%83%AA%E5%8D%98%E4%BD%8D%E3%81%A7%E7%92%B0%E5%A2%83%E5%A4%89%E6%95%B0%E3%82%92%E8%A8%AD%E5%AE%9A%E3%81%99%E3%82%8B

aws profileは設定済みの前提。`aws configure list`で確認できる。

## direnv
https://github.com/direnv/direnv?tab=readme-ov-file#basic-installation

### インストール手順
1. brew install direnv
2. ~/.zshrc に`eval "$(direnv hook zsh)"`を追記。
3. source ~/.zshrc

.envrcファイルにAWSプロファイル名などを設定。

# Terraformコマンド
`terraform`を実行して各種コマンドを確認できる。

# 依存関係図を作る
`terraform graph > graph.dot`を実行して、dotファイルをPreview Graphvizで開くと依存関係を表す図ができる。
（構成図というワードから連想するものではない。）

https://qiita.com/lilacs/items/fe8b3223f2a193c0fa2e

# ファイルレイアウト
- live : 実際に環境へ反映しているもののみを格納
  - stg : ステージング環境
    - data-sources : データストア
    - serivices : アプリケーションやマイクロサービス
  - prd : 本番環境

- modules : モジュール
  - services

- global : 全環境横断で利用するもの
  - s3

# ステート管理

`global/s3`内で作成したS3バケットで管理。
（書籍内ではDynamoDBも使う構成だったが、Terraformの更新により不要になった。）

## ステート管理開始手順
### 管理コンポーネント（S3バケット）自体の管理
1. `global/s3`内で terraform init, apply 実行し、S3バケットを作成。
2. それらを`global/s3/main.tf`にてbackendに設定。
3. `global/s3`内で terraform init, apply 実行。

### 管理コンポーネント以外の管理
1. `xxx/main.tf`にてbackendにステート管理用S3を設定。
2. `xxx`内で terraform init, apply 実行。
