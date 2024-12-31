// Copyright 2024 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

import Foundation

//
// NOTE:
// Keep this in sync with `SkipBridgeKt.BridgedTypes`
//

/// Supported bridged type constants.
public enum BridgedTypes: String {
    case boolean_
    case byte_
    case char_
    case double_
    case float_
    case int_
    case long_
    case short_
    case string_

    case byteArray
    case date
    case list
    case map
    case result
    case set
    case uuid
    case uri

    case swiftArray
    case swiftData
    case swiftDate
    case swiftDictionary
    case swiftResult
    case swiftSet
    case swiftUUID
    case swiftURL

    case other
}

/// Utilities to convert unknown bridged objects.
public struct AnyBridging {
    /// Convert an unknown Kotlin/Java instance to its Swift projection.
    public static func fromJavaObject(_ ptr: JavaObjectPointer?, options: JConvertibleOptions, fallback: (() -> Any)? = nil) -> Any? {
        guard let ptr else {
            return nil
        }
        if let projection = tryProjection(of: ptr, options: options) {
            return projection
        }

        let bridgedTypeString = bridgedTypeString(of: ptr, options: options)
        let bridgedType = BridgedTypes(rawValue: bridgedTypeString) ?? .other
        switch bridgedType {
        case .boolean_:
            return Bool.fromJavaObject(ptr, options: options)
        case .byte_:
            return Int8.fromJavaObject(ptr, options: options)
        case .char_:
            // TODO
            // return Character.fromJavaObject(ptr, options: options)
            fatalError("Character is not yet bridgable")
        case .double_:
            return Double.fromJavaObject(ptr, options: options)
        case .float_:
            return Float.fromJavaObject(ptr, options: options)
        case .int_:
            return Int.fromJavaObject(ptr, options: options)
        case .long_:
            return Int64.fromJavaObject(ptr, options: options)
        case .short_:
            return Int16.fromJavaObject(ptr, options: options)
        case .string_:
            return String.fromJavaObject(ptr, options: options)
        case .byteArray:
            return Data.fromJavaObject(ptr, options: options)
        case .date:
            return Date.fromJavaObject(ptr, options: options)
        case .list:
            return Array<Any>.fromJavaObject(ptr, options: options)
        case .map:
            return Dictionary<AnyHashable, Any>.fromJavaObject(ptr, options: options)
        case .result:
            return Result<Any, Error>.fromJavaObject(ptr, options: options)
        case .set:
            return Array<AnyHashable>.fromJavaObject(ptr, options: options)
        case .uuid:
            return UUID.fromJavaObject(ptr, options: options)
        case .uri:
            return URL.fromJavaObject(ptr, options: options)
        case .swiftArray:
            return Array<Any>.fromJavaObject(ptr, options: options)
        case .swiftData:
            return Data.fromJavaObject(ptr, options: options)
        case .swiftDate:
            return Date.fromJavaObject(ptr, options: options)
        case .swiftDictionary:
            return Dictionary<AnyHashable, Any>.fromJavaObject(ptr, options: options)
        case .swiftResult:
            return Result<Any, Error>.fromJavaObject(ptr, options: options)
        case .swiftSet:
            return Set<AnyHashable>.fromJavaObject(ptr, options: options)
        case .swiftUUID:
            return UUID.fromJavaObject(ptr, options: options)
        case .swiftURL:
            return URL.fromJavaObject(ptr, options: options)
        case .other:
            if let fallback {
                return fallback()
            } else {
                fatalError("Unable to bridge Kotlin/Java instance \(ptr)")
            }
        }
    }

    private static func tryProjection(of ptr: JavaObjectPointer, options: JConvertibleOptions) -> Any? {
        let ptr_java = ptr.toJavaParameter(options: options)
        let options_java = options.rawValue.toJavaParameter(options: options)
        let closure_java: JavaObjectPointer? = try! Java_fileClass.callStatic(method: Java_tryProjection_methodID, options: options, args: [ptr_java, options_java])
        let closure: (() -> Any)? = SwiftClosure0.closure(forJavaObject: closure_java, options: options)
        return closure?()
    }

