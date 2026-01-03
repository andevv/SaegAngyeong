//
//  BaseViewModel.swift
//  SaegAngyeong
//
//  Created by andev on 12/14/25.
//

import Combine

/// 모든 ViewModel이 채택하는 기본 프로토콜
protocol ViewModelType {
    associatedtype Input
    associatedtype Output

    func transform(input: Input) -> Output
}

/// 공통 기능을 제공하는 베이스 ViewModel (선택적 상속)
class BaseViewModel {

    // MARK: - Common Outputs
    let isLoading = PassthroughSubject<Bool, Never>()
    let error = PassthroughSubject<Error, Never>()

    // MARK: - Combine
    var cancellables = Set<AnyCancellable>()

    init() {}

    deinit {
        #if DEBUG
        print("[Deinit][VM] \(type(of: self))")
        #endif
    }
}
