# Things JSON Coder

This repo contains a Swift file that allows the creation of the JSON required to be passed to the `add-json` command of Things’ URL scheme.

## Installation

To install, download the [`ThingsJSONObjects.swift`](https://github.com/culturedcode/ThingsJSONCoder/blob/master/ThingsJSONObjects.swift) file and add it as a source file to your own project. Alternatively, this repo can be cloned as either a real or fake submodule inside your project.

## Requirements

This code is written with Swift 4.

## Things Model Classes

The following model classes can be encoded into JSON:

* `TJSTodo`
* `TJSProject`
* `TJSHeading`
* `TJSChecklistItem`

#### Container enums

There are two wrapper enums used to package objects into arrays. Associated objects are used to hold the above model objects inside. These enums exist to allow more than one type of object inside an array while retaining type safety. They also handle the encoding and decoding of heterogeneous types within an array to and from JSON.

* `TJSToplevelItem` – This enum has cases for todo and project objects. An array of top level items (`[TJSToplevelItem]`) should be the root object that is encoded into the JSON that is passed to the URL scheme.

* `TJSProject.Item` – This enum has cases for todo and heading objects. Only todo and heading objects can be items inside a project.

## Examples

#### Create a todo

```Swift
let todo1 = TJSTodo(title: "Pick up dry cleaning", when: "today")
```

#### Create a todo with checklist items

Checklist items do not need to be wrapped in any enum as there is only a single object type inside a todo’s checklist items array.

```Swift
let todo2 = TJSTodo(title: "Pack for vacation",
                    checklistItems: [TJSChecklistItem(title: "Camera"),
                                     TJSChecklistItem(title: "Passport")])
```

#### Create a project containing a heading and a todo

Each item inside a project must be wrapped in a `TJSProject.Items` enum.

```Swift
let project = TJSProject(title: "Go Shopping",
                         items: [.heading(TJSHeading(title: "Dairy")),
                                 .todo(TJSTodo(title: "Milk"))])
```

#### Encode the above todos and project as JSON

```Swift
let items = [TJSTopLevelItem.todo(todo1),
             TJSTopLevelItem.todo(todo2),
             TJSTopLevelItem.project(project)]
do {
    let encoder = JSONEncoder()
    let data = try encoder.encode(items)
    let json = String.init(data: data, encoding: .utf8)
}
catch {
    // Handle error
}
```

#### Percent encode JSON, create a URL and open Things

The resultant JSON is then ready to be percent encoded and used to invoke the Things URL scheme. When percent encoding, ensure to specify the `.urlQueryAllowed` character set.

```Swift
let jsonEncoded = json.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
let url = URL(string: "things:///add-json?data=\(jsonEncoded)")!
UIApplication.shared.open(url, options: [:], completionHandler: nil)
```

## License

This code is released under the MIT license. See LICENSE for details.
