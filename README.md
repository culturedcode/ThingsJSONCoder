# Things JSON Coder

This repo contains a Swift file that allows the creation of the JSON required to be passed to the `json` command of Things’ URL scheme.

## Installation

To install, download the [`ThingsJSON.swift`](https://github.com/culturedcode/ThingsJSONCoder/blob/master/ThingsJSON.swift) file and add it as a source file to your own project. Alternatively, this repo can be cloned as either a real or fake submodule inside your project.

## Requirements

This code is written with Swift 4.

## Getting Started

#### The Things JSON Container

The top level object that will be encoded into the JSON array is the `TJSContainer`. This object contains an array of the items to be included in the JSON.

#### Model Classes

The following Things model classes can be encoded into JSON:

* `Todo`
* `Project`
* `Heading`
* `ChecklistItem`

#### Container Enums

There are two wrapper enums used to package objects into arrays. Associated values are used to hold the above model objects inside. These enums exist to allow more than one type of object inside an array while retaining type safety. They also handle the encoding and decoding of heterogeneous types within an array to and from JSON.

* `TJSContainer.Item` – This enum has cases for todo and project objects. Only todo and project items can exist at the top level array in the JSON.

* `TJSProject.Item` – This enum has cases for todo and heading objects. Only todo and heading objects can be items inside a project.

#### Dates
Dates should be formatted according to ISO8601. Setting the JSON encoder’s `dateEncodingStrategy` to `ThingsJSONDateEncodingStrategy()` is the easiest way to do this (see example below).

## Example

Create two todos and a project, encode them into JSON and send to Things’ add command.

```Swift
let todo1 = TJSTodo(title: "Pick up dry cleaning", when: "today")
let todo2 = TJSTodo(title: "Pack for vacation",
                    checklistItems: [TJSChecklistItem(title: "Camera"),
                                     TJSChecklistItem(title: "Passport")])

let project = TJSProject(title: "Go Shopping",
                         items: [.heading(TJSHeading(title: "Dairy")),
                                 .todo(TJSTodo(title: "Milk"))])

let container = TJSContainer(items: [.todo(todo1),
                                     .todo(todo2),
                                     .project(project)])
do {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = ThingsJSONDateEncodingStrategy()
    let data = try encoder.encode(container)
    let json = String.init(data: data, encoding: .utf8)!
    var components = URLComponents.init(string: "things:///add-json")!
    let queryItem = URLQueryItem.init(name: "data", value: json)
    components.queryItems = [queryItem]
    let url = components.url!
    UIApplication.shared.open(url, options: [:], completionHandler: nil)
}
catch {
    // Handle error
}
```

## License

This code is released under the MIT license. See [LICENSE](https://github.com/culturedcode/ThingsJSONCoder/blob/master/LICENSE) for details.
