package storage::datacore::api::plugin;
use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    # A version, we don't really use it but could help if your want to version your code
    $self->{version} = '0.1';

    $self->{modes} = {
        'pool-usage' => 'storage::datacore::api::mode::poolspaceusage',
        'alerts-count' => 'storage::datacore::api::mode::alertscount',
        'list-pool' => 'storage::datacore::api::mode::listpool',
        'status-monitor' => 'storage::datacore::api::mode::statusmonitor',
    };
    $self->{custom_modes}->{api} = 'storage::datacore::api::custom::api';
    return $self;
}
1;