    private static func bridgedTypeString(of ptr: JavaObjectPointer, options: JConvertibleOptions) -> String {
        let ptr_java = ptr.toJavaParameter(options: options)
        return try! Java_fileClass.callStatic(method: Java_bridgedTypeString_methodID, options: options, args: [ptr_java])
    }
}

private let Java_fileClass = try! JClass(name: "skip/bridge/kt/BridgeSupportKt")
private let Java_tryProjection_methodID = Java_fileClass.getStaticMethodID(name: "Swift_projection", sig: "(Ljava/lang/Object;I)Lkotlin/jvm/functions/Function0;")!
private let Java_bridgedTypeString_methodID = Java_fileClass.getStaticMethodID(name: "bridgedTypeStringOf", sig: "(Ljava/lang/Object;)Ljava/lang/String;")!

//
// NOTE:
// The Kotlin version of custom converting types should conform to `SwiftCustomBridged`.
// If it also conforms to `KotlinConverting`, it should convert to and from its underlying
// Kotlin type when the `kotlincompat` option is given.
//

// MARK: Array

extension Array: JObjectProtocol, JConvertible {
    public static func fromJavaObject(_ obj: JavaObjectPointer?, options: JConvertibleOptions) -> Array<Element> {
        // let list = arr.kotlin(nocopy: true)
        let list_java: JavaObjectPointer
        if options.contains(.kotlincompat) {
            list_java = obj!
        } else {
            list_java = try! JavaObjectPointer.call(Java_SkipArray_kotlin_methodID, on: obj!, options: options, args: [true.toJavaParameter(options: options)])
        }
        let count = try! Int32.call(Java_List_size_methodID, on: list_java, options: options, args: [])
        var arr = Array<Element>()
        for i in 0..<count {
            // arr.append(list.get(i))
            let element_java = try! JavaObjectPointer?.call(Java_List_get_methodID, on: list_java, options: options, args: [i.toJavaParameter(options: options)])
            // Convert non-polymorphic JConvertibles directly, else fall back to AnyBridging
            let element: Element
            if let convertibleElement = Element.self as? JConvertible.Type, !(Element.self is AnyObject.Type) {
                element = convertibleElement.fromJavaObject(element_java, options: options) as! Element
            } else {
                element = AnyBridging.fromJavaObject(element_java, options: options) as! Element
            }
            arr.append(element)
            if let element_java {
                jni.deleteLocalRef(element_java)
            }
        }
        return arr
    }

    public func toJavaObject(options: JConvertibleOptions) -> JavaObjectPointer? {
        // let list = ArrayList(count)
        let list_java = try! Java_ArrayList.create(ctor: Java_ArrayList_constructor_methodID, options: options, args: [Int32(self.count).toJavaParameter(options: options)])
        for element in self {
            // list.add(element)
            let element_java = (element as! JConvertible).toJavaObject(options: options)
            let _ = try! Bool.call(Java_ArrayList_add_methodID, on: list_java, options: options, args: [element_java.toJavaParameter(options: options)])
            if let element_java {
                jni.deleteLocalRef(element_java)
            }
        }
        if options.contains(.kotlincompat) {
            return list_java
        } else {
            // return Array(list, nocopy: true, shared: false)
            let arr_java = try! Java_SkipArray.create(ctor: Java_SkipArray_constructor_methodID, options: options, args: [list_java.toJavaParameter(options: options), true.toJavaParameter(options: options), false.toJavaParameter(options: options)])
            return arr_java
        }
    }
}

