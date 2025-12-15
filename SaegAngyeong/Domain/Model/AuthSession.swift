//
//  AuthSession.swift
//  SaegAngyeong
//
//  Created by andev on 12/15/25.
//

import Foundation

struct AuthTokens {
    let accessToken: String
    let refreshToken: String
}

struct AuthSession {
    let user: UserProfile
    let tokens: AuthTokens
}
