# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

NHL-Judge-System JudgeはSwiftUIベースのiPad/iPhoneアプリケーションで、ダンス/パフォーマンスコンテストの審査員として機能します。UDPネットワーク通信を介してホストデバイスとリアルタイムでスコアを送受信します。

これは2つのアプリケーションからなるシステムの一部です：
- **nexthouselab-judge** (このリポジトリ): スコアを入力・送信する審査員クライアントデバイス
- **nexthouselab-host**: スコアを集約するホスト/マスターデバイス (兄弟ディレクトリに配置)

## ビルド・開発コマンド

### プロジェクトのビルド
```bash
xcodebuild -scheme nexthouselab-judge -configuration Debug build
```

### リリースビルド
```bash
xcodebuild -scheme nexthouselab-judge -configuration Release build
```

### Xcodeで開く
```bash
open nexthouselab-judge.xcodeproj
```

### テスト実行
```bash
xcodebuild test -scheme nexthouselab-judge -destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch) (6th generation)'
```

## アーキテクチャ

### コアアプリ構造

アプリはSwiftUIを使用し、環境オブジェクトで状態管理を行います：

- **nexthouselab_judgeApp.swift**: アプリのエントリーポイント。3つのメイン状態オブジェクトを初期化：
  - `SocketManager`: すべてのUDPネットワーク通信を管理
  - `ScoreModel`: スコアデータと永続化を管理
  - `MessageHandler`: ネットワークメッセージの処理と状態管理（2025年追加）

- **HomeView.swift**: 審査員名入力、出場者リストインポート、ホスト選択などの初期設定画面
- **MainView.swift**: スコア入力のメインインターフェース（メッセージ処理はMessageHandlerに委譲）

### ナビゲーションフロー

1. **HomeView** (`View/HomeView.swift`): エントリーポイント。審査員は以下を行います：
   - 名前を入力（UserDefaultsに保存）
   - CSVファイルから出場者リストをインポート（フォーマット: `番号,名前`）
   - ネットワーク同期用のホストIPアドレスを選択
   - 採点モード（ソロまたはデュアル）を選択

2. **MainView** (`View/MainView.swift`): メインの採点インターフェース：
   - 出場者リスト（`EntryListItemView`）
   - 0-10の範囲で0.5刻みのリアルタイムスコア入力
   - 5秒ごとの自動保存
   - スコア変更時のUDPメッセージブロードキャスト

### ネットワークアーキテクチャ (UDPベース)

カスタムUDPネットワーキング層を実装してリアルタイム通信を実現:

**SocketManager.swift**が複数のホストへの接続を管理:
- **受信ポート**: 8000（ホストからのメッセージを受信）
- **送信ポート**: 9000（ホストへメッセージ送信）
- IPアドレスをキーとした`NWConnection`オブジェクトの辞書を保持
- 複数のホストデバイスに同時接続可能

**PeerManager.swift**: ローカル検出用のMultipeerConnectivity実装:
- サービスタイプ"judge-session"でBonjourサービスディスカバリーを使用
- ピアの自動検出と接続を提供
- デフォルトで接続を暗号化
- メインフローにはまだ統合されていない（将来的なオプション）

### メッセージプロトコル（型安全化済み）

**NetworkMessage.swift**で型安全なメッセージ定義を提供:

```swift
enum NetworkMessage {
    case editing(judgeName: String, entryNumber: Int)
    case decision(judgeName: String, entryNumber: Int, score: Float?)
    case cancel(judgeName: String, entryNumber: Int)
    case update(judgeName: String, scores: [String: Float?], doneStates: [String: Bool])
    case currentNumber(number: Int)
    case requestUpdate
}
```

ワイヤーフォーマット（スラッシュ区切りの文字列）:
- `EDITING/{judgeName}/{entryNumber}` - 審査員がエントリーを編集中
- `SCORER/DECISION/{judgeName}/{entryNumber}/{score}` - スコア確定（-1はnilとして扱う）
- `SCORER/CANCEL/{judgeName}/{entryNumber}/-1` - スコアキャンセル
- `UPDATE/{judgeName}/{scoresJSON}/{doneStatesJSON}` - 一括スコア更新（ホストへの応答）
- `{number}` - 現在のエントリー番号の同期（ホストからの受信）
- `UPDATE` - ホストからのリクエスト（スコアデータ送信を要求）

