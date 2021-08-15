//
//  OnlyFrequency.swift
//  
//
//  Created by Aris Sarris on 15/8/21.
//

import Foundation

typealias OnlyKey = RawRepresentable & CaseIterable

enum OnlyFrequency<T: OnlyKey> where T.RawValue == String {
    case once(T)
    case oncePerSession(T)
    case ifTimePassed(T, DispatchTimeInterval)
    case `if`(() -> Bool)
    case every(T, times: Int)
}
