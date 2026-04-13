use strict;
use warnings;
use Test2::V0;

use Test2::Tools::Compare qw{is like match};
use FindBin;
use lib "$FindBin::RealBin/../../../src";
use centreon::plugins::misc qw/mask_secrets/;

sub mask_secrets_execute() {
    my @tests = ( {  original => 'raidcom get system -password MySecretPass123 -I100',
                     masked   => 'raidcom get system -password *** -I100'
                  },
                  {  original => 'pairdisplay -password=SuperSecret123 -g GRP1',
                     masked   => 'pairdisplay -password=*** -g GRP1'
                  },
                  {  original => 'curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9" https://test.com',
                     masked   => 'curl -H "Authorization: Bearer ***" https://test.com'
                  },
                  {  original => 'curl -H "Authorization: Basic ABCDEF" https://test.com',
                     masked   => 'curl -H "Authorization: Basic ***" https://test.com'
                  },
                  {  original => 'snmpwalk -snmp-community=tutu -v 2c localhost',
                     masked   => 'snmpwalk -snmp-community=*** -v 2c localhost'
                  },
                  {  original => 'snmpwalk -c MyCommunitString123 -v 2c localhost',
                     masked   => 'snmpwalk -c *** -v 2c localhost'
                  },
                  {  original => 'ssh -l admin user@host.com',
                     masked   => 'ssh -l admin user@host.com'
                  },
                  {  original => 'mysql -u root -pMyPassword123 database',
                     masked   => 'mysql -u root -p*** database'
                  },
                  {  original => 'mysql -u root -p MyPassword123 database',
                     masked   => 'mysql -u root -p *** database'
                  },
                  {  original => 'pg_dump -U postgres -W database',
                     masked   => 'pg_dump -U postgres -W database'
                  },
                  {  original => 'curl --header "api-key: sk-1234567890abcdef" https://test.com',
                     masked   => 'curl --header "api-key: ***" https://test.com'
                  },
                  {  original => 'prog get path -token=abc123def456 -I100',
                     masked   => 'prog get path -token=*** -I100'
                  },
                  {  original => 'PVX-Authorization: P@sSw@RdZ',
                     masked   => 'PVX-Authorization: ***'
                  },
                  {  original => 'Authorization: Basic ABCDEF',
                     masked   => 'Authorization: Basic ***'
                  },
                  {  original => 'https://admin:SecurePass@test.com:8080/api',
                     masked   => 'https://admin:***@test.com:8080/api',
                  },
                  {  original => '/tmp/centreon-plugins/test.pl --secret=secret',
                     masked   => '/tmp/centreon-plugins/test.pl --secret=***',
                  },
    );

    foreach my $test (@tests) {
        my $masked = mask_secrets($test->{original});
	ok($test->{masked} eq $masked, "Masks secrets in '".$test->{original} . "' => '" . $masked."'");
    }
}

mask_secrets_execute();
done_testing();
