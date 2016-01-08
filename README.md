# OpzWorks CLI

Command line interface for managing AWS OpsWorks chef cookbooks and stack json, as well
as other OpsWorks centric tasks such as generating ssh configs for OpsWorks instances.

## Wiki

See the [wiki](https://github.com/mapzen/opzworks/wiki) for more detailed information on getting started, walkthroughs, etc.

## Build Status

[![Circle CI](https://circleci.com/gh/mapzen/opzworks.svg?style=svg)](https://circleci.com/gh/mapzen/opzworks)

## Third party requirements:

Aside from a recent version of ruby:

* git
* [ChefDK](https://downloads.chef.io/chef-dk/)

## Installation

Install for use on the command line (requires ruby and rubygems): `gem install opzworks`

Then run `opzworks --help`

To use the gem in a project, add `gem 'opzworks'` to your Gemfile, and then execute: `bundle`

To build locally from this repository: `rake install`

## Commands

Run `opzworks` with one of the following commands:

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

## Configuration

The gem reads information from `~/.aws/config`, or from the file referenced by
the `AWS_CONFIG_FILE` environment variable. It should already look something like this:

    [default]
    aws_access_key_id     = ilmiochiaveID
    aws_secret_access_key = ilmiochiavesegreto
    region                = us-east-1
    output                = json

If you want the gem to read from an environment other than 'default', you can do so
by exporting the `AWS_PROFILE` environment variable. It should be set to whatever profile
name you have defined that you want to use in the config file.

Add the following section to `~/.aws/config`:

    [opzworks]
    ssh-user-name         = <MY SSH USER NAME>
    berks-repository-path = <PATH TO OPSWORKS BERKSHELF REPOSITORIES>
    berks-github-org      = <GITHUB ORG THAT YOUR OPSWORKS REPOSITORIES EXIST UNDER>
    berks-s3-bucket       = <AN EXISTING S3 BUCKET>

The `ssh-user-name` value should be set to the username you want to use when
logging in remotely, most probably the user name from your _My Settings_ page
in OpsWorks.

The `berks-repository-path` should point to a base directory in which your opsworks
git repositories for each stack will live.

The `berks-s3-bucket` will default to 'opzworks' if not set. You need to create the
the bucket manually (e.g. `aws s3 mb s3://opsworks-cookbook-bucket`).

The `berks-github-org` setting is used if you try to run `berks` or `json` on a stack, and
the local opsworks-${project} repo isn't found. In this event, the code will attempt to clone
the repo into `berks-repository-path` and continue.

Additional options are:

`berks-base-path`, which is the temporary base directory where the berkshelf will be
built. Defaults to /tmp.

`berks-tarball-name`, which is the name of the tarball that will be uploaded to S3. Defaults to cookbooks.tgz.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