private let Java_SkipArray = try! JClass(name: "skip/lib/Array")
private let Java_SkipArray_constructor_methodID = Java_SkipArray.getMethodID(name: "<init>", sig: "(Ljava/lang/Iterable;ZZ)V")!
private let Java_SkipArray_kotlin_methodID = Java_SkipArray.getMethodID(name: "kotlin", sig: "(Z)Ljava/util/List;")!
private let Java_ArrayList = try! JClass(name: "java/util/ArrayList")
private let Java_ArrayList_constructor_methodID = Java_ArrayList.getMethodID(name: "<init>", sig: "(I)V")!
private let Java_ArrayList_add_methodID = Java_ArrayList.getMethodID(name: "add", sig: "(Ljava/lang/Object;)Z")!
private let Java_List = try! JClass(name: "java/util/List")
private let Java_List_size_methodID = Java_List.getMethodID(name: "size", sig: "()I")!
private let Java_List_get_methodID = Java_List.getMethodID(name: "get", sig: "(I)Ljava/lang/Object;")!

// MARK: Data

extension Data: JObjectProtocol, JConvertible {
    public static func fromJavaObject(_ obj: JavaObjectPointer?, options: JConvertibleOptions) -> Data {
        let kotlinByteArray: JavaObjectPointer
        if options.contains(.kotlincompat) {
            kotlinByteArray = obj!
        } else {
            kotlinByteArray = try! JavaObjectPointer.call(Java_SkipData_kotlin_methodID, on: obj!, options: options, args: [true.toJavaParameter(options: options)])
        }
        let (bytes, length) = jni.getByteArrayElements(kotlinByteArray)
        defer { jni.releaseByteArrayElements(kotlinByteArray, elements: bytes, mode: .unpin) }
        guard let bytes else {
            return Data()
        }
        return Data(bytes: bytes, count: Int(length))
    }

    public func toJavaObject(options: JConvertibleOptions) -> JavaObjectPointer? {
        self.withUnsafeBytes { buffer in
            let kotlinByteArray = jni.newByteArray(buffer.baseAddress, size: Int32(count))!
            if options.contains(.kotlincompat) {
                return kotlinByteArray
            } else {
                return try! Java_SkipData.create(ctor: Java_SkipData_constructor_methodID, options: options, args: [kotlinByteArray.toJavaParameter(options: options)])
            }
        }
    }
}

// MARK: Date

private let Java_SkipData = try! JClass(name: "skip/foundation/Data")
private let Java_SkipData_constructor_methodID = Java_SkipData.getMethodID(name: "<init>", sig: "([B)V")!
private let Java_SkipData_kotlin_methodID = Java_SkipData.getMethodID(name: "kotlin", sig: "(Z)[B")!

extension Date: JObjectProtocol, JConvertible {
    public static func fromJavaObject(_ obj: JavaObjectPointer?, options: JConvertibleOptions) -> Date {
        let timeInterval: Double
        if options.contains(.kotlincompat) {
            let millis = try! Int64.call(Java_Date_getTime_methodID, on: obj!, options: options, args: [])
            timeInterval = Double(millis) / 1000.0
        } else {
            timeInterval = try! Double.call(Java_SkipDate_timeIntervalSince1970_methodID, on: obj!, options: options, args: [])
        }
        return Date(timeIntervalSince1970: timeInterval)
    }

    public func toJavaObject(options: JConvertibleOptions) -> JavaObjectPointer? {
        let millis = Int64(timeIntervalSince1970 * 1000.0)
        let utilDate = try! Java_Date.create(ctor: Java_Date_constructor_methodID, options: options, args: [millis.toJavaParameter(options: options)])
        if options.contains(.kotlincompat) {
            return utilDate
        } else {
            return try! Java_SkipDate.create(ctor: Java_SkipDate_constructor_methodID, options: options, args: [utilDate.toJavaParameter(options: options)])
        }
    }
}

private let Java_SkipDate = try! JClass(name: "skip/foundation/Date")
private let Java_SkipDate_constructor_methodID = Java_SkipDate.getMethodID(name: "<init>", sig: "(Ljava/util/Date;)V")!
private let Java_SkipDate_timeIntervalSince1970_methodID = Java_SkipDate.getMethodID(name: "getTimeIntervalSince1970", sig: "()D")!
private let Java_Date = try! JClass(name: "java/util/Date")
private let Java_Date_constructor_methodID = Java_Date.getMethodID(name: "<init>", sig: "(J)V")!
private let Java_Date_getTime_methodID = Java_Date.getMethodID(name: "getTime", sig: "()J")!

