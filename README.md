## Silversides

Silversides is a project that builds a framework containing two custom controls, and a demonstration application that uses those controls to select and display a file URL.

### OBWFilteringMenu

OBWFilteringMenu implements an NSMenu-like menu that allows items to be filtered by typing.  Filter strings may be either simple text, or a regular expression in the form of **g/_[pattern]_/**.  Each item has a title and an optional image.  Items may be defined as "alternate" items that are hidden unless a specific combination of keyboard modifiers are pressed.

![OBWFilteringMenu sample image](https://github.com/KenHeglund/Silversides/tree/readme_updates/README.assets/OBWFilteringMenu.png)

The demonstration application creates OBWFilteringMenu popup menus for each of the elements of the OBWPathView view.

### OBWPathView

OBWPathView displays a series of hierarchical elements.  Each element has a title and an optional image.  NSMenu or OBWFilteringMenu popup menus may be associated with each element.

![OBWPathView sample image](https://github.com/KenHeglund/Silversides/tree/readme_updates/README.assets/OBWPathView.png)

The demonstration application implements an OBWPathView that displays a file path on the local drive and provides OBWFilteringMenu menus for each element that allow a new path to be selected.

### Build Environment

* Swift 2.3
* Xcode 8.1 / macOS 10.12 SDK
* Deploys to macOS 10.11 or newer
