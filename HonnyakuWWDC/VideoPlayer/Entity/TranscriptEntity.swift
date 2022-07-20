//  Transcript.swift

import Foundation

struct TranscriptEntity: Hashable, Codable {

    struct Paragraph: Hashable, Codable {
        struct Sentence: Hashable, Codable {
            var at: Int
            var text: String
        }

        var at: Int
        var sentences: [Sentence]
    }

    var language: String
    var paragraphs: [Paragraph]

    static var zero: TranscriptEntity = TranscriptEntity(language: "EN", paragraphs: [])

    static var mock: TranscriptEntity = TranscriptEntity(language: "JA", paragraphs: [Paragraph(at: 0, sentences: Array<(Int,String)>([
        (0, "♪ music ♪"), (1, "こんにちは"), (2, "WWDCへようこそ"),
        (3,"Swift Playgrounds のために設計されたガイド付き教育コンテンツを構築する方法を学びましょう。完成したサンプルコードプロジェクトにガイドを追加する方法について、一緒に考えてみましょう。"),
        (4, "学習センターにタスクを追加して、関連するコードと、学習者が自分のコードでプロジェクトを拡張することを奨励するオプションの実験タスクを表示する方法を説明します。"),
        (5,"a"),(6,"b"),(7,"c"),(8,"d"),(9,"e"),(10,"あ"),(11,"い"),(12,"う"),(13,"え"),(14,"お"),
        (25,"a"),(26,"b"),(27,"c"),(28,"d"),(29,"e"),(30,"あ"),(31,"い"),(32,"う"),(33,"え"),(34,"お"),
        (45,"a"),(46,"b"),(47,"c"),(48,"d"),(49,"e"),(50,"あ"),(51,"い"),(52,"う"),(53,"え"),(54,"お")
    ]).map { at,text in Paragraph.Sentence(at: at, text: text) })])
}