// MARK: Dictionary

extension Dictionary: JObjectProtocol, JConvertible {
    public static func fromJavaObject(_ obj: JavaObjectPointer?, options: JConvertibleOptions) -> Dictionary<Key, Value> {
        // let map = dict.kotlin(nocopy: true)
        let map_java: JavaObjectPointer
        if options.contains(.kotlincompat) {
            map_java = obj!
        } else {
            map_java = try! JavaObjectPointer.call(Java_SkipDictionary_kotlin_methodID, on: obj!, options: options, args: [true.toJavaParameter(options: options)])
        }
        // let keySet = map.keySet()
        let keySet_java = try! JavaObjectPointer.call(Java_Map_keySet_methodID, on: map_java, options: options, args: [])
        let iterator_java = try! JavaObjectPointer.call(Java_Set_iterator_methodID, on: keySet_java, options: options, args: [])
        let size = try! Int32.call(Java_Set_size_methodID, on: keySet_java, options: options, args: [])
        var dict = Dictionary<Key, Value>()
        for _ in 0..<size {
            // let key = itr.next(); let value = map.get(key)
            let key_java = try! JavaObjectPointer?.call(Java_Iterator_next_methodID, on: iterator_java, options: options, args: [])
            let value_java = try! JavaObjectPointer?.call(Java_Map_get_methodID, on: map_java, options: options, args: [key_java.toJavaParameter(options: options)])

            // Convert non-polymorphic JConvertibles directly, else fall back to AnyBridging
            let key: Key
            let value: Value
            if let convertibleKey = Key.self as? JConvertible.Type, !(Key.self is AnyObject.Type) {
                key = convertibleKey.fromJavaObject(key_java, options: options) as! Key
            } else {
                key = AnyBridging.fromJavaObject(key_java, options: options) as! Key
            }
            if let convertibleValue = Value.self as? JConvertible.Type, !(Value.self is AnyObject.Type) {
                value = convertibleValue.fromJavaObject(value_java, options: options) as! Value
            } else {
                value = AnyBridging.fromJavaObject(value_java, options: options) as! Value
            }
            dict[key] = value
            if let key_java {
                jni.deleteLocalRef(key_java)
            }
            if let value_java {
                jni.deleteLocalRef(value_java)
            }
        }
        return dict
    }

    public func toJavaObject(options: JConvertibleOptions) -> JavaObjectPointer? {
        // let map = LinkedHashMap(count)
        let map_java = try! Java_LinkedHashMap.create(ctor: Java_LinkedHashMap_constructor_methodID, options: options, args: [Int32(self.count).toJavaParameter(options: options)])
        for (key, value) in self {
            // map.put(key, value)
            let key_java = (key as! JConvertible).toJavaObject(options: options)
            let value_java = (value as! JConvertible).toJavaObject(options: options)
            let _ = try! JavaObjectPointer?.call(Java_LinkedHashMap_put_methodID, on: map_java, options: options, args: [key_java.toJavaParameter(options: options), value_java.toJavaParameter(options: options)])
            if let key_java {
                jni.deleteLocalRef(key_java)
            }
            if let value_java {
                jni.deleteLocalRef(value_java)
            }
        }
        if options.contains(.kotlincompat) {
            return map_java
        } else {
            // return Dictionary(map, nocopy: true, shared: false)
            let dict_java = try! Java_SkipDictionary.create(ctor: Java_SkipDictionary_constructor_methodID, options: options, args: [map_java.toJavaParameter(options: options), true.toJavaParameter(options: options), false.toJavaParameter(options: options)])
            return dict_java
        }
    }
}

