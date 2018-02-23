//
//  ThingsJSON.swift
//
//  Copyright © 2018 Cultured Code GmbH & Co. KG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

// MARK: Container

/// The container holding the array of items to be encoded to JSON.
public class TJSContainer : Codable {

    /// The array of items that will be encoded or decoded from the JSON.
    public var items = [Item]()

    /// Create and return a new ThingsJSON object configured with the provided items.
    public init(items: [Item]) {
        self.items = items
    }

    /// Creates a new instance by decoding from the given decoder.
    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.items = try container.decode([Item].self)
    }

    /// Encodes this value into the given encoder.
    public func encode(to encoder: Encoder) throws {
        try self.items.encode(to: encoder)
    }

    /// An item that can exist inside the top level JSON array.
    ///
    /// This is an enum that wraps a TJSTodo or TJSProject object and handles its encoding
    /// and decoding to JSON. This is required because there is no way of specifiying a
    /// strongly typed array that contains more than one type.
    public enum Item : Codable {
        case todo(TJSTodo)
        case project(TJSProject)

        /// Creates a new instance by decoding from the given decoder.
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            do {
                // Try to decode a to-do
                let todo = try container.decode(TJSTodo.self)
                self = .todo(todo)
            }
            catch TJSError.invalidType(_) {
                // If it's the wrong type, try a project
                let project = try container.decode(TJSProject.self)
                self = .project(project)
            }
        }

        /// Encodes this value into the given encoder.
        public func encode(to encoder: Encoder) throws {
            switch self {
            case .todo(let todo):
                try todo.encode(to: encoder)
            case .project(let project):
                try project.encode(to: encoder)
            }
        }
    }
}


// MARK: - Model Items

/// The superclass of all the Things JSON model items.
///
/// Do not instantiate this class itself. Instead use one of the subclasses.
public class TJSModelItem {
    fileprivate var type: String = ""

    /// The operation to perform on the object.
    public var operation: Operation

    /// The ID of the item to update.
    public var id: String?

    private enum CodingKeys: String, CodingKey {
        case type
        case operation
        case id
        case attributes
    }

    public enum Operation: String, Codable {
        /// Create a new item.
        case create = "create"
        /// Update an existing item.
        ///
        /// Requires id to be set.
        case update = "update"
    }

    public init(operation: Operation, id: String? = nil) {
        self.operation = operation
        self.id = id
    }

    fileprivate func attributes<T>(_ type: T.Type, from decoder: Decoder) throws -> KeyedDecodingContainer<T> {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedType = try container.decode(String.self, forKey: .type)
        self.operation = try container.decodeIfPresent(Operation.self, forKey: .operation) ?? .create
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        guard decodedType == self.type else {
            let description = String(format: "Expected to decode a %@ but found a %@ instead.", self.type, decodedType)
            let errorContext = DecodingError.Context(codingPath: [CodingKeys.type], debugDescription: description)
            let expectedType = Swift.type(of: self)
            throw TJSError.invalidType(expectedType: expectedType, errorContext: errorContext)
        }
        return try container.nestedContainer(keyedBy: T.self, forKey: .attributes)
    }

    fileprivate func attributes<T>(_ type: T.Type, for encoder: Encoder) throws -> KeyedEncodingContainer<T> {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.type, forKey: .type)
        try container.encode(self.operation, forKey: .operation)
        try container.encodeIfPresent(self.id, forKey: .id)
        return container.nestedContainer(keyedBy: T.self, forKey: .attributes)
    }
}


// MARK: -

/// Represents a to-do in Things.
public class TJSTodo : TJSModelItem, Codable {
    public var title: String?
    public var notes: String?
    public var prependNotes: String?
    public var appendNotes: String?
    public var when: String?
    public var deadline: String?
    public var tags: [String]?
    public var addTags: [String]?
    public var checklistItems: [TJSChecklistItem]?
    public var prependChecklistItems: [TJSChecklistItem]?
    public var appendChecklistItems: [TJSChecklistItem]?
    public var listID: String?
    public var list: String?
    public var heading: String?
    public var completed: Bool?
    public var canceled: Bool?
    public var creationDate: Date?
    public var completionDate: Date?

    private enum CodingKeys: String, CodingKey {
        case title
        case notes
        case prependNotes = "prepend-notes"
        case appendNotes = "append-notes"
        case when
        case deadline
        case tags
        case addTags = "add-tags"
        case checklistItems = "checklist-items"
        case prependChecklistItems = "prepend-checklist-items"
        case appendChecklistItems = "append-checklist-items"
        case listID = "list-id"
        case list
        case heading
        case completed
        case canceled
        case creationDate = "creation-date"
        case completionDate = "completion-date"
    }

