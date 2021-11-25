# Package

version       = "0.1.0"
author        = "kevin hogeland"
description   = "pxed pixel editor firmware"
license       = "Proprietary"
srcDir        = "src"

bin = @[
    "main/main",
    "editor/desktop_host"
]


# Dependencies

requires "nim >= 1.4.8"
requires "nesper >= 0.6.1"
requires "vmath >= 1.0.9"
requires "opengl >= 1.2.6"
requires "staticglfw >= 4.1.3"

# includes nimble tasks for building Nim esp-idf projects
include nesper/build_utils/tasks
