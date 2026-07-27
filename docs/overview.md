# Overview

## Toruto とは

「簡単に、手軽に、おしゃれなカメラ体験」を提供する iPhone 専用カメラアプリ。

写真加工アプリではなく、**カメラを選ぶ楽しさ**を提供するアプリ。
その日の気分でカメラを着替える体験を目指す。

撮った瞬間に完成した一枚を残せることを大切にする。

## ブランドキーワード

- Simple
- Stylish
- Fun
- Everyday
- Pocket Camera
- Digital Camera
- Film Camera

## MVP 機能

| 機能 | 内容 |
|---|---|
| リアルタイムカメラ | AVFoundation によるライブプレビュー |
| フィルター | 撮影時点でリアルタイム適用（後加工なし） |
| フレーム撮影 | 画面中央のフレーム内だけを保存（Dazz Cam 方式） |
| 保存 | 加工済み画像のみを保存（元画像は残さない） |
| カメラプリセット | プリセット切り替えで撮影体験が変わる |

## 技術スタック

| 項目 | 内容 |
|---|---|
| Language | Swift |
| UI | SwiftUI |
| Camera | AVFoundation |
| Image Processing | Core Image |
| Photo Library | PhotoKit |

## 開発方針

- **撮影体験を最優先する**
- 設定よりも「すぐ撮れる」ことを重視する
- UI はシンプルで直感的に
- 加工アプリではなく「カメラアプリ」として設計する
