# OpzWorks CLI

Command line interface for managing AWS OpsWorks chef cookbooks and stack json, as well
as other OpsWorks centric tasks such as generating ssh configs for OpsWorks instances.

## Wiki

#### See the [wiki](https://github.com/mapzen/opzworks/wiki) for more detailed information on getting started, walkthroughs, etc.

## Build Status

[![Circle CI](https://circleci.com/gh/mapzen/opzworks.svg?style=svg)](https://circleci.com/gh/mapzen/opzworks)

## Third party requirements:

Ruby 2.3+, and...

* git
* [ChefDK](https://downloads.chef.io/chef-dk/)

#### Again, please see the [wiki](https://github.com/mapzen/opzworks/wiki) for details!

## Installation

Install for use on the command line (requires ruby and rubygems): `gem install opzworks`

Then run `opzworks --help`

To use the gem in a project, add `gem 'opzworks'` to your Gemfile, and then execute: `bundle`

To build locally from this repository: `rake install`

## Commands

#### ssh

Generate and update SSH configuration files, or alternatively return a list of IPs for matching stacks.

#### elastic

Perform [start|stop|bounce|rolling] operations on an Elastic cluster.

The host from which this command is originated will need to have access to the the target
systems via private IP and assumes port 9200 is open and available.

This is a very rough implementation!

#### json

Update stack custom JSON.

#### berks

Build the berkshelf for a stack, or only upload the Berksfile to allow remote berkshelf management on the host, upload the tarball to S3, trigger `update_custom_cookbooks` on the stack.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
