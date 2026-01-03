# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

NHL-Judge-Systemは、ダンス/パフォーマンスコンテストの審査を支援するリアルタイム採点システムです。SwiftUIで構築された2つのiOS/iPadOSアプリケーションで構成され、UDPネットワーク通信を介して複数の審査員デバイスとホストデバイス間でスコアをリアルタイムに同期します。

## システム構成

このリポジトリには2つの独立したXcodeプロジェクトが含まれています:

### 1. nexthouselab-host (ホストアプリ)
**場所**: `src/nexthouselab-host/`

中央ホスト/マスターデバイスとして機能し、複数の審査員からスコアを集約します。

- **役割**: スコア集約、審査員間の同期、データ管理
- **ネットワーク**: ポート9000でリッスン、ポート8000で審査員に接続
- **主な機能**:
  - 複数審査員デバイスからのリアルタイムスコア受信
  - 現在のエントリー番号を全審査員に同期
  - スコアマトリックスの管理と永続化
  - 審査員IPアドレス管理

### 2. nexthouselab-judge (審査員アプリ)
**場所**: `src/nexthouselab-judge/`

審査員が使用するクライアントデバイスアプリケーションです。

- **役割**: スコア入力、ホストへの送信
- **ネットワーク**: ポート8000で受信、ポート9000でホストに送信
- **主な機能**:
  - 0-10の範囲で0.5刻みのスコア入力
  - CSVファイルから出場者リストをインポート
  - リアルタイムでホストにスコア送信
  - ソロ/デュアルモード対応

## 技術スタック

- **フレームワーク**: SwiftUI
- **対応OS**: iOS/iPadOS 17.4以上
- **ネットワーク**: UDPベースのカスタムプロトコル (Network Framework)
- **状態管理**: 環境オブジェクト (`SocketManager`, `ScoreModel`, `MessageHandler`)
- **データ永続化**: UserDefaults
- **ローカライゼーション**: 日本語・英語対応
- **依存関係**: R.swift (審査員アプリのみ、リソース型安全性)

## ビルド方法

各プロジェクトは独立してビルドできます:

```bash
# ホストアプリ
cd src/nexthouselab-host
xcodebuild -scheme nexthouselab-host -configuration Debug build

# 審査員アプリ
cd src/nexthouselab-judge
xcodebuild -scheme nexthouselab-judge -configuration Debug build
```

または、Xcodeで各プロジェクトファイルを直接開いてビルド・実行してください。

## アーキテクチャの特徴

### 共通アーキテクチャ
両アプリケーションは以下の共通設計パターンを採用:

- **型安全なメッセージプロトコル**: `NetworkMessage` enumによる型安全な通信
- **設定の一元管理**: `AppConfiguration`構造体で設定を集中管理
- **責務の分離**: `MessageHandler`でメッセージ処理ロジックを分離
- **スコアのNull安全性**: `Float?`型でnilを明示的に表現（マジックナンバー`-1`を排除）

### ネットワークプロトコル
**MultipeerConnectivity**ベースの自動ピア検出システム:
- Bonjourサービスディスカバリーによる自動検出
- サービスタイプ: `"judge-session"`
- 暗号化必須（MCSessionの`encryptionPreference: .required`）
- スラッシュ区切りの文字列メッセージ（NetworkMessage enum）
- スコア更新、編集状態、同期リクエストなどをサポート
- スコア`nil`はワイヤー上で`-1`として送信

## ディレクトリ構造

```
NHL-Judge-System/
├── src/
│   ├── nexthouselab-host/          # ホストアプリ
│   │   ├── nexthouselab-host.xcodeproj
│   │   ├── nexthouselab-host/
│   │   │   ├── Model/              # データモデル、設定、メッセージ処理
│   │   │   ├── Socket/             # ネットワーク管理
│   │   │   ├── View/               # SwiftUI ビュー
│   │   │   └── Ex/                 # 拡張機能
│   │   └── CLAUDE.md               # ホストアプリの詳細ドキュメント
│   └── nexthouselab-judge/         # 審査員アプリ
│       ├── nexthouselab-judge.xcodeproj
│       ├── nexthouselab-judge/
│       │   ├── Model/              # データモデル、設定、メッセージ処理
│       │   ├── Socket/             # ネットワーク管理
│       │   ├── View/               # SwiftUI ビュー
│       │   └── Resources/          # ローカライゼーションリソース
│       └── CLAUDE.md               # 審査員アプリの詳細ドキュメント
└── CLAUDE.md                       # このファイル（プロジェクト全体の概要）
```

## 開発履歴

### 2025年1月 大規模リファクタリング
両プロジェクトで以下の改善を実施:
- 型安全性の向上（`NetworkMessage` enum、`Optional<Float>`）
- アーキテクチャの改善（`MessageHandler`、`AppConfiguration`の導入）
- コード品質の改善（タイポ修正、デッドコード削除）
- スレッドセーフティ問題の修正

### 2025年11月 UDP → MultipeerConnectivity 完全移行（✅完了）

**移行の目的**: 手動IP入力を廃止し、自動ピア検出による接続を実現

**完了した全作業**:

1. **Phase 1-2: 基本アーキテクチャ構築**
   - `JudgePeerModel`作成（審査員名↔MCPeerIDマッピング管理）
   - `PeerManager`にJudgePeerModel連携機能追加
   - `AppConfiguration`更新（UDP設定削除、MultipeerConnectivity設定追加）
   - 未使用SocketManager宣言削除（4ファイル）

