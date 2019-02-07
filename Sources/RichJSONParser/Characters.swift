internal extension UInt8 {
    static let backSpace = UInt8(0x08)
    static let tab = UInt8(0x09)
    static let lf = UInt8(0x0A)
    static let formFeed = UInt8(0x0C)
    static let cr = UInt8(0x0D)
    static let space = UInt8(0x20)
    static let doubleQuote = UInt8(0x22)
    static let star = UInt8(0x2A)
    static let plus = UInt8(0x2B)
    static let comma = UInt8(0x2C)
    static let minus = UInt8(0x2D)
    static let dot = UInt8(0x2E)
    static let slash = UInt8(0x2F)
    
    static let num0 = UInt8(0x30)
    static let num1 = UInt8(0x31)
    static let num2 = UInt8(0x32)
    static let num3 = UInt8(0x33)
    static let num4 = UInt8(0x34)
    static let num5 = UInt8(0x35)
    static let num6 = UInt8(0x36)
    static let num7 = UInt8(0x37)
    static let num8 = UInt8(0x38)
    static let num9 = UInt8(0x39)
    
    static let colon = UInt8(0x3A)
    
    static let alLA = UInt8(0x41)
    static let alLE = UInt8(0x45)
    static let alLF = UInt8(0x46)
    
    static let leftBracket = UInt8(0x5B)
    static let backSlash = UInt8(0x5C)
    static let rightBracket = UInt8(0x5D)
    static let leftBrace = UInt8(0x7B)
    static let rightBrace = UInt8(0x7D)
    
    static let alSA = UInt8(0x61)
    static let alSB = UInt8(0x62)
    static let alSE = UInt8(0x65)
    static let alSF = UInt8(0x66)
    static let alSL = UInt8(0x6C)
    static let alSN = UInt8(0x6e)
    static let alSR = UInt8(0x72)
    static let alSS = UInt8(0x73)
    static let alST = UInt8(0x74)
    static let alSU = UInt8(0x75)
    static let alSZ = UInt8(0x7A)
    
    var isDigit: Bool {
        return .num0 <= self && self <= .num9
    }
    
    var isDigit1To9: Bool {
        return .num1 <= self && self <= .num9
    }
    
    var isHex: Bool {
        return isDigit ||
            .alSA <= self && self <= .alSF ||
            .alLA <= self && self <= .alLF
    }
    
    var hexValue: UInt8? {
        if .num0 <= self && self <= .num9 {
            return self - .num0
        } else if .alSA <= self && self <= .alSF {
            return 10 + (self - .alSA)
        } else if .alLA <= self && self <= .alLF {
            return 10 + (self - .alLA)
        } else {
            return nil
        }
    }
    
    var isControlCode: Bool {
        return 0x00 <= self && self <= 0x1F ||
            self == 0x7F
    }
    
    var isPrintable: Bool {
        return 0x20 <= self && self <= 0x7E
    }


}

internal extension Unicode.Scalar {
    static let backSpace = Unicode.Scalar(.backSpace)
    static let tab = Unicode.Scalar(.tab)
    static let lf = Unicode.Scalar(.lf)
    static let formFeed = Unicode.Scalar(.formFeed)
    static let cr = Unicode.Scalar(.cr)
    
    static let space = Unicode.Scalar(.space)
    static let doubleQuote = Unicode.Scalar(.doubleQuote)
    static let star = Unicode.Scalar(.star)
    static let plus = Unicode.Scalar(.plus)
    static let comma = Unicode.Scalar(.comma)
    static let minus = Unicode.Scalar(.minus)
    static let dot = Unicode.Scalar(.dot)
    static let slash = Unicode.Scalar(.slash)

    static let num0 = Unicode.Scalar(.num0)
    static let num1 = Unicode.Scalar(.num1)
    static let num9 = Unicode.Scalar(.num9)
    static let colon = Unicode.Scalar(.colon)
    
    static let alphaLA = Unicode.Scalar(0x41)!
    static let alphaLE = Unicode.Scalar(.alLE)
    static let alphaLF = Unicode.Scalar(0x46)!
    static let alphaLZ = Unicode.Scalar(0x5A)!
    
    static let backSlash = Unicode.Scalar(.backSlash)
    static let leftBracket = Unicode.Scalar(.leftBracket)
    static let rightBracket = Unicode.Scalar(.rightBracket)

    static let alphaSA = Unicode.Scalar(.alSA)
    static let alphaSB = Unicode.Scalar(.alSB)
    static let alphaSE = Unicode.Scalar(.alSE)
    static let alphaSF = Unicode.Scalar(.alSF)
    static let alphaSN = Unicode.Scalar(.alSN)
    static let alphaSR = Unicode.Scalar(.alSR)
    static let alphaST = Unicode.Scalar(.alST)
    static let alphaSU = Unicode.Scalar(.alSU)
    static let alphaSZ = Unicode.Scalar(.alSZ)
    static let leftBrace = Unicode.Scalar(.leftBrace)
    static let rightBrace = Unicode.Scalar(.rightBrace)
    
    var isDigit: Bool {
        return .num0 <= self && self <= .num9
    }
    
    var isDigit1To9: Bool {
        return .num1 <= self && self <= .num9
    }
    
    var isHex: Bool {
        return isDigit ||
            .alphaSA <= self && self <= .alphaSF ||
            .alphaLA <= self && self <= .alphaLF
    }
    
    var hexValue: Int? {
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
    
    var isAlpha: Bool {
        return .alphaSA <= self && self <= .alphaSZ ||
            .alphaLA <= self && self <= .alphaLZ
    }
    
    var isControlCode: Bool {
        let x = self.value
        
        return 0x00 <= x && x <= 0x1F ||
            x == 0x7F ||
            0x80 <= x && x <= 0x9F
    }
    
    var surrogatePair: (high: UInt32, low: UInt32)? {
        let x = self.value
        guard x > 0xFFFF else {
            return nil
        }
        
        let high = 0xD800 + (x - 0x10000) >> 10
        let low = 0xDC00 + (x - 0x10000) & 0x03FF
        return (high: high, low: low)
    }
}

internal extension UInt32 {
    var isHighSurrogate: Bool {
        let x = self
        
        return 0xD800 <= x && x <= 0xDBFF
    }
    
    var isLowSurrogate: Bool {
        let x = self
        
        return 0xDC00 <= x && x <= 0xDFFF
    }
    
    static func combineSurrogates(high: UInt32, low: UInt32) -> UInt32 {
        return 0x10000 +
            (high - 0xD800) << 10 +
            (low - 0xDC00)
    }
}
