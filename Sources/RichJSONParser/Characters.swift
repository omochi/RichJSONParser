internal extension UInt8 {
    static let doubleQuote = UInt8(0x22)
    static let backSlash = UInt8(0x5C)
    static let backSpace = UInt8(0x08)
    static let formFeed = UInt8(0x0C)
    static let cr = UInt8(0x0D)
    static let lf = UInt8(0x0A)
    static let tab = UInt8(0x09)
}

internal extension Unicode.Scalar {
    static let backSpace = Unicode.Scalar(.backSpace)
    static let formFeed = Unicode.Scalar(.formFeed)
    
    static let cr = Unicode.Scalar(.cr)
    static let lf = Unicode.Scalar(.lf)
    static let tab = Unicode.Scalar(.tab)
    static let space = Unicode.Scalar(0x20)!
    
    static let doubleQuote = Unicode.Scalar(.doubleQuote)
    
    static let plus = Unicode.Scalar(0x2B)!
    static let minus = Unicode.Scalar(0x2D)!
    static let star = Unicode.Scalar(0x2A)!
    static let slash = Unicode.Scalar(0x2F)!
    static let comma = Unicode.Scalar(0x2C)!
    static let dot = Unicode.Scalar(0x2E)!
    static let colon = Unicode.Scalar(0x3A)!
    static let backSlash = Unicode.Scalar(.backSlash)
    static let leftBracket = Unicode.Scalar(0x5B)!
    static let rightBracket = Unicode.Scalar(0x5D)!
    static let leftBrace = Unicode.Scalar(0x7B)!
    static let rightBrace = Unicode.Scalar(0x7D)!
    
    static let num0 = Unicode.Scalar(0x30)!
    static let num1 = Unicode.Scalar(0x31)!
    static let num9 = Unicode.Scalar(0x39)!
    
    static let alphaSA = Unicode.Scalar(0x61)!
    static let alphaSB = Unicode.Scalar(0x62)!
    static let alphaSE = Unicode.Scalar(0x65)!
    static let alphaSF = Unicode.Scalar(0x66)!
    static let alphaSN = Unicode.Scalar(0x6e)!
    static let alphaSR = Unicode.Scalar(0x72)!
    static let alphaST = Unicode.Scalar(0x74)!
    static let alphaSU = Unicode.Scalar(0x75)!
    static let alphaSZ = Unicode.Scalar(0x7A)!
    
    static let alphaLA = Unicode.Scalar(0x41)!
    static let alphaLE = Unicode.Scalar(0x45)!
    static let alphaLF = Unicode.Scalar(0x46)!
    static let alphaLZ = Unicode.Scalar(0x5A)!
    
    func isDigit() -> Bool {
        return .num0 <= self && self <= .num9
    }
    
    func isDigit1To9() -> Bool {
        return .num1 <= self && self <= .num9
    }
    
    func isHex() -> Bool {
        return isDigit() ||
            .alphaSA <= self && self <= .alphaSF ||
            .alphaLA <= self && self <= .alphaLF
    }
    
    func hexValue() -> Int? {
        if .num0 <= self && self <= .num9 {
            return Int(self.value - Unicode.Scalar.num0.value)
        } else if .alphaSA <= self && self <= .alphaSF {
            return 10 + Int(self.value - Unicode.Scalar.alphaSA.value)
        } else if .alphaLA <= self && self <= .alphaLF {
            return 10 + Int(self.value - Unicode.Scalar.alphaLA.value)
        } else {
            return nil
        }
    }
    
    func isAlpha() -> Bool {
        return .alphaSA <= self && self <= .alphaSZ ||
            .alphaLA <= self && self <= .alphaLZ
    }
    
    func isControlCode() -> Bool {
        let x = self.value
        
        return 0x00 <= x && x <= 0x1F ||
            x == 0x7F ||
            0x80 <= x && x <= 0x9F
    }
}

