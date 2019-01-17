internal struct DecodedUnicodeChar {
    public var codePoint: Unicode.Scalar
    public var length: Int
    
    public init(codePoint: Unicode.Scalar,
                length: Int)
    {
        self.codePoint = codePoint
        self.length = length
    }
}
