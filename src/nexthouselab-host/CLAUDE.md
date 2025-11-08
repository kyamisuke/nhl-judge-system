# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

NHL-Judge-System HostはSwiftUIベースのiPad/iPhoneアプリケーションで、ダンス/パフォーマンスコンテストの審査セッションを管理します。UDPネットワーク通信を介して複数の審査員デバイスと通信し、リアルタイムでスコアを収集・同期する中央ホストとして機能します。

これは2つのアプリケーションからなるシステムの一部です:
- **nexthouselab-host** (このリポジトリ): スコアを集約するホスト/マスターデバイス
- **nexthouselab-judge**: スコアを送信する審査員クライアントデバイス (兄弟ディレクトリに配置)

## ビルドと実行コマンド

### プロジェクトのビルド
```bash
# デバイス/シミュレータ用にビルド
xcodebuild -scheme nexthouselab-host -configuration Debug build

# リリース用ビルド
xcodebuild -scheme nexthouselab-host -configuration Release build

# ビルド成果物をクリーン
xcodebuild -scheme nexthouselab-host clean
```

### 実行方法
iOS/iPadOSアプリのため、Xcodeまたは実機で実行する必要があります。`nexthouselab-host.xcodeproj`をXcodeで開いてビルド・実行してください。

## アーキテクチャ

### コアアプリ構造

アプリはSwiftUIを使用し、環境オブジェクトで状態管理を行います:

- **nexthouselab_hostApp.swift**: アプリのエントリーポイント。3つのメイン状態オブジェクトを初期化:
  - `SocketManager`: すべてのUDPネットワーク通信を管理
  - `ScoreModel`: スコアデータと永続化を管理
  - `MessageHandler`: ネットワークメッセージの処理と状態管理（新規追加）

- **MainView.swift**: UI全体を統括するルートビュー（メッセージ処理はMessageHandlerに委譲）

### ネットワークアーキテクチャ (UDPベース)

カスタムUDPネットワーキング層を実装してリアルタイム通信を実現:

**SocketManager.swift**が複数の同時接続を管理:
- **iPadモード**: ポート9000でリッスン、ポート8000で審査員に接続
- **iPhoneモード**: ポート9000(ホスト)と8000(phone)のデュアルリスナー
- IPアドレスをキーとした`NWConnection`オブジェクトの辞書を保持
- ブロードキャスト(全審査員)と個別送信の両方をサポート

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
    case connect(ipAddress: String)
    case disconnect(ipAddress: String)
    case scorer(judgeName: String, entryNumber: String, score: Float?)
    case update(judgeName: String, scores: [String: Float?])
    case currentNumber(number: Int)
    case requestUpdate
}
```

ワイヤーフォーマット（スラッシュ区切りの文字列）:
- `EDITING/{judgeName}/{entryNumber}` - 審査員がエントリーを編集中
- `CONNECT/{ipAddress}` - 新しい審査員が接続
- `DISCONNECT/{ipAddress}` - 審査員が切断
- `SCORER/{judgeName}/{entryNumber}/{score}` - スコア更新（-1はnilとして扱う）
- `UPDATE/{judgeName}/{scoresJSON}/{stateJSON}` - 一括スコア更新
- `{number}` - 現在のエントリー番号の同期

**重要**: スコア値`-1`は自動的に`nil`に変換されます（未入力を示す）

すべての受信メッセージは重複排除追跡用にUUIDが付加されます。

### メッセージ処理アーキテクチャ

**MessageHandler.swift** (新規追加):
- 受信メッセージを型安全に処理
- `NetworkMessage.parse()`でメッセージをパース
- 各メッセージタイプに応じた専用ハンドラで処理
- `@Published`プロパティでUI状態を管理:
  - `currentMessage`: 現在編集中のメッセージ
  - `currentNumber`: 現在のエントリー番号

**設計思想**:
- MainViewからメッセージ処理ロジックを完全に分離（213行→7行に削減）
- 型安全性により実行時エラーを削減
- 関心の分離によりテストとメンテナンスが容易

### データモデル

**ScoreModel.swift**:
- ネストされた辞書構造: `[judgeName: [entryNumber: score]]`
- **型**: `Dictionary<String, Dictionary<String, Float?>>` （Optional型でnilを明示的に表現）
- 5秒ごとにUserDefaultsへ自動保存
- **重要**: スコア`nil`は未入力を示す（保存時は`-1`に変換して後方互換性を維持）
- `AppConfiguration.StorageKeys.scores`キーで永続化

主要メソッド:
- `getScore(in:for:)`: Optional<Float>のBindingを返す
- `update(forKey:scores:)`: Float版スコア辞書を受け取り変換（互換性用）
- `updateOptional(forKey:scores:)`: Optional<Float>版を直接受け取る

**JudgeIpModel.swift**:
- 審査員名とIPアドレスのマッピング
- 重複する審査員名やIPを防止
- `AppConfiguration.StorageKeys.hostAddresses`キーで永続化

### 設定管理

**AppConfiguration.swift** (新規追加):
- アプリケーション全体の設定を一元管理する構造体

主要セクション:
- `Network`: ポート番号、サービスタイプなどのネットワーク設定
- `StorageKeys`: UserDefaultsキーの定義
- `Judges`: 審査員の設定（デフォルト4名）
- `Colors`: UI色定義
- `CompetitionMode`: 競技モード（solo/dual）

後方互換性のため`Const`クラスをラッパーとして提供。

### デバイス固有の動作

`UIDevice.current.isiPad`でデバイスタイプを検出:

**iPad (ホストモード)**:
- ナビゲーションコントロール付きの完全な審査インターフェース
- ポート9000でUDPリスナー起動
- 複数の審査員デバイスに接続可能
- エントリーをナビゲートする上下矢印を表示

**iPhone (審査員/セカンダリモード)**:
- シンプルなインターフェース
- デュアルリスナー(ポート8000と9000)
- ホストと審査員の両方として機能可能

### ビュー構造

```
MainView (ルート)
├── JudgeView - スコア付きの全審査員列を表示
│   └── EntryListItemView - 個別のエントリー行
├── PrincipalIcon - リセット機能付きのツールバーアイコン
└── HostSelectModalView - 審査員IPアドレスを管理するモーダル
```

ビューは以下に整理:
- `View/Component/` - 再利用可能なUIコンポーネント
- `View/Phone/` - iPhone専用ビュー
- `View/` - メインビュー

### ディレクトリ構造

```
nexthouselab-host/
├── Model/
│   ├── AppConfiguration.swift    # 設定管理（新規）
│   ├── MessageHandler.swift      # メッセージ処理（新規）
│   ├── NetworkMessage.swift      # 型安全なメッセージ定義（新規）
│   ├── ScoreModel.swift          # スコアデータ管理
│   ├── EntryName.swift
│   ├── JudgeName.swift
│   └── Message.swift
├── Socket/
│   ├── SocketManager.swift       # UDPネットワーク管理
│   └── PeerManager.swift         # MultipeerConnectivity（未統合）
├── View/
│   ├── MainView.swift
│   ├── Component/
│   └── Phone/
└── Ex/
    ├── UIDeviceEx.swift
    ├── TrackableList.swift
    └── DocumentPickerView.swift
