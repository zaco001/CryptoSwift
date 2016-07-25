//
//  PBKDF1.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 07/06/16.
//  Copyright © 2016 Marcin Krzyzanowski. All rights reserved.
//

public extension PKCS5 {

    /// A key derivation function.
    ///
    /// PBKDF1 is recommended only for compatibility with existing
    /// applications since the keys it produces may not be large enough for
    /// some applications.
    public struct PBKDF1 {

        public enum ErrorProblem: Error {
            case invalidInput
            case derivedKeyTooLong
        }

        public enum Variant {
            case md5, sha1

            var size:Int {
                switch (self) {
                case .md5:
                    return MD5.size
                case .sha1:
                    return SHA1.size
                }
            }

            private func calculateHash(_ bytes:Array<UInt8>) -> Array<UInt8>? {
                switch (self) {
                case .sha1:
                    return Hash.sha1(bytes).calculate()
                case .md5:
                    return Hash.md5(bytes).calculate()
                }
            }
        }

        private let iterations: Int // c
        private let variant: Variant
        private let keyLength: Int
        private let t1: Array<UInt8>

        /// - parameters:
        ///   - salt: salt, an eight-bytes
        ///   - variant: hash variant
        ///   - iterations: iteration count, a positive integer
        ///   - keyLength: intended length of derived key
        public init(password: Array<UInt8>, salt: Array<UInt8>, variant: Variant = .sha1, iterations: Int = 4096 /* c */, keyLength: Int? = nil /* dkLen */) throws {
            precondition(iterations > 0)
            precondition(salt.count == 8)
            
            let keyLength = keyLength ?? variant.size

            if (keyLength > variant.size) {
                throw ErrorProblem.derivedKeyTooLong
            }

            guard let t1 = variant.calculateHash(password + salt) else {
                throw ErrorProblem.invalidInput
            }

            self.iterations = iterations
            self.variant = variant
            self.keyLength = keyLength
            self.t1 = t1
        }

        /// Apply the underlying hash function Hash for c iterations
        public func calculate() -> Array<UInt8> {
            var t = t1
            for _ in 2...self.iterations {
                t = self.variant.calculateHash(t)!
            }
            return Array(t[0..<self.keyLength])
        }
    }
}