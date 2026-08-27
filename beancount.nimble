# Package

version       = "1.0.0"
author        = "BeanCount"
description   = "A coffee-brew journal"
license       = "MIT"
srcDir        = "src"
bin           = @["beancount"]

# Dependencies
requires "nim >= 2.0.0"
requires "jester >= 0.6.0"
requires "bcrypt >= 0.2.0"
requires "db_connector >= 0.1.0"
