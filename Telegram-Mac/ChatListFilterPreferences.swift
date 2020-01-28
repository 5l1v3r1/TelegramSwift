//
//  ChatListFilterPreferences.swift
//  Telegram
//
//  Created by Mikhail Filimonov on 24.01.2020.
//  Copyright © 2020 Telegram. All rights reserved.
//

import Postbox
import SwiftSignalKit

public enum ChatListFilterPresetName: Equatable, Hashable, PostboxCoding {
    case unmuted
    case unread
    case channels
    case groups
    case privateChats
    case bots
    case custom(String)
    
    public init(decoder: PostboxDecoder) {
        switch decoder.decodeInt32ForKey("_t", orElse: 0) {
        case 0:
            self = .unmuted
        case 1:
            self = .channels
        case 2:
            self = .privateChats
        case 3:
            self = .groups
        case 4:
            self = .bots
        case 5:
            self = .unread
        case 10:
            self = .custom(decoder.decodeStringForKey("title", orElse: "Preset"))
        default:
            assertionFailure()
            self = .custom("Preset")
        }
    }
    
    public func encode(_ encoder: PostboxEncoder) {
        switch self {
        case .unmuted:
            encoder.encodeInt32(0, forKey: "_t")
        case .channels:
            encoder.encodeInt32(1, forKey: "_t")
        case .privateChats:
            encoder.encodeInt32(2, forKey: "_t")
        case .groups:
            encoder.encodeInt32(3, forKey: "_t")
        case .bots:
            encoder.encodeInt32(4, forKey: "_t")
        case .unread:
            encoder.encodeInt32(5, forKey: "_t")
        case let .custom(title):
            encoder.encodeInt32(10, forKey: "_t")
            encoder.encodeString(title, forKey: "title")
        }
    }

    
    var title: String {
        switch self {
        case .unmuted:
            return L10n.chatListFilterUnmutedChats
        case .channels:
            return L10n.chatListFilterChannels
        case .groups:
            return L10n.chatListFilterGroups
        case .privateChats:
            return L10n.chatListFilterPrivateChats
        case .unread:
            return L10n.chatListFilterUnreadChats
        case .bots:
            return L10n.chatListFilterBots
        case let .custom(name):
            return name
        }
    }
}

struct ChatListFilterPreset: Equatable, PostboxCoding {
    let name: ChatListFilterPresetName
    let includeCategories: ChatListFilter
    let additionallyIncludePeers: [PeerId]
    let uniqueId: Int32
    init(name: ChatListFilterPresetName, includeCategories: ChatListFilter, additionallyIncludePeers: [PeerId], uniqueId: Int32) {
        self.name = name
        self.includeCategories = includeCategories
        self.additionallyIncludePeers = additionallyIncludePeers
        self.uniqueId = uniqueId
    }
    
    init(decoder: PostboxDecoder) {
        self.name = decoder.decodeObjectForKey("name", decoder: { ChatListFilterPresetName(decoder: $0) }) as? ChatListFilterPresetName ?? ChatListFilterPresetName.custom("Preset")
        self.includeCategories = ChatListFilter(rawValue: decoder.decodeInt32ForKey("includeCategories", orElse: 0))
        self.additionallyIncludePeers = decoder.decodeInt64ArrayForKey("additionallyIncludePeers").map(PeerId.init)
        self.uniqueId = decoder.decodeInt32ForKey("uniqueId", orElse: 0)
    }
    
    func encode(_ encoder: PostboxEncoder) {
        encoder.encodeObject(self.name, forKey: "name")
        encoder.encodeInt32(self.includeCategories.rawValue, forKey: "includeCategories")
        encoder.encodeInt64Array(self.additionallyIncludePeers.map { $0.toInt64() }, forKey: "additionallyIncludePeers")
        encoder.encodeInt32(self.uniqueId, forKey: "uniqueId")
    }
    
    var title: String {
        return name.title
    }
    var desc: String {
        return self.includeCategories.string
    }
}



struct ChatListFilter: OptionSet {
    var rawValue: Int32
    
    init(rawValue: Int32) {
        self.rawValue = rawValue
    }
    
    static let muted = ChatListFilter(rawValue: 1 << 1)
    static let privateChats = ChatListFilter(rawValue: 1 << 2)
    static let groups = ChatListFilter(rawValue: 1 << 3)
    static let bots = ChatListFilter(rawValue: 1 << 4)
    static let channels = ChatListFilter(rawValue: 1 << 5)
    static let read = ChatListFilter(rawValue: 1 << 6)
    static let all: ChatListFilter = [
        .muted,
        .privateChats,
        .groups,
        .bots,
        .channels,
        .read
    ]
    static let _workMode: ChatListFilter = [
        .privateChats,
        .groups,
        .bots,
        .channels,
        .read]
    
