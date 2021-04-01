# HOWTO Centos

> :warning: **cwrapper_perl is deprecated** because of security issue.
> Prefer usage of a sudoers file or use it at your own risk.

Install dependencies:

    # yum install perl-devel 'perl(ExtUtils::Embed)'

Compile the wrapper:

    # gcc -o cwrapper_perl cwrapper_perl.c `perl -MExtUtils::Embed -e ccopts -e ldopts`

Create a fatpack: https://github.com/centreon/centreon-plugins/blob/master/doc/en/user/guide.rst#can-i-have-one-standalone-perl-file-

Comment following lines in the end of fatpack file:

    use strict;
    use warnings;
    # Not perl embedded compliant at all
    #use FindBin;
    #use lib "$FindBin::Bin";
    # use lib '/usr/lib/nagios/plugins/';

    use centreon::plugins::script;

    centreon::plugins::script->new()->run();

Set setuid right:

    # chown root:root cwrapper_perl
    # chmod 4775 cwrapper_perl

Test it:

    $ cwrapper_perl centreon_protocol_udp.pl --plugin --mode=connection --hostname=10.30.2.65 --port=161




