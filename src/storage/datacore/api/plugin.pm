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
    # Important part!
    #    On the left, the name of the mode as users will use it in their command line
    #    On the right, the path to the file (note that .pm is not present at the end)
    $self->{modes} = {
        'pool-usage' => 'storage::datacore::api::mode::poolspaceusage'
    };
    $self->{custom_modes}->{api} = 'storage::datacore::api::custom::api';
    return $self;
}
1;