2. **Phase 3: 基本View更新**
   - Judge `HomeView`更新（自動ホスト検索開始）
   - Host `PhoneMainView`更新（MessageHandler統合）

3. **Phase 4: UI完全再設計**
   - `SelectHostView`再設計（Judge側）
     - IP入力削除 → 自動ホスト検出・接続
     - シンプルな接続状態表示
   - `HostSelectModalView`再設計（Host側）
     - IP入力・Picker削除 → 接続済み審査員リスト表示
     - シンプルな接続状態表示
   - `HomeAlertModifier`更新（IP入力エラーケース削除）

4. **Phase 5: JudgeView更新**
   - SocketManager依存削除
   - PeerManager経由でブロードキャスト送信に変更
   - UPDATE メッセージ送信を全審査員に一斉送信

5. **Phase 6: JudgeIpModel削除**
   - `JudgeIpModel`クラス全体削除（47行）
   - `Const.IP_KEY`, `Const.HOST_KEY`削除

6. **Phase 7: 環境オブジェクト追加**
   - Host側App.swiftに`JudgePeerModel`を@StateObjectとして追加
   - PeerManagerとJudgePeerModelの依存関係を設定

7. **Phase 8: ドキュメント更新**
   - 各プロジェクトのCLAUDE.md更新（この作業）

**主要な変更点**:
- ネットワーク層: UDP（SocketManager）→ MultipeerConnectivity（PeerManager）
- 審査員識別: IPアドレス → MCPeerID + 審査員名マッピング
- 接続方法: 手動IP入力 → 自動ピア検出
- UI: IP入力フィールド → 自動検出されたピア/ホストのリスト表示
- UPDATE送信: 個別送信 → ブロードキャスト送信

**削除されたコンポーネント**:
- `SocketManager` クラス（Host/Judge両方）
- `JudgeIpModel` クラス（Host側のみ）
- IP入力UI（両側）
- IP検証ロジック（両側）

**追加されたコンポーネント**:
- `JudgePeerModel` クラス（Host側のみ）
- 自動ピア検出UI（両側）

**現在の制限事項**:
- UPDATE送信はブロードキャスト（全審査員に一斉送信）
- 審査員の個別切断機能は未実装（表示のみ）
- 接続品質モニタリングは未実装

## 詳細情報

各アプリケーションの詳細なアーキテクチャ、API、開発ガイドラインについては、それぞれのCLAUDE.mdを参照してください:
- ホストアプリ: `src/nexthouselab-host/CLAUDE.md`
- 審査員アプリ: `src/nexthouselab-judge/CLAUDE.md`

## Xcodeプロジェクトファイル管理

**重要**: ファイルの追加・削除を行った際は、必ずXcodeプロジェクトファイル（`.xcodeproj`）も更新してください。

### Claude Codeへの指示

**ファイル追加・削除時のルール**:
1. タスク完了時に、追加・削除したファイルのリストを**必ず報告**する
2. ユーザーが手動でXcodeプロジェクトファイルを更新する
3. 報告フォーマット：
   ```
   【Xcodeプロジェクト更新が必要】

   追加ファイル:
   - path/to/NewFile.swift (プロジェクト名)

   削除ファイル:
   - path/to/OldFile.swift (プロジェクト名)
   ```

### ファイル追加・削除時の手順（ユーザー用）

1. **ファイル操作後、Xcodeで確認**:
   ```bash
   # Hostプロジェクト
   open src/nexthouselab-host/nexthouselab-host.xcodeproj

   # Judgeプロジェクト
   open src/nexthouselab-judge/nexthouselab-judge.xcodeproj
   ```

2. **新規ファイルの追加**:
   - Xcodeのプロジェクトナビゲーターで右クリック → "Add Files to..."
   - ファイルを選択し、適切なターゲットにチェックを入れる
   - "Copy items if needed"のチェックを**外す**（既にプロジェクト内にあるため）

3. **削除されたファイルの除去**:
   - Xcodeのプロジェクトナビゲーターで赤く表示されているファイルを右クリック
   - "Delete" → "Remove Reference"を選択（ファイルシステムからは削除しない）

4. **ビルドテスト**:
   ```bash
   cd src/nexthouselab-host && xcodebuild -scheme nexthouselab-host clean build
   cd src/nexthouselab-judge && xcodebuild -scheme nexthouselab-judge clean build
   ```

### Xcodeプロジェクトへの反映が必要なファイル

**新規追加**:
- `src/nexthouselab-host/nexthouselab-host/Model/JudgePeerModel.swift` ← **要追加**
- `src/nexthouselab-host/nexthouselab-host/Socket/PeerManager.swift` ← 登録済み
- `src/nexthouselab-judge/nexthouselab-judge/Socket/PeerManager.swift` ← 登録済み

**削除**:
- `src/nexthouselab-host/nexthouselab-host/Socket/SocketManager.swift` ← **要除去**
- `src/nexthouselab-judge/nexthouselab-judge/Socket/SocketManager.swift` ← **要除去**

**手順**:
1. Xcodeで各プロジェクトを開く
2. JudgePeerModel.swiftを追加（Host側のみ）
3. SocketManager.swiftの参照を削除（両プロジェクト）
4. ビルドして動作確認

## Git管理

現在のブランチ: main

プロジェクトファイルとSocket関連の新規ファイルが未コミット状態です。