**重要**: スコア値`-1`は自動的に`nil`に変換されます（未入力を示す）

### メッセージ処理アーキテクチャ

**MessageHandler.swift** (2025年追加):
- 受信メッセージを型安全に処理
- `NetworkMessage.parse()`でメッセージをパース
- 各メッセージタイプに応じた専用ハンドラで処理
- `@Published`プロパティでUI状態を管理:
  - `currentNumber`: 現在のエントリー番号

**設計思想**:
- MainViewからメッセージ処理ロジックを完全に分離（47行のロジックを削減）
- 型安全性により実行時エラーを削減
- 関心の分離によりテストとメンテナンスが容易

### リソース生成

このプロジェクトは**R.swift**（Swift Package Manager経由）を使用して型安全なリソースアクセサーを生成します：
- プロジェクトルートの`R.generated.swift`に生成されたコードが含まれます
- カラーへのアクセス: `Color(R.color.oddColor)`, `Color(R.color.scoreColor)` など
- ローカライズ文字列へのアクセス: `R.string.localizable.ok()`, `R.string.localizable.done()`
- 画像へのアクセス: `R.image.icon`

`R.generated.swift`は手動で編集しないでください - ビルド時に再生成されます。

### ローカライゼーション

アプリは日本語と英語に対応：
- ローカライズ文字列は`Resources/ja.lproj/Localizable.strings`と`Resources/en.lproj/Localizable.strings`に配置
- UIはロケールに基づいてボタンフォントサイズを調整（`Locale.current == Locale(identifier: "ja_JP")`）

### データモデル

**ScoreModel.swift**:
- スコア辞書構造: `Dictionary<String, Float?>` （Optional型でnilを明示的に表現）
- 完了状態辞書: `Dictionary<String, Bool>`
- 5秒ごとにUserDefaultsへ自動保存
- **重要**: スコア`nil`は未入力を示す（保存時は`-1`に変換して後方互換性を維持）
- `AppConfiguration.StorageKeys.scores`キーで永続化

主要メソッド:
- `getScore(for:)`: Floatの Bindingを返す（nilは0として表示）
- `updateScores(forKey:value:)`: Float?版を直接受け取る
- `initialize(entryList:)`: エントリーリストでスコアを初期化（nilで開始）
- `startTimer()`/`stopTimer()`: 自動保存タイマーの制御

### 設定管理

**AppConfiguration.swift** (2025年追加):
- アプリケーション全体の設定を一元管理する構造体

主要セクション:
- `Network`: ポート番号（送信9000、受信8000）、サービスタイプなどのネットワーク設定
- `StorageKeys`: UserDefaultsキーの定義
- `Scores`: スコア範囲（0-10）、ステップ（0.5）、自動保存間隔（5秒）などの設定
- `CompetitionMode`: 競技モード（solo/dual）
- `ExportGenres`: エクスポート用のジャンルリスト
- `UI`: フレーム幅、フォントサイズなどのUI定数

後方互換性のため`Const`クラスをラッパーとして提供（将来的に削除予定）。

### データ永続化

すべてのデータはUserDefaultsに保存:
- `scores`: 完全なスコア辞書（nil値は-1として保存）
- `done_states`: 各エントリーの完了状態
- `judge_name`: 審査員名
- `selected_file_cocntents`: インポートしたファイル内容
- `host`: ホストIPアドレスの配列
- `current_play_num_key`: 現在のプレイ番号

### 採点モード

`Const.Mode`列挙型で定義：
- **Solo**: 1人ずつのパフォーマー、順次採点
- **Dual**: 2人同時（ペア）

モードは以下に影響します：
- `EntryListItemView`の背景色（デュアルモードでは奇数/偶数色）
- どのエントリーが「現在プレイ中」として表示されるか
- エントリータップ時の選択動作

### ディレクトリ構造