    /// Create and return a new todo configured with the provided values.
    public init(operation: Operation = .create,
         id: String? = nil,
         title: String? = nil,
         notes: String? = nil,
         prependNotes: String? = nil,
         appendNotes: String? = nil,
         when: String? = nil,
         deadline: String? = nil,
         tags: [String]? = nil,
         addTags: [String]? = nil,
         checklistItems: [TJSChecklistItem]? = nil,
         prependChecklistItems: [TJSChecklistItem]? = nil,
         appendChecklistItems: [TJSChecklistItem]? = nil,
         listID: String? = nil,
         list: String? = nil,
         heading: String? = nil,
         completed: Bool? = nil,
         canceled: Bool? = nil,
         creationDate: Date? = nil,
         completionDate: Date? = nil) {

        super.init(operation: operation, id: id)
        self.type = "to-do"

        self.title = title
        self.notes = notes
        self.prependNotes = prependNotes
        self.appendNotes = appendNotes
        self.when = when
        self.deadline = deadline
        self.tags = tags
        self.addTags = addTags
        self.checklistItems = checklistItems
        self.prependChecklistItems = prependChecklistItems
        self.appendChecklistItems = appendChecklistItems
        self.listID = listID
        self.list = list
        self.heading = heading
        self.completed = completed
        self.canceled = canceled
        self.creationDate = creationDate
        self.completionDate = completionDate
    }

    /// Create and return a new todo configured with same values as the provided todo.
    public convenience init(_ todo: TJSTodo) {
        self.init(id: todo.id,
                  title: todo.title,
                  notes: todo.notes,
                  prependNotes: todo.prependNotes,
                  appendNotes: todo.appendNotes,
                  when: todo.when,
                  deadline: todo.deadline,
                  tags: todo.tags,
                  addTags: todo.addTags,
                  checklistItems: todo.checklistItems,
                  prependChecklistItems: todo.prependChecklistItems,
                  appendChecklistItems: todo.appendChecklistItems,
                  listID: todo.listID,
                  list: todo.list,
                  heading: todo.heading,
                  completed: todo.completed,
                  canceled: todo.canceled,
                  creationDate: todo.creationDate,
                  completionDate: todo.completionDate)
    }

    /// Creates a new instance by decoding from the given decoder.
    public required convenience init(from decoder: Decoder) throws {
        self.init()
        let attributes = try self.attributes(CodingKeys.self, from: decoder)
        do {
            title = try attributes.decodeIfPresent(String.self, forKey: .title)
            notes = try attributes.decodeIfPresent(String.self, forKey: .notes)
            prependNotes = try attributes.decodeIfPresent(String.self, forKey: .prependNotes)
            appendNotes = try attributes.decodeIfPresent(String.self, forKey: .appendNotes)
            when = try attributes.decodeIfPresent(String.self, forKey: .when)
            deadline = try attributes.decodeIfPresent(String.self, forKey: .deadline)
            tags = try attributes.decodeIfPresent([String].self, forKey: .tags)
            addTags = try attributes.decodeIfPresent([String].self, forKey: .addTags)
            checklistItems = try attributes.decodeIfPresent([TJSChecklistItem].self, forKey: .checklistItems)
            prependChecklistItems = try attributes.decodeIfPresent([TJSChecklistItem].self, forKey: .prependChecklistItems)
            appendChecklistItems = try attributes.decodeIfPresent([TJSChecklistItem].self, forKey: .appendChecklistItems)
            listID = try attributes.decodeIfPresent(String.self, forKey: .listID)
            list = try attributes.decodeIfPresent(String.self, forKey: .list)
            heading = try attributes.decodeIfPresent(String.self, forKey: .heading)
            completed = try attributes.decodeIfPresent(Bool.self, forKey: .completed)
            canceled = try attributes.decodeIfPresent(Bool.self, forKey: .canceled)
            creationDate = try attributes.decodeIfPresent(Date.self, forKey: .creationDate)
            completionDate = try attributes.decodeIfPresent(Date.self, forKey: .completionDate)
        }
        catch TJSError.invalidType(let expectedType, let errorContext) {
            throw DecodingError.typeMismatch(expectedType, errorContext)
        }
    }

