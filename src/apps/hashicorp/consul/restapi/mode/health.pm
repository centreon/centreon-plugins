package apps::hashicorp::consul::restapi::mode::health;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'consul_cluster', type => 1, cb_prefix_output => 'custom_prefix_output'},
    ];

    $self->{maps_counters}->{consul_cluster} = [
        { label => 'node status', type => 2, critical_default => '%{status} ne "passing"', set => {
                key_values => [ { name => 'status' } ],
                output_template => "node status : %s",
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub custom_prefix_output {
    my ($self, %options) = @_;

    return 'Node ' . $self->{option_results}->{node} . ' ';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'node:s' => { name => 'node' }
    });

    return $self;
}

sub set_options {
    my ($self, %options) = @_;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(url_path => 'health/node/' . $self->{option_results}->{node});

    $self->{consul_cluster}->{$self->{option_results}->{node}} = {
        node => $self->{option_results}->{node},
        status => $result->[0]->{Status}
    };
}

1;

__END__

=head1 MODE

Check Hashicorp Consul Health status.

Example:
perl centreon_plugins.pl --plugin=apps::hashicorp::consul::restapi::plugin --mode=health
--hostname=10.0.0.1 --consul-token='s.aBCD123DEF456GHI789JKL012' --verbose

More information on'https://developer.hashicorp.com/consul/api-docs/health'.

=over 8

=item B<--node>

Specify the name or ID of the node to query when calling health api.

=item B<--warning-status>

Set warning threshold for seal status (default: none).

=item B<--critical-status>

Set critical threshold for seal status (default: '%{sealed} ne "unsealed"').

=back

=cut
