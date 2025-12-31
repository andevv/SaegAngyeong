//
//  PaymentDTOs.swift
//  SaegAngyeong
//
//  Created by andev on 12/31/25.
//

import Foundation

struct PaymentValidationRequestDTO: Encodable {
    let impUID: String

    enum CodingKeys: String, CodingKey {
        case impUID = "imp_uid"
    }
}

struct ReceiptOrderResponseDTO: Decodable {
    let paymentID: String

    enum CodingKeys: String, CodingKey {
        case paymentID = "payment_id"
    }
}