    /// Encodes this value into the given encoder.
    public func encode(to encoder: Encoder) throws {
        var attributes = try self.attributes(CodingKeys.self, for: encoder)
        try attributes.encodeIfPresent(title, forKey: .title)
        try attributes.encodeIfPresent(notes, forKey: .notes)
        try attributes.encodeIfPresent(prependNotes, forKey: .prependNotes)
        try attributes.encodeIfPresent(appendNotes, forKey: .appendNotes)
        try attributes.encodeIfPresent(when, forKey: .when)
        try attributes.encodeIfPresent(deadline, forKey: .deadline)
        try attributes.encodeIfPresent(tags, forKey: .tags)
        try attributes.encodeIfPresent(addTags, forKey: .addTags)
        try attributes.encodeIfPresent(checklistItems, forKey: .checklistItems)
        try attributes.encodeIfPresent(prependChecklistItems, forKey: .prependChecklistItems)
        try attributes.encodeIfPresent(appendChecklistItems, forKey: .appendChecklistItems)
        try attributes.encodeIfPresent(listID, forKey: .listID)
        try attributes.encodeIfPresent(list, forKey: .list)
        try attributes.encodeIfPresent(heading, forKey: .heading)
        try attributes.encodeIfPresent(completed, forKey: .completed)
        try attributes.encodeIfPresent(canceled, forKey: .canceled)
        try attributes.encodeIfPresent(creationDate, forKey: .creationDate)
        try attributes.encodeIfPresent(completionDate, forKey: .completionDate)
    }
}


// MARK: -

/// Represents a project in Things.
public class TJSProject : TJSModelItem, Codable {
    var title: String?
    var notes: String?
    var prependNotes: String?
    var appendNotes: String?
    var when: String?
    var deadline: String?
    var tags: [String]?
    var addTags: [String]?
    var areaID: String?
    var area: String?
    var items: [Item]?
    var completed: Bool?
    var canceled: Bool?
    var creationDate: Date?
    var completionDate: Date?

    private enum CodingKeys: String, CodingKey {
        case title
        case notes
        case prependNotes = "prepend-notes"
        case appendNotes = "append-notes"
        case when
        case deadline
        case tags
        case addTags = "add-tags"
        case areaID = "area-id"
        case area
        case items
        case completed
        case canceled
        case creationDate = "creation-date"
        case completionDate = "completion-date"
    }

    /// Create and return a new project configured with the provided values.
    init(operation: Operation = .create,
         id: String? = nil,
         title: String? = nil,
         notes: String? = nil,
         prependNotes: String? = nil,
         appendNotes: String? = nil,
         when: String? = nil,
         deadline: String? = nil,
         tags: [String]? = nil,
         addTags: [String]? = nil,
         areaID: String? = nil,
         area: String? = nil,
         items: [Item]? = nil,
         completed: Bool? = nil,
         canceled: Bool? = nil,
         creationDate: Date? = nil,
         completionDate: Date? = nil) {

        super.init(operation: operation, id: id)
        self.type = "project"

        self.title = title
        self.notes = notes
        self.prependNotes = prependNotes
        self.appendNotes = appendNotes
        self.when = when
        self.deadline = deadline
        self.tags = tags
        self.addTags = addTags
        self.areaID = areaID
        self.area = area
        self.items = items
        self.completed = completed
        self.canceled = canceled
        self.creationDate = creationDate
        self.completionDate = completionDate
    }

    /// Create and return a new project configured with same values as the provided project.
    convenience init(_ project: TJSProject) {
        self.init(id: project.id,
                  title: project.title,
                  notes: project.notes,
                  prependNotes: project.prependNotes,
                  appendNotes: project.appendNotes,
                  when: project.when,
                  deadline: project.deadline,
                  tags: project.tags,
                  addTags: project.addTags,
                  areaID: project.areaID,
                  area: project.area,
                  items: project.items,
                  completed: project.completed,
                  canceled: project.canceled,
                  creationDate: project.creationDate,
                  completionDate: project.completionDate)
    }

