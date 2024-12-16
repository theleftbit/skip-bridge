// Copyright 2024 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

/// Protocol added to compiled Swift types that are bridged to Kotlin.
public protocol BridgedToKotlin: JObjectProtocol, JConvertible {
}

/// Protocol added to compiled Swift projections generated from bridged Kotlin types.
public protocol BridgedFromKotlin: JObjectProtocol, JConvertible {
}

/// An opaque reference to a Swift object.
public typealias SwiftObjectPointer = Int64
public let SwiftObjectNil = Int64(0)

extension SwiftObjectPointer {
    /// Get a pointer to the given object.
    public static func pointer<T: AnyObject>(to object: T?, retain: Bool) -> SwiftObjectPointer {
        guard let object else {
            return SwiftObjectNil
        }
        let unmanaged = retain ? Unmanaged.passRetained(object) : Unmanaged.passUnretained(object)
        let rawPtr = unmanaged.toOpaque()
        return SwiftObjectPointer(Int(bitPattern: rawPtr))
    }

    /// Return the object for this pointer.
    public func pointee<T: AnyObject>() -> T? {
        guard self != SwiftObjectNil else {
            return nil
        }
        let rawPtr = UnsafeMutableRawPointer(bitPattern: Int(self))!
        return Unmanaged<T>.fromOpaque(rawPtr).takeUnretainedValue()
    }

    /// Increment the reference count for a Swift object held by Java.
    public func retained<T: AnyObject>(as type: T.Type) -> SwiftObjectPointer {
        guard self != SwiftObjectNil, let rawPtr = UnsafeMutableRawPointer(bitPattern: Int(self)) else {
            return self
        }
        let unmanaged = Unmanaged<T>.fromOpaque(rawPtr)
        let refUnmanaged = unmanaged.retain()
        return SwiftObjectPointer(Int(bitPattern: refUnmanaged.toOpaque()))
    }

    /// Decrement the reference count for a Swift object held by Java.
    public func release<T: AnyObject>(as type: T.Type) {
        guard self != SwiftObjectNil, let rawPtr = UnsafeMutableRawPointer(bitPattern: Int(self)) else {
            return
        }
        let unmanaged = Unmanaged<T>.fromOpaque(rawPtr)
        unmanaged.release()
    }
}

extension SwiftObjectPointer {
    /// Return the `Swift_peer` of the given `SwiftPeerBridged` Kotlin object.
    public static func peer(of bridged: JavaObjectPointer, options: JConvertibleOptions) -> SwiftObjectPointer {
        return try! SwiftObjectPointer.call(Java_PeerBridged_peer_methodID, on: bridged, options: options, args: [])
    }

    /// Return the `Swift_peer` of the given Kotlin object if it is `SwiftPeerBridged`.
    public static func tryPeer(of object: JavaObjectPointer, options: JConvertibleOptions) -> SwiftObjectPointer? {
        let object_java = object.toJavaParameter(options: options)
        let ptr: SwiftObjectPointer = try! Java_fileClass.callStatic(method: Java_tryPeer_methodID, options: options, args: [object_java])
        return ptr == SwiftObjectNil ? nil : ptr
    }
}
private let Java_fileClass = try! JClass(name: "skip/bridge/kt/BridgeSupportKt")
private let Java_tryPeer_methodID = Java_fileClass.getStaticMethodID(name: "Swift_peer", sig: "(Ljava/lang/Object;)J")!
private let Java_PeerBridged_class = try! JClass(name: "skip/bridge/kt/SwiftPeerBridged")
private let Java_PeerBridged_peer_methodID = Java_PeerBridged_class.getMethodID(name: "Swift_peer", sig: "()J")!

/// Reference type to hold a value type.
public final class SwiftValueTypeBox<T> {
    public var value: T

    public init(_ value: T) {
        self.value = value
    }
}

/// Added to non-final base classes to help handle polymorphism in `JConvertible`.
public protocol BridgedToKotlinBaseClass: AnyObject {
}

extension BridgedToKotlinBaseClass {
    /// Return the appropriate constructor to use to create the Kotlin/Java peer of this instance.
    public func Java_findConstructor(base baseClass: JClass, _ baseMethodID: JavaMethodID) -> (cls: JClass, ctor: JavaMethodID) {
        let selfType = type(of: self)
        if let subclass3 = selfType as? BridgedToKotlinSubclass3.Type {
            return subclass3.Java_subclass3Constructor
        } else if let subclass2 = selfType as? BridgedToKotlinSubclass2.Type {
            return subclass2.Java_subclass2Constructor
        } else if let subclass1 = selfType as? BridgedToKotlinSubclass1.Type {
            return subclass1.Java_subclass1Constructor
        } else {
            return (baseClass, baseMethodID)
        }
    }
}

/// Added to first-level subclasses to help handle polymorphism in `BridgedToKotlin` instances.
public protocol BridgedToKotlinSubclass1: AnyObject {
    static var Java_subclass1Constructor: (JClass, JavaMethodID) { get }
}

/// Added to second-level subclasses to help handle polymorphism in `BridgedToKotlin` instances.
public protocol BridgedToKotlinSubclass2: AnyObject {
    static var Java_subclass2Constructor: (JClass, JavaMethodID) { get }
}

/// Added to third-level subclasses to help handle polymorphism in `BridgedToKotlin` instances.
public protocol BridgedToKotlinSubclass3: AnyObject {
    static var Java_subclass3Constructor: (JClass, JavaMethodID) { get }
}
