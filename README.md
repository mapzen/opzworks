# OpzWorks CLI

Command line interface for managing AWS OpsWorks chef cookbooks and stack json, as well
as other OpsWorks centric tasks such as generating ssh configs for OpsWorks instances.

## Wiki

See the [wiki](https://github.com/mapzen/opzworks/wiki) for more detailed information on getting started, walkthroughs, etc.

## Build Status

[![Circle CI](https://circleci.com/gh/mapzen/opzworks.svg?style=svg)](https://circleci.com/gh/mapzen/opzworks)

## Third party requirements:

* Ruby 2.3 or greater
* Git
* [ChefDK](https://downloads.chef.io/chef-dk/)

## Installation

Install for use on the command line (requires ruby and rubygems): `gem install opzworks`

If you don't want to install opzworks globally you can run `gem install --user-install opzworks`. On a Mac this will install things in `${HOME}/.gem/ruby/2.3.0/bin` and you will need to invoke opzworks explicitly or update your `${PATH}` environment variable.

Then run `opzworks --help`

To use the gem in a project, add `gem 'opzworks'` to your Gemfile, and then execute: `bundle`

To build locally from this repository: `rake install`

## Config files

You will also need to ensure that you have the following config files:

### AWS

opzworks expects to be able to find a file at `${HOME}/.aws/credentials`. This is a standard `ini` style config file that looks like this (adjusted to your specifics):

```
[default]
aws_access_key_id     = YOUR-AWS-KEY
aws_secret_access_key = YOUR-AWS-SECRET
region                = us-east-1
output                = json
```

If that lokos kind of like [the AWS way of managing your (AWS) credentials](http://blogs.aws.amazon.com/security/post/Tx3D6U6WSFGOK2H/A-New-and-Standardized-Way-to-Manage-Credentials-in-the-AWS-SDKs) that's because it is.

_Actually you also need to have a `${HOME}/.aws/config` file because computers, I guess, so I just symlink them:_

```
ln -s ${HOME}/.aws/credentials ${HOME}/.aws/config
```

### Opsworks

opzworks expects to be able to find a file at `${HOME}/.opzworks/config`. This is a standard `ini` style config file that looks like this (adjusted to your specifics):

```
[default]
ssh-user-name         = USERNAME
berks-github-org      = mapzen
berks-s3-bucket       = mapzen-opsworks
berks-repository-path = /PATH/TO/BERKS-Y-THINGS
```

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
