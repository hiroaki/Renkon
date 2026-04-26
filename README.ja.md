# Renkon / レンコン

English version: [README.md](README.md)

Renkon は Web ベースのシンプルな RSS リーダーです。セルフホスト型の個人用サーバとしての利用を想定しています。

- 3 ペインの画面レイアウト
- キーボードでの操作
- 記事の簡易プレビュー（RSS フィードに含まれている内容のみ）
- OPML 形式のエクスポート、インポートをサポート

現在はアルファ版です。今後多くの機能を実装していく予定です。

![サンプル画像](README.png)

## 要件

Docker コンテナとして実行できますので、Docker エンジンが動作する環境で利用できます。

Docker を利用しない場合は、以下が必要です。

- Ruby 3.4.9
- SQLite3


## 起動方法

Docker でローカル起動する場合は、開発用の compose 設定を使います。

```sh
$ docker compose up --build -d
$ docker compose exec web bin/rails db:prepare
$ docker compose exec web bin/rails s
```

その後、ブラウザで http://127.0.0.1:3000/ を開いてください。

Docker を使わずに起動する場合は、依存関係をインストールして DB を準備したうえで起動してください。

```sh
$ bundle install
$ bin/rails db:prepare
$ bin/rails s
```


## 開発者向けガイド

### 環境構築

開発用コンテナをビルドして起動し、その後にデータベースを準備します。

```sh
$ docker compose up --build -d
$ docker compose exec web bin/rails db:prepare
```

### サーバー起動

起動済みコンテナ内で開発サーバーを開始します。

```sh
$ docker compose exec web bin/dev
```

### テスト

```sh
$ bin/rspec
```

システムテストには cuprite を使っていますが、Docker コンテナには Chrome ブラウザがインストールされていないため、コンテナ内から実行すると失敗します。コンテナに Chrome をインストールするか、Chrome が利用できるホスト上で実行してください。

### ローカル CI

```sh
$ bin/ci
```

ローカルでテスト前提のセットアップ、importmap の脆弱性監査、RSpec、ステージング用イメージの起動確認を行います。デプロイ前の最終確認に使ってください。

### デプロイ

デプロイ前に `dot.env.staging.sample` を `.env.staging` としてコピーし、必要な環境変数を設定したうえで destination を指定して実行してください。

```sh
$ dotenv -f .env.staging bundle exec kamal deploy --destination=staging
```


## ライセンス

このプロジェクトは Zero-Clause BSD ライセンス（0BSD）の下で提供されています。詳細は LICENSE ファイルを参照してください。