```

## 主要な技術詳細

### 並行処理パターン
- ネットワーク操作は`DispatchGroup`で並列送信
- `DispatchSemaphore`で同期的な接続確立
- リスナーにはバックグラウンドキュー、UI更新にはメインキュー
- タイマーベースの自動保存 (5秒間隔)

### 状態同期
- ホストは現在のエントリー番号を全審査員にブロードキャスト
- 審査員はスコア更新をホストに送信
- `storedData`辞書がUUIDキーでメッセージキューを保持
- 5秒タイマーで未処理メッセージを再試行

### データ永続化
すべてのデータはUserDefaultsに保存:
- `scores`: 完全なスコアマトリックス（nil値は-1として保存）
- `host_key`: 審査員名とIPマッピング
- `selected_file_cocntents`: インポートしたファイル内容
- ファイルベースの永続化なし

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
   - タイポ修正: `listenerState`, `receivedData`, `broadcastIp`, `updatedTime`
   - 約130行のコメントアウトコードを削除
   - 重複コードの統合

4. **Enum命名の統一**
   - `CompetitionMode`: `.Solo`/`.Dual` → `.solo`/`.dual`（小文字に統一）

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

### テスト
- `MessageHandler`, `NetworkMessage`, `ScoreModel`は独立してテスト可能
- ViewとModelが分離されているためユニットテストが容易

### 既知の技術的負債
- `PeerManager`が未統合（SocketManagerとの選択・統合が必要）
- MainView.swiftにモード選択をUI経由で動的にする旨のTODO
- UserDefaultsへの直接依存（テスト時にモック化が困難）

## 推奨される今後の改善

1. **UserDefaults Repository の作成** - テスト容易性の向上
2. **PeerManagerの統合判断** - SocketManagerとの統合または削除
3. **審査員数の動的変更** - UI経由での変更を可能に
4. **エクスポートジャンルの設定可能化** - ハードコードの解消

## 開発環境

- SwiftUI
- iOS デプロイメントターゲット: 17.4以上
- 外部依存関係: なし
- Network Framework (`import Network`) 使用
- MultipeerConnectivity Framework（オプション）
- 日本語ローカライズ対応
