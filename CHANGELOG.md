changelog
=========

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