    static let _unread: ChatListFilter = [
        .muted,
        .privateChats,
        .groups,
        .bots,
        .channels]
    
    static let _channels: ChatListFilter = [
        .muted,
        .channels,
        .read
    ]
    static let _groups: ChatListFilter = [
        .muted,
        .groups,
        .read
    ]
    static let _privateChats: ChatListFilter = [
        .muted,
        .privateChats,
        .read
    ]
    static let _bots: ChatListFilter = [
        .muted,
        .bots,
        .read
    ]
    var string: String {
        return ""
    }
}

struct ChatListFilterPreferences: PreferencesEntry, Equatable {
    let current: ChatListFilterPreset?
    let presets: [ChatListFilterPreset]

    static var defaultSettings: ChatListFilterPreferences {
        var presets: [ChatListFilterPreset] = []
        
        presets.append(ChatListFilterPreset(name: .privateChats, includeCategories: ._privateChats, additionallyIncludePeers: [], uniqueId: 0))
        presets.append(ChatListFilterPreset(name: .channels, includeCategories: ._channels, additionallyIncludePeers: [], uniqueId: 1))
        presets.append(ChatListFilterPreset(name: .groups, includeCategories: ._groups, additionallyIncludePeers: [], uniqueId: 2))
        presets.append(ChatListFilterPreset(name: .bots, includeCategories: ._bots, additionallyIncludePeers: [], uniqueId: 3))
        presets.append(ChatListFilterPreset(name: .unread, includeCategories: ._unread, additionallyIncludePeers: [], uniqueId: 4))
        presets.append(ChatListFilterPreset(name: .unmuted, includeCategories: ._workMode, additionallyIncludePeers: [], uniqueId: 5))
        
        return ChatListFilterPreferences(current: nil, presets: presets)
    }
    
    init(current: ChatListFilterPreset?, presets: [ChatListFilterPreset]) {
        self.current = current
        self.presets = presets
    }
    
    init(decoder: PostboxDecoder) {
        self.current = decoder.decodeObjectForKey("current") as? ChatListFilterPreset
        self.presets = decoder.decodeObjectArrayWithDecoderForKey("presets")
    }
    
    func encode(_ encoder: PostboxEncoder) {
        if let current = current {
            encoder.encodeObject(current, forKey: "current")
        } else {
            encoder.encodeNil(forKey: "current")
        }
        encoder.encodeObjectArray(self.presets, forKey: "presets")
    }
    
    func isEqual(to: PreferencesEntry) -> Bool {
        if let to = to as? ChatListFilterPreferences {
            return self == to
        } else {
            return false
        }
    }
    
    static func ==(lhs: ChatListFilterPreferences, rhs: ChatListFilterPreferences) -> Bool {
        return lhs.current == rhs.current && lhs.presets == rhs.presets
    }
    
    func withUpdatedCurrentPreset(_ current: ChatListFilterPreset?) -> ChatListFilterPreferences {
        return ChatListFilterPreferences(current: current, presets: self.presets)
    }
    func withAddedPreset(_ preset: ChatListFilterPreset) -> ChatListFilterPreferences {
        var presets = self.presets
        if let index = presets.firstIndex(where: {$0.uniqueId == preset.uniqueId}) {
            presets[index] = preset
        } else {
            presets.append(preset)
        }
        return ChatListFilterPreferences(current: self.current, presets: presets)
    }
    
    func withRemovedPreset(_ preset: ChatListFilterPreset) -> ChatListFilterPreferences {
        var presets = self.presets
        presets.removeAll(where: {$0.uniqueId == preset.uniqueId })
        return ChatListFilterPreferences(current: self.current, presets: presets)
    }
}

func chatListFilterPreferences(postbox: Postbox) -> Signal<ChatListFilterPreferences, NoError> {
    return postbox.preferencesView(keys: [ApplicationSpecificPreferencesKeys.chatListSettings]) |> map { view in
        return view.values[ApplicationSpecificPreferencesKeys.chatListSettings] as? ChatListFilterPreferences ?? ChatListFilterPreferences.defaultSettings
    }
}

func updateChatListFilterPreferencesInteractively(postbox: Postbox, _ f: @escaping (ChatListFilterPreferences) -> ChatListFilterPreferences) -> Signal<Void, NoError> {
    return postbox.transaction { transaction -> Void in
        transaction.updatePreferencesEntry(key: ApplicationSpecificPreferencesKeys.chatListSettings, { entry in
            let currentSettings: ChatListFilterPreferences
            if let entry = entry as? ChatListFilterPreferences {
                currentSettings = entry
            } else {
                currentSettings = ChatListFilterPreferences.defaultSettings
            }
            return f(currentSettings)
        })
    }
}
