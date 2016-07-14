//
//  Packet.swift
//  Aphid
//
//  Created by Robert F. Dickerson on 7/10/16.
//
//

import Foundation
import Socket

let PacketNames: [UInt8:String] = [
    1: "CONNECT",
    2: "CONNACK",
    3: "PUBLISH",
    4: "PUBACK",
    5: "PUBREC",
    6: "PUBREL",
    7: "PUBCOMP",
    8: "SUBSCRIBE",
    9: "SUBACK",
    10: "UNSUBSCRIBE",
    11: "UNSUBACK",
    12: "PINGREQ",
    13: "PINGRESP",
    14: "DISCONNECT"
]

enum ControlCode: Byte {
    case connect    = 0x10
    case connack    = 0x20
    case publish    = 0x30 // special case
    case puback     = 0x40
    case pubrec     = 0x50
    case pubrel     = 0x62
    case pubcomp    = 0x70
    case subscribe  = 0x82
    case suback     = 0x90
    case unsubscribe = 0xa2
    case unsuback   = 0xb0
    case pingreq    = 0xc0
    case pingresp   = 0xd0
    case disconnect = 0xe0
    case reserved   = 0xf0
}
let Connect: UInt8  = 1
let Connack: UInt8  = 2
let Publish  = 3

enum ErrorCodes: Byte {
    case accepted                       = 0x00
    case errRefusedBadProtocolVersion   = 0x01
    case errRefusedIDRejected           = 0x02
    case error                          = 0x03
}
enum qosType: Byte {
    case atMostOnce = 0 // At Most One Delivery
    case atLeastOnce = 1 // At Least Deliver Once
    case exactlyOnce = 2 // Deliver Exactly Once
}
struct Details {
    var qos: Byte
    var messageID: UInt16
}
struct FixedHeader {
    let messageType: Byte
    var dup: Bool
    var qos: Byte
    var retain: Bool
    var remainingLength: Int

    init(messageType: ControlCode) {
        self.messageType = UInt8(messageType.rawValue & 0xF0) >> 4
        dup = (messageType.rawValue & 0x08 >> 3).bool
        qos = messageType.rawValue & 0x06 >> 1
        retain = (messageType.rawValue & 0x01).bool
        remainingLength = 0
    }

    func pack() -> Data {
        var data = Data()
        data.append((messageType << 4 | dup.toByte << 3 | qos << 1 | retain.toByte).data)

        for byte in encodeLength(remainingLength) {
            data.append(encodeUInt8(byte))
        }

        return data
    }
}

extension FixedHeader: CustomStringConvertible {

    var description: String {
        return "\(messageType): dup: \(dup) qos: \(qos)"
    }

}

extension Aphid {
    func newControlPacket(packetType: ControlCode, topicName: String? = nil, packetId: UInt16? = nil ) -> ControlPacket? {
        switch packetType {
        case .connect:
            return ConnectPacket(header: FixedHeader(messageType: .connect), clientId: clientId )
        case .connack:
            return ConnackPacket(header: FixedHeader(messageType: .connack))
        case .publish:
            return PublishPacket(header: FixedHeader(messageType: .publish), topicName: topicName!, packetIdentifier: packetId!)
        case .puback:
            return PublishPacket(header: FixedHeader(messageType: .puback), topicName: "Test", packetIdentifier: 0x00) // Wrong
        case .pubrec:
            return PublishPacket(header: FixedHeader(messageType: .pubrec), topicName: "Test", packetIdentifier: 0x00) // Wrong
        case .pubrel:
            return PublishPacket(header: FixedHeader(messageType: .pubrel), topicName: "Test", packetIdentifier: 0x00) // Wrong
        case .pubcomp:
            return PublishPacket(header: FixedHeader(messageType: .pubcomp), topicName: "Test", packetIdentifier: 0x00) // Wrong
        case .subscribe:
            return SubscribePacket(header: FixedHeader(messageType: .subscribe), messageID: 0, topics: [String](), qoss: [Byte]())// Wrong
        case .suback:
            return PublishPacket(header: FixedHeader(messageType: .suback), topicName: "Test", packetIdentifier: 0x00) // Wrong
        case .unsubscribe:
            return UnsubscribePacket(header: FixedHeader(messageType: .unsubscribe), messageID: 0x00, topics: [String]()) // Wrong
        case .unsuback:
            return PublishPacket(header: FixedHeader(messageType: .unsuback), topicName: "Test", packetIdentifier: 0x00) // Wrong
        case .pingreq:
            return PingreqPacket(header: FixedHeader(messageType: .pingreq))
        case .pingresp:
            return PublishPacket(header: FixedHeader(messageType: .pingresp), topicName: "Test", packetIdentifier: 0x00) // Wrong
        case .disconnect:
            return DisconnectPacket(header: FixedHeader(messageType: .disconnect))
        default:
            return nil
        }
    }
}


