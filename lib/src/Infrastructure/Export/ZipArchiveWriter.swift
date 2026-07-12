//
//  ZipArchiveWriter.swift
//  Taylor'd Portfolio
//
//  Infrastructure · Export — a minimal ZIP writer (needed for .docx; no external deps).
//

import Foundation

/// Writes a ZIP archive from in-memory entries using the **STORED** (uncompressed) method,
/// which is valid ZIP/OOXML and avoids any compression dependency. Enough to package a
/// `.docx` (an OOXML zip). Pure Foundation — no external libraries.
nonisolated enum ZipArchiveWriter {
    struct Entry: Sendable {
        let path: String
        let data: Data
    }

    static func archive(_ entries: [Entry]) -> Data {
        var output = Data()
        var central = Data()
        var offset: UInt32 = 0
        // Fixed valid MS-DOS timestamp (1980-01-01 00:00), so output is deterministic.
        let dosTime: UInt16 = 0
        let dosDate: UInt16 = 0x0021

        for entry in entries {
            let nameBytes = Array(entry.path.utf8)
            let crc = crc32(entry.data)
            let size = UInt32(entry.data.count)

            // Local file header + data.
            output.append(le32: 0x0403_4b50)          // local file header signature
            output.append(le16: 20)                    // version needed to extract
            output.append(le16: 0)                     // general purpose flags
            output.append(le16: 0)                     // compression method: 0 = stored
            output.append(le16: dosTime)
            output.append(le16: dosDate)
            output.append(le32: crc)
            output.append(le32: size)                  // compressed size
            output.append(le32: size)                  // uncompressed size
            output.append(le16: UInt16(nameBytes.count))
            output.append(le16: 0)                     // extra field length
            output.append(contentsOf: nameBytes)
            let localHeaderOffset = offset
            output.append(entry.data)
            offset = UInt32(output.count)

            // Central directory record for the same entry.
            central.append(le32: 0x0201_4b50)          // central dir header signature
            central.append(le16: 20)                   // version made by
            central.append(le16: 20)                   // version needed
            central.append(le16: 0)                    // flags
            central.append(le16: 0)                    // method
            central.append(le16: dosTime)
            central.append(le16: dosDate)
            central.append(le32: crc)
            central.append(le32: size)
            central.append(le32: size)
            central.append(le16: UInt16(nameBytes.count))
            central.append(le16: 0)                    // extra
            central.append(le16: 0)                    // comment length
            central.append(le16: 0)                    // disk number start
            central.append(le16: 0)                    // internal attributes
            central.append(le32: 0)                    // external attributes
            central.append(le32: localHeaderOffset)
            central.append(contentsOf: nameBytes)
        }

        let centralOffset = UInt32(output.count)
        let centralSize = UInt32(central.count)
        output.append(central)

        // End of central directory record.
        output.append(le32: 0x0605_4b50)
        output.append(le16: 0)                          // this disk
        output.append(le16: 0)                          // disk with central dir
        output.append(le16: UInt16(entries.count))      // entries on this disk
        output.append(le16: UInt16(entries.count))      // total entries
        output.append(le32: centralSize)
        output.append(le32: centralOffset)
        output.append(le16: 0)                          // comment length
        return output
    }

    /// Standard CRC-32 (polynomial 0xEDB88320), as ZIP requires.
    static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in data {
            crc ^= UInt32(byte)
            for _ in 0..<8 {
                crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB8_8320 : (crc >> 1)
            }
        }
        return crc ^ 0xFFFF_FFFF
    }
}

private extension Data {
    // nonisolated so the nonisolated `ZipArchiveWriter` can call these synchronously
    // (the project defaults type isolation to MainActor) — v0.4.1 Milestone H.
    nonisolated mutating func append(le16 value: UInt16) {
        append(UInt8(value & 0xff))
        append(UInt8((value >> 8) & 0xff))
    }
    nonisolated mutating func append(le32 value: UInt32) {
        append(UInt8(value & 0xff))
        append(UInt8((value >> 8) & 0xff))
        append(UInt8((value >> 16) & 0xff))
        append(UInt8((value >> 24) & 0xff))
    }
}