private let Java_SkipDictionary = try! JClass(name: "skip/lib/Dictionary")
private let Java_SkipDictionary_constructor_methodID = Java_SkipDictionary.getMethodID(name: "<init>", sig: "(Ljava/util/Map;ZZ)V")!
private let Java_SkipDictionary_kotlin_methodID = Java_SkipDictionary.getMethodID(name: "kotlin", sig: "(Z)Ljava/util/Map;")!
private let Java_LinkedHashMap = try! JClass(name: "java/util/LinkedHashMap")
private let Java_LinkedHashMap_constructor_methodID = Java_LinkedHashMap.getMethodID(name: "<init>", sig: "(I)V")!
private let Java_LinkedHashMap_put_methodID = Java_LinkedHashMap.getMethodID(name: "put", sig: "(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;")!
private let Java_Map = try! JClass(name: "java/util/Map")
private let Java_Map_get_methodID = Java_Map.getMethodID(name: "get", sig: "(Ljava/lang/Object;)Ljava/lang/Object;")!
private let Java_Map_keySet_methodID = Java_Map.getMethodID(name: "keySet", sig: "()Ljava/util/Set;")!
private let Java_Set = try! JClass(name: "java/util/Set")
private let Java_Set_size_methodID = Java_Set.getMethodID(name: "size", sig: "()I")!
private let Java_Set_iterator_methodID = Java_Set.getMethodID(name: "iterator", sig: "()Ljava/util/Iterator;")!
private let Java_Iterator = try! JClass(name: "java/util/Iterator")
private let Java_Iterator_next_methodID = Java_Iterator.getMethodID(name: "next", sig: "()Ljava/lang/Object;")!

// MARK: Result

extension Result: JObjectProtocol, JConvertible {
    public static func fromJavaObject(_ obj: JavaObjectPointer?, options: JConvertibleOptions) -> Result<Success, Failure> {
        // let result = res.kotlin(nocopy: true)
        let result_java: JavaObjectPointer
        if options.contains(.kotlincompat) {
            result_java = obj!
        } else {
            result_java = try! JavaObjectPointer.call(Java_SkipResult_kotlin_methodID, on: obj!, options: options, args: [true.toJavaParameter(options: options)])
        }
        let throwable_java: JavaObjectPointer? = try! result_java.call(method: Java_Result_exceptionOrNull_methodID, options: options, args: [])
        if let throwable_java {
            let error = JThrowable.toError(throwable_java, options: options) as! Failure
            return .failure(error)
        } else {
            let success_java: JavaObjectPointer? = try! result_java.call(method: Java_Result_getOrNull_methodID, options: options, args: [])
            let success: Success
            if let convertibleSuccess = Success.self as? JConvertible.Type, !(Success.self is AnyObject.Type) {
                success = convertibleSuccess.fromJavaObject(success_java, options: options) as! Success
            } else {
                success = AnyBridging.fromJavaObject(success_java, options: options) as! Success
            }
            return .success(success)
        }
    }

    public func toJavaObject(options: JConvertibleOptions) -> JavaObjectPointer? {
        let result_java: JavaObjectPointer
        switch self {
        case .success(let value):
            let value_java = (value as! JConvertible).toJavaParameter(options: options)
            result_java = try! Java_Result_Companion_instance.call(method: Java_Result_Companion_success_methodID, options: options, args: [value_java])
        case .failure(let error):
            let error_java = JThrowable.toThrowable(error, options: options).toJavaParameter(options: options)
            result_java = try! Java_Result_Companion_instance.call(method: Java_Result_Companion_failure_methodID, options: options, args: [error_java])
        }
        guard !options.contains(.kotlincompat) else {
            return result_java
        }
        return try! Java_SkipResult.create(ctor: Java_SkipResult_constructor_methodID, options: options, args: [result_java.toJavaParameter(options: options)])
    }
}