extension Bool {
    var toByte: Byte {
        get {
            return self ? 0x01 : 0x00
        }
    }
}
extension String {
    var data: Data {
        get {
            var array = Data()

            let utf = self.data(using: String.Encoding.utf8)!

            array.append(UInt16(utf.count).data)
            array.append(utf)

            return array
        }
    }
}
extension UInt8 {
    var data: Data {
        return Data(bytes: [self])
    }

    var bool: Bool {
        return self == 0x01 ? true : false
    }
}
extension UInt16 {
    var data: Data {
        get {
            var data = Data()
            var bytes: [UInt8] = [0x00, 0x00]
            bytes[0] = UInt8(self >> 8)
            bytes[1] = UInt8(self & 0x00ff)
            data.append(Data(bytes: bytes, count: 2))
            return data
        }
    }
    var bytes: [Byte] {
        get {
            var bytes: [UInt8] = [0x00, 0x00]
            bytes[0] = UInt8(self >> 8)
            bytes[1] = UInt8(self & 0x00ff)
            return bytes
        }
    }
}
func encodeString(str: String) -> Data {
    var array = Data()

    let utf = str.data(using: String.Encoding.utf8)!

    array.append(encodeUInt16ToData(UInt16(utf.count)))
    array.append(utf)

    return array
}
func encodeBit(_ bool: Bool) -> Byte {
    return bool ? 0x01 : 0x00
}
func encodeUInt16ToData(_ value: UInt16) -> Data {
    var data = Data()
    var bytes: [UInt8] = [0x00, 0x00]
    bytes[0] = UInt8(value >> 8)
    bytes[1] = UInt8(value & 0x00ff)
    data.append(Data(bytes: bytes, count: 2))
    return data
}
func encodeUInt16(_ value: UInt16) -> [Byte] {
    var bytes: [UInt8] = [0x00, 0x00]
    bytes[0] = UInt8(value >> 8)
    bytes[1] = UInt8(value & 0x00ff)
    return bytes
}

func encodeUInt8(_ value: UInt8) -> Data {
    return Data(bytes: [value])
}

/*func encodeUInt16(_ value: UInt16) -> Data {
    var value = value
    return Data(bytes: &UInt8(value), count: sizeof(UInt16))
}*/

/*public func encode<T>(_ value: T) -> Data {
    var value = value
    return withUnsafePointer(&value) { p in
        Data(bytes: UnsafePointer<UInt8>(p), count: sizeof(p))
        //Data(bytes: p, count: sizeofValue(value))
    }
}*/
func getBytes(_ value: Data) {
    value.enumerateBytes() {
        buffer, byteIndex, stop in

        print(buffer.first!)
        if byteIndex == value.count {
            stop = true
        }
    }
}
func encodeLength(_ length: Int) -> [Byte] {
    var encLength = [Byte]()
    var length = length

    repeat {
        var digit = Byte(length % 128)
        length /= 128
        if length > 0 {
            digit |= 0x80
        }
        encLength.append(digit)

    } while length != 0

    return encLength
}

func decodebit(_ byte: Byte) -> Bool {
    return byte == 0x01 ? true : false
}
func decodeString(_ reader: SocketReader) -> String {
    let fieldLength = decodeUInt16(reader)
    let field = NSMutableData(capacity: Int(fieldLength))
    do {
       let _ = try reader.read(into: field!)
    } catch {

    }
    return String(field)
}
func decodeUInt8(_ reader: SocketReader) -> UInt8 {
    let num = NSMutableData(capacity: 1)
    do {
        let _ = try reader.read(into: num!)
    } catch {

    }
    return decode(num!)
}
func decodeUInt16(_ reader: SocketReader) -> UInt16 {
    let uint = NSMutableData(capacity: 2)
    do {
        let _ = try reader.read(into: uint!)
    } catch {

    }
    return decode(uint!)
}
public func decode<T>(_ data: NSData) -> T {
    let pointer = UnsafeMutablePointer<T>(allocatingCapacity: sizeof(T.self))
    data.getBytes(pointer, length: sizeof(T.self))
    return pointer.move()
}
func decodeLength(_ bytes: [Byte]) -> Int {
    var rLength: UInt32 = 0
    var multiplier: UInt32 = 0
    var b: [Byte] = [0x00]
    while true {
        let digit = b[0]
        rLength |= UInt32(digit & 127) << multiplier
        if (digit & 128) == 0 {
            break
        }
        multiplier += 7
    }
    return Int(rLength)
}
