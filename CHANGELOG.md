changelog
=========

0.5.3
-----
* remove detection of Berksfile.opsworks (for Chef 11.10 remote berkshelf management): not used, and will be deprecated.

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
