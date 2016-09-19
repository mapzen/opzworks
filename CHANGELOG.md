changelog
=========

0.12.6
------
* validate stack json before commit

0.12.4
------
* large lint for rubocop 2.3 syntax

0.12.3
------
* cull backups

0.12.2
------
* bug fix

0.12.1
------
* lint

0.12.0
------
* update aws-sdk dependency to 2.2.37
* create backups of cookbook tarball before uploading new

0.11.1
------
* bump aws-sdk dependency
* bundle update

0.11.0
------
* opzworks config file moved out of ~/.aws/config to ~/.opzworks/config
* default opzworks config block is now assumed to be `[default]` (previously `[opzworks]`)
* overriding of selected opzworks profile is done via ENV: `OPZWORKS_PROFILE=something`

0.10.0
------
* allow override of default [opzworks] config block via ENV var: `OPZWORKS_PROFILE`
* better error handling if passed a missing `AWS_PROFILE`

0.9.0
-----
* allow updating only specific cookbooks in the berkshelf: when passing the `-u` update flag, you can now also specify a space delimited list of cookbooks following a `-c` switch (`-u` alone will continue to run `berks update` for the entire berksfile):

e.g. `opzworks berks transitland::d -u -c mapzen_transitland sensu`

0.8.0
-----
* change in behavior: `berks update` is now no longer the default, and will be skipped unless the --update flag is passed explicitly. This is to prevent unwanted updating of unpinned cookbooks. However, you must now be sure to pass --update when the situation requires it.
* to allow the short option of -u for `berks update`, the `update_custom_cookbooks` flag is now -ucc

0.7.3
-----
* bundle update
* bump rubocop to 0.37.0

0.7.2
-----
* improved formatting and messaging for json cmd output

0.7.1
-----
* more output formatting cleanup
* remove superflous cleanup commands

0.7.0
-----
* use `berks package` rather than vendor and archive
* dump overrides support

0.6.3
-----
* support for missing Berksfile.lock, such as when starting a new project

0.5.5
-----
* remove Berksfile.opsworks detection, deprecated

0.5.1
-----
* remove detection of chef stack for update custom cookbooks... the cmdline flag rules

0.5.0
-----
* commit Gemfile.lock

0.4.2
-----
* standardize behavior of json and berks commands: changes in a dirty working opsworks repo will
  be committed and pushed before the remote stack is updated

0.4.0
-----
* add framework for opsworks cmd structure
* add list-stacks option

0.3.9
-----
* add remote management berkshelf option back in: if there is a Berksfile.opsworks present in the
  opsworks-${project} repo, simply upload it to S3 (don't build the local berkshelf)

0.3.7
-----
* elastic code enhancements, including a timeout on ssh connect

0.3.6
-----
* bug fix for elasticsearch 'start'

0.3.4
-----
* -r option for `ssh` to return raw ips

0.3.0
-----
* attempt to clone opsworks-${project} repo if not found

0.2.4
-----
* provide ability to change the amount of diff context via --context {int} switch to json command

0.2.3
-----
* provide --private option for ssh to allow use of private ips (defaults to public)

0.2.2
-----
* big speed improvement for ssh by removing unecessary aws calls

0.2.1
-----
* documentation enhancements

0.2.0
-----
* elastic command support

0.1.0
-----
* initial release with berks/json/ssh support