```
nexthouselab-judge/
├── Model/
│   ├── AppConfiguration.swift    # 設定管理（2025年追加）
│   ├── MessageHandler.swift      # メッセージ処理（2025年追加）
│   └── NetworkMessage.swift      # 型安全なメッセージ定義（2025年追加）
├── Socket/
│   └── SocketManager.swift       # UDPネットワーク管理
├── View/
│   ├── HomeView.swift            # 初期設定画面
│   ├── MainView.swift            # スコア入力画面
│   ├── ScoreModel.swift          # スコアデータ管理
│   ├── EntryListItemView.swift   # 個別エントリー行
│   ├── DocumentPickerView.swift  # ファイルインポート
│   └── Component/                # 再利用可能なUIコンポーネント
└── Resources/
    ├── ja.lproj/                 # 日本語リソース
    └── en.lproj/                 # 英語リソース
```

## 主要な技術詳細

### 並行処理パターン
- ネットワーク操作は非同期処理で実装（2025年改善：デッドロック問題を解決）
- `DispatchQueue.main.async`でUI更新（syncは使用しない）
- リスナーにはバックグラウンドキュー、UI更新にはメインキュー
- タイマーベースの自動保存 (5秒間隔)

### 型安全性とNull安全性

**スコアの扱い**:
- アプリ内部: `Float?`型でnilを明示的に表現
- ネットワーク送信: `-1`に変換（後方互換性）
- UserDefaults保存: `-1`に変換（後方互換性）
- 受信時: `-1`を自動的にnilに変換

**メッセージの扱い**:
- 文字列パース: `NetworkMessage.parse()`で型安全に変換
- パース失敗時: nilを返し、エラーログを出力
- 型安全性によりコンパイル時にエラーを検出

## 最近の大規模リファクタリング（2025年実施）

### 主要な変更点

1. **型安全性の向上**
   - `NetworkMessage` enumによるメッセージプロトコルの型安全化
   - `Optional<Float>`によるスコアの明示的なnil表現（マジックナンバー`-1`を排除）
   - `AppConfiguration`による定数の一元管理

2. **アーキテクチャの改善**
   - `MessageHandler`クラスの追加（MainViewから47行のロジックを分離）
   - 責務の明確化と関心の分離
   - テスト容易性の向上

3. **コード品質の改善**
   - タイポ修正: `listenerState`, `receivedData`, `updatedTime`
   - 約100行のコメントアウトコードを削除
   - 重複コードの統合（`connect`と`connectAllHosts`）
   - スレッドセーフティ問題の修正（`DispatchQueue.main.sync` → `async`）

4. **Enum命名の統一**
   - `CompetitionMode`: `.Solo`/`.Dual` → `.solo`/`.dual`（小文字に統一）

5. **ファイル構成の整理**
   - `Model/`ディレクトリの新規作成
   - `Const.swift`を削除（AppConfigurationに統合、互換レイヤーとして残存）
   - `ContentView.swift`削除（未使用）

### マイグレーション注意点

- 既存のUserDefaultsデータは自動的に変換されます（`-1` → `nil`）
- ネットワークプロトコルは後方互換性を維持（`-1`として送受信）
- `Const`クラスは互換性レイヤーとして残存（将来的に削除予定）

## 開発上の注意点

### スコアの扱い
- **アプリ内部では常に`Float?`を使用**
- `-1`は「未入力」ではなく、`nil`を使用
- ネットワーク層とストレージ層でのみ`-1`に変換

### メッセージ処理
- 新しいメッセージタイプを追加する場合は`NetworkMessage` enumに追加
- `MessageHandler`に対応するハンドラメソッドを実装
- パース/シリアライズロジックも更新が必要

### 設定管理
- 新しい定数は`AppConfiguration`に追加
- 後方互換性が必要な場合のみ`Const`にも追加
- ハードコーディングを避け、設定可能にする

### CSVファイル形式
- フォーマット: `番号,名前` （1行に1人の出場者）
- 例: `1,Kenshu`

### テスト
- `MessageHandler`, `NetworkMessage`, `ScoreModel`は独立してテスト可能
- ViewとModelが分離されているためユニットテストが容易

## 推奨される今後の改善

1. **UserDefaults Repository の作成** - テスト容易性の向上
2. **エラーハンドリングの改善** - ユーザーへのフィードバック強化
3. **Protocol導入によるDI改善** - `SocketManagerProtocol`, `ScoreModelProtocol`を作成