private let Java_Result = try! JClass(name: "kotlin/Result")
private let Java_Result_Companion = try! JClass(name: "kotlin/Result$Companion")
private let Java_Result_Companion_instance = JObject(Java_Result.getStatic(field: Java_Result.getStaticFieldID(name: "Companion", sig: "Lkotlin/Result$Companion;")!, options: []))
private let Java_Result_Companion_success_methodID = Java_Result_Companion.getMethodID(name: "success", sig: "(Ljava/lang/Object;)Lkotlin/Result;")!
private let Java_Result_Companion_failure_methodID = Java_Result_Companion.getMethodID(name: "failure", sig: "(Ljava/lang/Throwable;)Lkotlin/Result;")!
private let Java_Result_exceptionOrNull_methodID = Java_Result.getMethodID(name: "exceptionOrNull", sig: "()Ljava/lang/Throwable;")!
private let Java_Result_getOrNull_methodID = Java_Result.getMethodID(name: "getOrNull", sig: "()Ljava/lang/Object;")!
private let Java_SkipResult = try! JClass(name: "skip/lib/Result")
private let Java_SkipResult_constructor_methodID = Java_SkipResult.getMethodID(name: "<init>", sig: "(Lkotlin/Result;)V")!
private let Java_SkipResult_kotlin_methodID = Java_SkipResult.getMethodID(name: "kotlin", sig: "(Z)Lkotlin/Result;")!

// MARK: Set

extension Set: JObjectProtocol, JConvertible {
    public static func fromJavaObject(_ obj: JavaObjectPointer?, options: JConvertibleOptions) -> Set<Element> {
        // let set = set.kotlin(nocopy: true)
        let set_java: JavaObjectPointer
        if options.contains(.kotlincompat) {
            set_java = obj!
        } else {
            set_java = try! JavaObjectPointer.call(Java_SkipSet_kotlin_methodID, on: obj!, options: options, args: [true.toJavaParameter(options: options)])
        }
        let iterator_java = try! JavaObjectPointer.call(Java_Set_iterator_methodID, on: set_java, options: options, args: [])
        let size = try! Int32.call(Java_Set_size_methodID, on: set_java, options: options, args: [])
        var set = Set<Element>()
        for _ in 0..<size {
            // set.insert(itr.next())
            let element_java = try! JavaObjectPointer?.call(Java_Iterator_next_methodID, on: iterator_java, options: options, args: [])
            // Convert non-polymorphic JConvertibles directly, else fall back to AnyBridging
            let element: Element
            if let convertibleElement = Element.self as? JConvertible.Type, !(Element.self is AnyObject.Type) {
                element = convertibleElement.fromJavaObject(element_java, options: options) as! Element
            } else {
                element = AnyBridging.fromJavaObject(element_java, options: options) as! Element
            }
            set.insert(element)
            if let element_java {
                jni.deleteLocalRef(element_java)
            }

        }
        return set
    }

    public func toJavaObject(options: JConvertibleOptions) -> JavaObjectPointer? {
        // let set = LinkedHashSet()
        let hashset_java = try! Java_LinkedHashSet.create(ctor: Java_LinkedHashSet_constructor_methodID, options: options, args: [])
        for element in self {
            // set.add(element)
            let element_java = (element as! JConvertible).toJavaObject(options: options)
            let _ = try! Bool.call(Java_LinkedHashSet_add_methodID, on: hashset_java, options: options, args: [element_java.toJavaParameter(options: options)])
            if let element_java {
                jni.deleteLocalRef(element_java)
            }
        }
        if options.contains(.kotlincompat) {
            return hashset_java
        } else {
            // return Set(set, nocopy: true, shared: false)
            let set_java = try! Java_SkipSet.create(ctor: Java_SkipSet_constructor_methodID, options: options, args: [hashset_java.toJavaParameter(options: options), true.toJavaParameter(options: options), false.toJavaParameter(options: options)])
            return set_java
        }
    }
}

private let Java_SkipSet = try! JClass(name: "skip/lib/Set")
private let Java_SkipSet_constructor_methodID = Java_SkipSet.getMethodID(name: "<init>", sig: "(Ljava/lang/Iterable;ZZ)V")!
private let Java_SkipSet_kotlin_methodID = Java_SkipSet.getMethodID(name: "kotlin", sig: "(Z)Ljava/util/Set;")!
private let Java_LinkedHashSet = try! JClass(name: "java/util/LinkedHashSet")
private let Java_LinkedHashSet_constructor_methodID = Java_LinkedHashSet.getMethodID(name: "<init>", sig: "()V")!
private let Java_LinkedHashSet_add_methodID = Java_LinkedHashSet.getMethodID(name: "add", sig: "(Ljava/lang/Object;)Z")!

