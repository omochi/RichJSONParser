import Foundation

public final class StaticBuffer {
    public private(set) var memory: UnsafeMutablePointer<UInt8>
    public var capacity: Int
    public private(set) var current: Int

    public init(capacity: Int) {
        let capacity = max(16, capacity)
        self.memory = UnsafeMutablePointer<UInt8>.allocate(capacity: capacity)
        self.capacity = capacity
        self.current = 0
    }
    
    deinit {
        memory.deallocate()
    }
    
    public func write(byte: UInt8) {
        if current == self.capacity {
            expand()
        }

        memory.advanced(by: current).pointee = byte
        current += 1
    }
    
    private func expand() {
        let newCapacity = capacity * 2
        let newMemory = UnsafeMutablePointer<UInt8>.allocate(capacity: newCapacity)
        newMemory.assign(from: memory, count: current)
        
        self.memory.deallocate()
        self.memory = newMemory
        self.capacity = newCapacity
    }
}
