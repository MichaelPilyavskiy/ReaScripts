# ReaPack Repository Tools

[![Build Status](https://travis-ci.org/cfillion/reapack-repository-tools.svg?branch=master)](https://travis-ci.org/cfillion/reapack-repository-tools)

This folder contains the recommanded build script for the management
of [ReaPack](https://github.com/cfillion/reapack)-based repositories
using these tools:

- [metaheader](https://github.com/cfillion/metaheader):
  Parser for metadata headers
- [reapack-index](https://github.com/cfillion/reapack-index):
  Package indexer for ReaPack-based repositories

If you are building a new repository, install every file from this directory
(excluding README.md) in the root directory of your ReaPack-based repository.

File                   | Description
---------------------- | -------------------------------------------------------
Gemfile                | Dependency list. This tells `bundle install` what to do.
Rakefile               | This is the main build script for managing repositories
.gitignore             | Adds 'Gemfile.lock' (not Gemfile) to the list of files ignored by git
.travis.yml (optional) | Support for [Travis CI](https://travis-ci.org/) (running the tests at every commit pushed or pull requests)

### Setup for repository contributors

**Windows only:** You must install the latest version of Ruby from
[rubyinstaller.org](http://rubyinstaller.org/) in order to use these tools
(enable "Add Ruby executables to your PATH" when installing).
[GitHub For Desktop](https://desktop.github.com/) or any other
[git](https://git-scm.com/download/win) distribution is required as well.

Open Terminal.app on Mac or Git Shell on Windows and navigate to
your repository's directory using the following command:

```sh
# Mac OS X:
cd /path/to/your/repository

# Windows:
cd C:\Path\To\Your\Repository
```

Install the build tools and their dependencies:

```sh
gem install bundler
bundle install
```

Run `bundle update` once in a while to ensure you are always using the 
latest version of the tools (note that it doesn't update the build script
from this repository).

### Usage

Test the repository for invalid metadata tags:

```
bundle exec rake test
```

To generate or update `index.xml` (the database used by
[ReaPack](https://github.com/cfillion/reapack)) up to the
**latest commit** (uncommited changes are ignored):

```
bundle exec rake index
```

If you are using this command for the first time on a already existing
repository, run this command instead to silence the warnings for old commits:

```
bundle exec rake index -- --no-warnings
```

To modify an already released version of a package
(don't run this unless you know you need to):

```
bundle exec rake index -- --amend
```

**Bonus:** Run the tests and update `index.xml` using a single command:

```
bundle exec rake test index
```

### Resources

- [Batch header converter](https://gist.github.com/cfillion/6d99012e7eb971fdf937)