    /// Creates a new instance by decoding from the given decoder.
    public required convenience init(from decoder: Decoder) throws {
        self.init()
        let attributes = try self.attributes(CodingKeys.self, from: decoder)
        do {
            title = try attributes.decodeIfPresent(String.self, forKey: .title)
            notes = try attributes.decodeIfPresent(String.self, forKey: .notes)
            prependNotes = try attributes.decodeIfPresent(String.self, forKey: .prependNotes)
            appendNotes = try attributes.decodeIfPresent(String.self, forKey: .appendNotes)
            when = try attributes.decodeIfPresent(String.self, forKey: .when)
            deadline = try attributes.decodeIfPresent(String.self, forKey: .deadline)
            tags = try attributes.decodeIfPresent([String].self, forKey: .tags)
            addTags = try attributes.decodeIfPresent([String].self, forKey: .addTags)
            areaID = try attributes.decodeIfPresent(String.self, forKey: .areaID)
            area = try attributes.decodeIfPresent(String.self, forKey: .area)
            completed = try attributes.decodeIfPresent(Bool.self, forKey: .completed)
            canceled = try attributes.decodeIfPresent(Bool.self, forKey: .canceled)
            items = try attributes.decodeIfPresent([Item].self, forKey: .items)
            creationDate = try attributes.decodeIfPresent(Date.self, forKey: .creationDate)
            completionDate = try attributes.decodeIfPresent(Date.self, forKey: .completionDate)
        }
        catch TJSError.invalidType(let expectedType, let errorContext) {
            throw DecodingError.typeMismatch(expectedType, errorContext)
        }
    }

    /// Encodes this value into the given encoder.
    public func encode(to encoder: Encoder) throws {
        var attributes = try self.attributes(CodingKeys.self, for: encoder)
        try attributes.encodeIfPresent(title, forKey: .title)
        try attributes.encodeIfPresent(notes, forKey: .notes)
        try attributes.encodeIfPresent(prependNotes, forKey: .prependNotes)
        try attributes.encodeIfPresent(appendNotes, forKey: .appendNotes)
        try attributes.encodeIfPresent(when, forKey: .when)
        try attributes.encodeIfPresent(deadline, forKey: .deadline)
        try attributes.encodeIfPresent(tags, forKey: .tags)
        try attributes.encodeIfPresent(addTags, forKey: .addTags)
        try attributes.encodeIfPresent(areaID, forKey: .areaID)
        try attributes.encodeIfPresent(area, forKey: .area)
        try attributes.encodeIfPresent(items, forKey: .items)
        try attributes.encodeIfPresent(completed, forKey: .completed)
        try attributes.encodeIfPresent(canceled, forKey: .canceled)
        try attributes.encodeIfPresent(creationDate, forKey: .creationDate)
        try attributes.encodeIfPresent(completionDate, forKey: .completionDate)
    }

    /// A child item of a project.
    ///
    /// This is an enum that wraps a TJSTodo or TJSHeading object and handles its encoding
    /// and decoding to JSON. This is required because there is no way of specifiying a
    /// strongly typed array that contains more than one type.
    public enum Item : Codable {
        case todo(TJSTodo)
        case heading(TJSHeading)

        /// Creates a new instance by decoding from the given decoder.
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            do {
                // Try to decode a to-do
                let todo = try container.decode(TJSTodo.self)
                self = .todo(todo)
            }
            catch TJSError.invalidType(_) {
                // If it's the wrong type, try a heading
                let heading = try container.decode(TJSHeading.self)
                self = .heading(heading)
            }
        }

        /// Encodes this value into the given encoder.
        public func encode(to encoder: Encoder) throws {
            switch self {
            case .todo(let todo):
                try todo.encode(to: encoder)
            case .heading(let heading):
                try heading.encode(to: encoder)
            }
        }
    }
}


// MARK: -

/// Represents a heading in Things.
public class TJSHeading : TJSModelItem, Codable {
    public var title: String?
    public var archived: Bool?
    public var creationDate: Date?
    public var completionDate: Date?

    private enum CodingKeys: String, CodingKey {
        case title
        case archived
        case creationDate = "creation-date"
        case completionDate = "completion-date"
    }

    /// Create and return a new heading configured with the provided values.
    public init(operation: Operation = .create,
         title: String? = nil,
         archived: Bool? = nil,
         creationDate: Date? = nil,
         completionDate: Date? = nil) {

        super.init(operation: operation)
        self.type = "heading"

        self.title = title
        self.archived = archived
        self.creationDate = creationDate
        self.completionDate = completionDate
    }

    /// Create and return a new heading configured with same values as the provided heading.
    public convenience init(_ heading: TJSHeading) {
        self.init(title: heading.title,
                  archived: heading.archived,
                  creationDate: heading.creationDate,
                  completionDate: heading.completionDate)
    }

