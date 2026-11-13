package apps::hashicorp::nomad::restapi::mode::health;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'nomad_cluster', type => 1, cb_prefix_output => 'custom_prefix_output'},
    ];

    $self->{maps_counters}->{nomad_cluster} = [
        { label => 'client-status', type => 2, critical_default => '%{client} ne "ok"', set => {
                key_values => [ { name => 'client' } ],
                output_template => "client status : %s",
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'server-status', type => 2, critical_default => '%{server} ne "ok"', set => {
                key_values => [ { name => 'server' } ],
                output_template => "server status : %s",
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub custom_prefix_output {
    my ($self, %options) = @_;

    return 'Nomad ';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub set_options {
    my ($self, %options) = @_;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(url_path => 'agent/health');

    $self->{nomad_cluster}->{$self->{option_results}->{hostname}} = {
        client => $result->{client}->{ok} ? 'ok' : 'not ok',
        server => $result->{server}->{ok} ? 'ok' : 'not ok',
    };
}

1;

__END__

=head1 MODE

Check Hashicorp Nomad Health status.

Example:
perl centreon_plugins.pl --plugin=apps::hashicorp::nomad::restapi::plugin --mode=health
--hostname=10.0.0.1 --nomad-token='s.aBCD123DEF456GHI789JKL012' --verbose

More information on'https://developer.hashicorp.com/nomad/api-docs/agent#health'.

=over 8

=item B<--warning-client-status>

Set warning threshold for status (default: none).

=item B<--critical-client-status>

Set critical threshold for seal status (default: '%{client} ne "ok"').

=item B<--warning-server-status>

Set warning threshold for status (default: none).

=item B<--critical-server-status>

Set critical threshold for seal status (default: '%{server} ne "ok"').

=back

=cut
