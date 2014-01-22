# Meteor Emblem

This package brings [Emblem](http://emblemjs.com/) to Meteor.

## Installation

Meteor Emblem can be installed with [Meteorite](https://github.com/oortcloud/meteorite/). From inside a Meteorite-managed app:

``` sh
$ mrt add emblem
```

## Basics

Files ending in `.emblem` will be treated as emblem files and have the same functionality as their Handlebars equivalent.

## Contributing

There's a problem with testing using `mrt test-packages`.

Instead, from a meteor app with emblem installed as a package, use:

``` sh
$ meteor test-packages packages/emblem
```