// MARK: UUID

extension UUID: JObjectProtocol, JConvertible {
    public static func fromJavaObject(_ obj: JavaObjectPointer?, options: JConvertibleOptions) -> UUID {
        let uuidString: String
        if options.contains(.kotlincompat) {
            uuidString = try! String.call(Java_UUID_toString_methodID, on: obj!, options: options, args: [])
        } else {
            uuidString = try! String.call(Java_SkipUUID_uuidString_methodID, on: obj!, options: options, args: [])
        }
        return UUID(uuidString: uuidString)!
    }

    public func toJavaObject(options: JConvertibleOptions) -> JavaObjectPointer? {
        let uuidString = self.uuidString
        if options.contains(.kotlincompat) {
            return try! Java_UUID.callStatic(method: Java_UUID_fromString_methodID, options: options, args: [uuidString.toJavaParameter(options: options)])
        } else {
            return try! Java_SkipUUID.create(ctor: Java_SkipUUID_constructor_methodID, options: options, args: [uuidString.toJavaParameter(options: options)])
        }
    }
}

private let Java_SkipUUID = try! JClass(name: "skip/foundation/UUID")
private let Java_SkipUUID_constructor_methodID = Java_SkipUUID.getMethodID(name: "<init>", sig: "(Ljava/lang/String;)V")!
private let Java_SkipUUID_uuidString_methodID = Java_SkipUUID.getMethodID(name: "getUuidString", sig: "()Ljava/lang/String;")!
private let Java_UUID = try! JClass(name: "java/util/UUID")
private let Java_UUID_fromString_methodID = Java_UUID.getStaticMethodID(name: "fromString", sig: "(Ljava/lang/String;)Ljava/util/UUID;")!
private let Java_UUID_toString_methodID = Java_UUID.getMethodID(name: "toString", sig: "()Ljava/lang/String;")!

// MARK: URL

extension URL: JObjectProtocol, JConvertible {
    public static func fromJavaObject(_ obj: JavaObjectPointer?, options: JConvertibleOptions) -> URL {
        let absoluteString: String
        if options.contains(.kotlincompat) {
            absoluteString = try! String.call(Java_URI_toString_methodID, on: obj!, options: options, args: [])
        } else {
            absoluteString = try! String.call(Java_SkipURL_absoluteString_methodID, on: obj!, options: options, args: [])
        }
        return URL(string: absoluteString)!
    }

    public func toJavaObject(options: JConvertibleOptions) -> JavaObjectPointer? {
        let absoluteString = self.absoluteString
        if options.contains(.kotlincompat) {
            return try! Java_URI.create(ctor: Java_URI_constructor_methodID, options: options, args: [absoluteString.toJavaParameter(options: options)])
        } else {
            return try! Java_SkipURL.create(ctor: Java_SkipURL_constructor_methodID, options: options, args: [absoluteString.toJavaParameter(options: options), (nil as JavaObjectPointer?).toJavaParameter(options: options)])
        }
    }
}

private let Java_SkipURL = try! JClass(name: "skip/foundation/URL")
private let Java_SkipURL_constructor_methodID = Java_SkipURL.getMethodID(name: "<init>", sig: "(Ljava/lang/String;Lskip/foundation/URL;)V")!
private let Java_SkipURL_absoluteString_methodID = Java_SkipURL.getMethodID(name: "getAbsoluteString", sig: "()Ljava/lang/String;")!
private let Java_URI = try! JClass(name: "java/net/URI")
private let Java_URI_constructor_methodID = Java_URI.getMethodID(name: "<init>", sig: "(Ljava/lang/String;)V")!
private let Java_URI_toString_methodID = Java_URI.getMethodID(name: "toString", sig: "()Ljava/lang/String;")!
