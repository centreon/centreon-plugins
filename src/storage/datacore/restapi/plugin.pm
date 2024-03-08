package storage::datacore::restapi::plugin;
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
        'pool-usage' => 'storage::datacore::restapi::mode::poolspaceusage',
        'alerts' => 'storage::datacore::restapi::mode::alerts',
        'list-pool' => 'storage::datacore::restapi::mode::listpool',
        'status-monitor' => 'storage::datacore::restapi::mode::monitorstatus',
    };
    $self->{custom_modes}->{api} = 'storage::datacore::restapi::custom::api';
    return $self;
}
1;
=head1 PLUGIN DESCRIPTION

Check Datacore using rest API.

