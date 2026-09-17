package apps::hashicorp::consul::restapi::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $self->{modes} = {
        'health'       => 'apps::hashicorp::consul::restapi::mode::health',
    };

    $self->{custom_modes}->{api} = 'apps::hashicorp::consul::restapi::custom::api';
    return $self;
}

1;

__END__
=head1 PLUGIN DESCRIPTION

Check HashiCorp Consul using RestAPI.

=cut