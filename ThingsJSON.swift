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
class TJSContainer : Codable {

    /// The array of items that will be encoded or decoded from the JSON.
    var items = [Item]()

    /// Create and return a new ThingsJSON object configured with the provided items.
    init(items: [Item]) {
        self.items = items
    }

    /// Creates a new instance by decoding from the given decoder.
    required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.items = try container.decode([Item].self)
    }

    /// Encodes this value into the given encoder.
    func encode(to encoder: Encoder) throws {
        try self.items.encode(to: encoder)
    }

    /// An item that can exist inside the top level JSON array.
    ///
    /// This is an enum that wraps a TJSTodo or TJSProject object and handles its encoding
    /// and decoding to JSON. This is required because there is no way of specifiying a
    /// strongly typed array that contains more than one type.
    enum Item : Codable {
        case todo(TJSTodo)
        case project(TJSProject)

        /// Creates a new instance by decoding from the given decoder.
        init(from decoder: Decoder) throws {
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
        func encode(to encoder: Encoder) throws {
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
class TJSModelItem {
    fileprivate var type: String = ""

    private enum CodingKeys: String, CodingKey {
        case type
        case attributes
    }

    fileprivate func attributes<T>(_ type: T.Type, from decoder: Decoder) throws -> KeyedDecodingContainer<T> {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedType = try container.decode(String.self, forKey: .type)
        guard decodedType == self.type else {
            let description = String.init(format: "Expected to decode a %@ but found a %@ instead.", self.type, decodedType)
            let errorContext = DecodingError.Context.init(codingPath: [CodingKeys.type], debugDescription: description)
            let expectedType = Swift.type(of: self)
            throw TJSError.invalidType(expectedType: expectedType, errorContext: errorContext)
        }
        return try container.nestedContainer(keyedBy: T.self, forKey: .attributes)
    }

    fileprivate func attributes<T>(_ type: T.Type, for encoder: Encoder) throws -> KeyedEncodingContainer<T> {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.type, forKey: .type)
        return container.nestedContainer(keyedBy: T.self, forKey: .attributes)
    }
}


// MARK: -

/// Represents a to-do in Things.
class TJSTodo : TJSModelItem, Codable {
    var title: String?
    var notes: String?
    var when: String?
    var deadline: String?
    var tags: [String]?
    var checklistItems: [TJSChecklistItem]?
    var listID: String?
    var list: String?
    var heading: String?
    var completed: Bool?
    var canceled: Bool?

    private enum CodingKeys: String, CodingKey {
        case title
        case notes
        case when
        case deadline
        case tags
        case checklistItems = "checklist-items"
        case listID = "list-id"
        case list
        case heading
        case completed
        case canceled
    }

    /// Create and return a new todo configured with the provided values.
    init(title: String? = nil,
         notes: String? = nil,
         when: String? = nil,
         deadline: String? = nil,
         tags: [String]? = nil,
         checklistItems: [TJSChecklistItem]? = nil,
         listID: String? = nil,
         list: String? = nil,
         heading: String? = nil,
         completed: Bool? = nil,
         canceled: Bool? = nil) {

        super.init()
        self.type = "to-do"

        self.title = title
        self.notes = notes
        self.when = when
        self.deadline = deadline
        self.tags = tags
        self.checklistItems = checklistItems
        self.listID = listID
        self.list = list
        self.heading = heading
        self.completed = completed
        self.canceled = canceled
    }

    /// Create and return a new todo configured with same values as the provided todo.
    convenience init(_ todo: TJSTodo) {
        self.init(title: todo.title,
                  notes: todo.notes,
                  when: todo.when,
                  deadline: todo.deadline,
                  tags: todo.tags,
                  checklistItems: todo.checklistItems,
                  listID: todo.listID,
                  list: todo.list,
                  heading: todo.heading,
                  completed: todo.completed,
                  canceled: todo.canceled)
    }

    /// Creates a new instance by decoding from the given decoder.
    required convenience init(from decoder: Decoder) throws {
        self.init()
        let attributes = try self.attributes(CodingKeys.self, from: decoder)
        do {
            title = try attributes.decodeIfPresent(String.self, forKey: .title)
            notes = try attributes.decodeIfPresent(String.self, forKey: .notes)
            when = try attributes.decodeIfPresent(String.self, forKey: .when)
            deadline = try attributes.decodeIfPresent(String.self, forKey: .deadline)
            tags = try attributes.decodeIfPresent([String].self, forKey: .tags)
            checklistItems = try attributes.decodeIfPresent([TJSChecklistItem].self, forKey: .checklistItems)
            listID = try attributes.decodeIfPresent(String.self, forKey: .listID)
            list = try attributes.decodeIfPresent(String.self, forKey: .list)
            heading = try attributes.decodeIfPresent(String.self, forKey: .heading)
            completed = try attributes.decodeIfPresent(Bool.self, forKey: .completed)
            canceled = try attributes.decodeIfPresent(Bool.self, forKey: .canceled)
        }
        catch TJSError.invalidType(let expectedType, let errorContext) {
            throw DecodingError.typeMismatch(expectedType, errorContext)
        }
    }

    /// Encodes this value into the given encoder.
    func encode(to encoder: Encoder) throws {
        var attributes = try self.attributes(CodingKeys.self, for: encoder)
        try attributes.encodeIfPresent(title, forKey: .title)
        try attributes.encodeIfPresent(notes, forKey: .notes)
        try attributes.encodeIfPresent(when, forKey: .when)
        try attributes.encodeIfPresent(deadline, forKey: .deadline)
        try attributes.encodeIfPresent(tags, forKey: .tags)
        try attributes.encodeIfPresent(checklistItems, forKey: .checklistItems)
        try attributes.encodeIfPresent(listID, forKey: .listID)
        try attributes.encodeIfPresent(list, forKey: .list)
        try attributes.encodeIfPresent(heading, forKey: .heading)
        try attributes.encodeIfPresent(completed, forKey: .completed)
        try attributes.encodeIfPresent(canceled, forKey: .canceled)
    }
}


// MARK: -

/// Represents a project in Things.
class TJSProject : TJSModelItem, Codable {
    var title: String?
    var notes: String?
    var when: String?
    var deadline: String?
    var tags: [String]?
    var areaID: String?
    var area: String?
    var items: [Item]?
    var completed: Bool?
    var canceled: Bool?

    private enum CodingKeys: String, CodingKey {
        case title
        case notes
        case when
        case deadline
        case tags
        case areaID = "area-id"
        case area
        case items
        case completed
        case canceled
    }

    /// Create and return a new project configured with the provided values.
    init(title: String? = nil,
         notes: String? = nil,
         when: String? = nil,
         deadline: String? = nil,
         tags: [String]? = nil,
         areaID: String? = nil,
         area: String? = nil,
         items: [Item]? = nil,
         completed: Bool? = nil,
         canceled: Bool? = nil) {

        super.init()
        self.type = "project"

        self.title = title
        self.notes = notes
        self.when = when
        self.deadline = deadline
        self.tags = tags
        self.areaID = areaID
        self.area = area
        self.items = items
        self.completed = completed
        self.canceled = canceled
    }

    /// Create and return a new project configured with same values as the provided project.
    convenience init(_ project: TJSProject) {
        self.init(title: project.title,
                  notes: project.notes,
                  when: project.when,
                  deadline: project.deadline,
                  tags: project.tags,
                  areaID: project.areaID,
                  area: project.area,
                  items: project.items,
                  completed: project.completed,
                  canceled: project.canceled)
    }

    /// Creates a new instance by decoding from the given decoder.
    required convenience init(from decoder: Decoder) throws {
        self.init()
        let attributes = try self.attributes(CodingKeys.self, from: decoder)
        do {
            title = try attributes.decodeIfPresent(String.self, forKey: .title)
            notes = try attributes.decodeIfPresent(String.self, forKey: .notes)
            when = try attributes.decodeIfPresent(String.self, forKey: .when)
            deadline = try attributes.decodeIfPresent(String.self, forKey: .deadline)
            tags = try attributes.decodeIfPresent([String].self, forKey: .tags)
            areaID = try attributes.decodeIfPresent(String.self, forKey: .areaID)
            area = try attributes.decodeIfPresent(String.self, forKey: .area)
            completed = try attributes.decodeIfPresent(Bool.self, forKey: .completed)
            canceled = try attributes.decodeIfPresent(Bool.self, forKey: .canceled)
            items = try attributes.decodeIfPresent([Item].self, forKey: .items)
        }
        catch TJSError.invalidType(let expectedType, let errorContext) {
            throw DecodingError.typeMismatch(expectedType, errorContext)
        }
    }

    /// Encodes this value into the given encoder.
    func encode(to encoder: Encoder) throws {
        var attributes = try self.attributes(CodingKeys.self, for: encoder)
        try attributes.encodeIfPresent(title, forKey: .title)
        try attributes.encodeIfPresent(notes, forKey: .notes)
        try attributes.encodeIfPresent(when, forKey: .when)
        try attributes.encodeIfPresent(deadline, forKey: .deadline)
        try attributes.encodeIfPresent(tags, forKey: .tags)
        try attributes.encodeIfPresent(areaID, forKey: .areaID)
        try attributes.encodeIfPresent(area, forKey: .area)
        try attributes.encodeIfPresent(items, forKey: .items)
        try attributes.encodeIfPresent(completed, forKey: .completed)
        try attributes.encodeIfPresent(canceled, forKey: .canceled)
    }

    /// A child item of a project.
    ///
    /// This is an enum that wraps a TJSTodo or TJSHeading object and handles its encoding
    /// and decoding to JSON. This is required because there is no way of specifiying a
    /// strongly typed array that contains more than one type.
    enum Item : Codable {
        case todo(TJSTodo)
        case heading(TJSHeading)

        /// Creates a new instance by decoding from the given decoder.
        init(from decoder: Decoder) throws {
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
        func encode(to encoder: Encoder) throws {
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
class TJSHeading : TJSModelItem, Codable {
    var title: String?
    var archived: Bool?

    private enum CodingKeys: String, CodingKey {
        case title
        case archived
    }

    /// Create and return a new heading configured with the provided values.
    init(title: String? = nil,
         archived: Bool? = nil) {

        super.init()
        self.type = "heading"

        self.title = title
        self.archived = archived
    }

    /// Create and return a new heading configured with same values as the provided heading.
    convenience init(_ heading: TJSHeading) {
        self.init(title: heading.title,
                  archived: heading.archived)
    }

    /// Creates a new instance by decoding from the given decoder.
    required convenience init(from decoder: Decoder) throws {
        self.init()
        let attributes = try self.attributes(CodingKeys.self, from: decoder)
        title = try attributes.decodeIfPresent(String.self, forKey: .title)
        archived = try attributes.decodeIfPresent(Bool.self, forKey: .archived)
    }

    /// Encodes this value into the given encoder.
    func encode(to encoder: Encoder) throws {
        var attributes = try self.attributes(CodingKeys.self, for: encoder)
        try attributes.encodeIfPresent(title, forKey: .title)
        try attributes.encodeIfPresent(archived, forKey: .archived)
    }
}


// MARK: -

/// Represents a checklist item in Things.
class TJSChecklistItem : TJSModelItem, Codable {
    var title: String?
    var completed: Bool?
    var canceled: Bool?

    private enum CodingKeys: String, CodingKey {
        case title
        case completed
        case canceled
    }

    /// Create and return a new checklist item configured with the provided values.
    init(title: String? = nil,
         completed: Bool? = nil,
         canceled: Bool? = nil) {

        super.init()
        self.type = "checklist-item"

        self.title = title
        self.completed = completed
        self.canceled = canceled
    }

    /// Create and return a new checklist item configured with same values as the provided checklist item.
    convenience init (_ checklistItem: TJSChecklistItem) {
        self.init(title: checklistItem.title,
                  completed: checklistItem.completed,
                  canceled: checklistItem.canceled)
    }

    /// Creates a new instance by decoding from the given decoder.
    required convenience init(from decoder: Decoder) throws {
        self.init()
        let attributes = try self.attributes(CodingKeys.self, from: decoder)
        title = try attributes.decodeIfPresent(String.self, forKey: .title)
        completed = try attributes.decodeIfPresent(Bool.self, forKey: .completed)
        canceled = try attributes.decodeIfPresent(Bool.self, forKey: .canceled)
    }

    /// Encodes this value into the given encoder.
    func encode(to encoder: Encoder) throws {
        var attributes = try self.attributes(CodingKeys.self, for: encoder)
        try attributes.encodeIfPresent(title, forKey: .title)
        try attributes.encodeIfPresent(completed, forKey: .completed)
        try attributes.encodeIfPresent(canceled, forKey: .canceled)
    }
}


// MARK: - Internal Error

private enum TJSError : Error {
    case invalidType(expectedType: Any.Type, errorContext: DecodingError.Context)
}
