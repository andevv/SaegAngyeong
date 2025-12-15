//
//  Comment.swift
//  SaegAngyeong
//
//  Created by andev on 12/15/25.
//

import Foundation

struct Comment {
    let id: String
    let parentCommentID: String?
    let content: String
    let creator: UserSummary
    let createdAt: Date
    let replies: [Comment]
}

struct CommentDraft {
    let parentCommentID: String?
    let content: String
}