    /// Creates a new instance by decoding from the given decoder.
    public required convenience init(from decoder: Decoder) throws {
        self.init()
        let attributes = try self.attributes(CodingKeys.self, from: decoder)
        title = try attributes.decodeIfPresent(String.self, forKey: .title)
        archived = try attributes.decodeIfPresent(Bool.self, forKey: .archived)
        creationDate = try attributes.decodeIfPresent(Date.self, forKey: .creationDate)
        completionDate = try attributes.decodeIfPresent(Date.self, forKey: .completionDate)
    }

    /// Encodes this value into the given encoder.
    public func encode(to encoder: Encoder) throws {
        var attributes = try self.attributes(CodingKeys.self, for: encoder)
        try attributes.encodeIfPresent(title, forKey: .title)
        try attributes.encodeIfPresent(archived, forKey: .archived)
        try attributes.encodeIfPresent(creationDate, forKey: .creationDate)
        try attributes.encodeIfPresent(completionDate, forKey: .completionDate)
    }
}


// MARK: -

/// Represents a checklist item in Things.
public class TJSChecklistItem : TJSModelItem, Codable {
    public var title: String?
    public var completed: Bool?
    public var canceled: Bool?
    public var creationDate: Date?
    public var completionDate: Date?

    private enum CodingKeys: String, CodingKey {
        case title
        case completed
        case canceled
        case creationDate = "creation-date"
        case completionDate = "completion-date"
    }

    /// Create and return a new checklist item configured with the provided values.
    public init(operation: Operation = .create,
         title: String? = nil,
         completed: Bool? = nil,
         canceled: Bool? = nil,
         creationDate: Date? = nil,
         completionDate: Date? = nil) {

        super.init(operation: operation)
        self.type = "checklist-item"

        self.title = title
        self.completed = completed
        self.canceled = canceled
        self.creationDate = creationDate
        self.completionDate = completionDate
    }

    /// Create and return a new checklist item configured with same values as the provided checklist item.
    public convenience init (_ checklistItem: TJSChecklistItem) {
        self.init(title: checklistItem.title,
                  completed: checklistItem.completed,
                  canceled: checklistItem.canceled,
                  creationDate: checklistItem.creationDate,
                  completionDate: checklistItem.completionDate)
    }

    /// Creates a new instance by decoding from the given decoder.
    public required convenience init(from decoder: Decoder) throws {
        self.init()
        let attributes = try self.attributes(CodingKeys.self, from: decoder)
        title = try attributes.decodeIfPresent(String.self, forKey: .title)
        completed = try attributes.decodeIfPresent(Bool.self, forKey: .completed)
        canceled = try attributes.decodeIfPresent(Bool.self, forKey: .canceled)
        creationDate = try attributes.decodeIfPresent(Date.self, forKey: .creationDate)
        completionDate = try attributes.decodeIfPresent(Date.self, forKey: .completionDate)
    }

    /// Encodes this value into the given encoder.
    public func encode(to encoder: Encoder) throws {
        var attributes = try self.attributes(CodingKeys.self, for: encoder)
        try attributes.encodeIfPresent(title, forKey: .title)
        try attributes.encodeIfPresent(completed, forKey: .completed)
        try attributes.encodeIfPresent(canceled, forKey: .canceled)
        try attributes.encodeIfPresent(creationDate, forKey: .creationDate)
        try attributes.encodeIfPresent(completionDate, forKey: .completionDate)
    }
}


// MARK: - Internal Error

private enum TJSError : Error {
    case invalidType(expectedType: Any.Type, errorContext: DecodingError.Context)
}


// Mark: - Date Formatting

/// A date encoding strategy to format a date according to ISO8601.
///
/// Use to with a JSONEncoder to correctly format dates.
public func ThingsJSONDateEncodingStrategy() -> JSONEncoder.DateEncodingStrategy {
    if #available(iOS 10, OSX 10.12, *) {
        return .iso8601
    }
    else {
        return .formatted(isoDateFormatter())
    }
}

/// A date decoding strategy to format a date according to ISO8601.
///
/// Use to with a JSONDecoder to correctly format dates.
public func ThingsJSONDateDecodingStrategy() -> JSONDecoder.DateDecodingStrategy {
    if #available(iOS 10, OSX 10.12, *) {
        return .iso8601
    }
    else {
        return .formatted(isoDateFormatter())
    }
}

private func isoDateFormatter() -> DateFormatter {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

    return dateFormatter
}
