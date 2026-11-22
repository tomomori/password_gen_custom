# テスト手順

このフォルダには、配布用の `password_gen_custom.html` をQUnitで検証するブラウザテストがあります。

利用者がアプリを使用するときに、このフォルダやテスト用ツールは必要ありません。配布用の `password_gen_custom.html` は、これまでどおり単体で動作します。

## テスト対象

`password-generator.test.html` は、1つ上の階層にある実際の `password_gen_custom.html` を読み込み、テストを2つのQUnitモジュールに分けて実行します。

### 生成ロジック

- 指定した文字数で生成されること
- 選択した各文字種が最低1文字ずつ含まれること
- 先頭を英字に限定できること
- 紛らわしい文字を除外できること
- 文字種が未選択の場合に小文字が自動的に有効になること

### 画面操作

- 初期設定で12文字のパスワードが表示されること
- スライダー変更が文字数表示と生成結果へ反映されること
- 増減ボタンで文字数を変更できること
- 文字種チェックの変更が生成結果へ反映されること
- 先頭英字が有効な場合に小文字が自動的に有効になること
- 記号をすべて選択または解除できること
- ライトテーマとダークテーマを切り替えられること

テストには、`tests/lib/qunit`に同梱したQUnit 3.0.0を使用します。Node.js、インターネット接続、追加のライブラリインストールは不要です。

## ファイル構成

```text
tests/
├─ README.md
├─ password-generator.test.html  # QUnitのテスト画面
├─ password-generator.test.js    # テストケース
└─ lib/
   └─ qunit/
      ├─ qunit.js
      ├─ qunit.css
      ├─ LICENSE.txt
      └─ README.md
```

## Pythonで実行する方法

リポジトリのルートディレクトリで、PowerShellまたはコマンドプロンプトを開きます。

```powershell
py -m http.server 8000
```

ブラウザで次のURLを開きます。

```text
http://localhost:8000/tests/password-generator.test.html
```

テストが完了すると、QUnitの画面上部に結果が表示されます。

```text
12 tests completed in ... seconds.
12 passed, 0 skipped, 0 failed, and 0 todo.
```

QUnit画面上部の「Module」から、生成ロジックまたは画面操作だけに絞って再実行できます。

### アプリ画面の表示ボタンについて

「アプリ画面を表示」ボタンは、テスト対象の `password_gen_custom.html` の現在状態をQUnit画面内で手動確認するためのものです。もう一度押すと非表示に戻ります。表示・非表示を切り替えても、テスト結果には影響しません。

QUnitのテストは短時間で自動実行され、画面操作テストの前後ではアプリを初期状態へ戻します。そのため、このボタンを押しても、スライダーやチェックボックスがテスト中に動く過程は表示されません。テスト結果と、テスト対象の画面を同じページで確認したい場合に使用してください。

画面操作を一定間隔で再生して目視確認する機能は含まれていません。そのような確認が必要な場合は、PlaywrightなどによるE2Eテストまたは専用のデモ機能を別途検討します。

ローカルHTTPサーバーを終了するには、起動したターミナルで `Ctrl+C` を押します。

`py` コマンドを利用できない環境では、次のコマンドも試せます。

```powershell
python -m http.server 8000
```

## VS CodeのLive Server系拡張機能で実行する方法

Live Server、Live HTTP Serverなど、ローカルファイルをHTTPで配信できる拡張機能も利用できます。

1. VS Codeでリポジトリのルートディレクトリを開きます。
2. `tests/password-generator.test.html` を開きます。
3. エディターの右クリックメニューなどから、Live Server系拡張機能でページを開きます。
4. ブラウザにテスト結果が表示されることを確認します。

ポート番号は拡張機能の設定によって異なります。例えば、次のようなURLで表示されます。

```text
http://127.0.0.1:5500/tests/password-generator.test.html
```

リポジトリのルートがサーバーの公開ルートになるようにしてください。`tests` フォルダだけを公開すると、1つ上の階層にある `password_gen_custom.html` を読み込めない場合があります。

## `file://`から直接実行できない理由

次のようにテスト用HTMLをダブルクリックして開いた場合、テストは実行されません。

```text
file:///F:/.../tests/password-generator.test.html
```

テスト用HTMLは、iframe内に配布用HTMLを読み込み、QUnitからその関数や画面を検証します。`file://`で開いたファイル同士は、ブラウザの同一オリジン制約によって相互参照が禁止されるため、ローカルHTTPサーバーが必要です。

この制約はテスト方法だけに関係します。利用者が `password_gen_custom.html` を単体で開いてアプリを使用する場合には影響しません。

## テストが失敗する場合

### サーバーのログに`304`と表示される

`304 Not Modified`は、変更されていないファイルをブラウザキャッシュから再利用したことを示す正常な応答です。テストの失敗を意味するものではありません。

### 「ローカルHTTPサーバーから実行されている」が失敗する

アドレスバーが `file://` で始まっていないか確認してください。PythonまたはLive Server系拡張機能を使い、`http://localhost`または`http://127.0.0.1`から開きます。

### 配布用HTMLを読み込めない

サーバーをリポジトリのルートディレクトリから起動したか確認してください。次の2つのURLをブラウザから開ける必要があります。

```text
http://localhost:8000/password_gen_custom.html
http://localhost:8000/tests/password-generator.test.html
```

### ポート8000を使用できない

別のポート番号を指定できます。

```powershell
py -m http.server 8080
```

その場合は、ブラウザでも同じポート番号を使用します。

```text
http://localhost:8080/tests/password-generator.test.html
```

