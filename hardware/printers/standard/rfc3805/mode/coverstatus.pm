#
# Copyright 2021 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package hardware::printers::standard::rfc3805::mode::coverstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_cover_output {
    my ($self, %options) = @_;

    return "Cover '" . $options{instance_value}->{description} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'covers', type => 1, cb_prefix_output => 'prefix_cover_output', message_multiple => 'All covers are ok' }
    ];

    $self->{maps_counters}->{covers} = [
        {
            label => 'status',
            type => 2,
            unknown_default => '%{status} =~ /other|unknown/',
            warning_default => '%{status} =~ /coverOpen|interlockOpen/',
            set => {
                key_values => [ { name => 'status' }, { name => 'description' } ],
                output_template => "status is '%s'",
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
    });

    return $self;
}

my $map_status = {
    1 => 'other', 2 => 'unknown',
    3 => 'coverOpen', 4 => 'coverClosed',
    5 => 'interlockOpen', 6 => 'interlockClosed'
};

my $mapping = {
    description => { oid => '.1.3.6.1.2.1.43.6.1.1.2' }, # prtCoverDescription
    status      => { oid => '.1.3.6.1.2.1.43.6.1.1.3', map => $map_status } # prtCoverStatus
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_prtCoverTable = '.1.3.6.1.2.1.43.6.1';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_prtCoverTable,
        start => $mapping->{description}->{oid},
        nothing_quit => 1
    );

    $self->{covers} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{status}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        $result->{description} = centreon::plugins::misc::trim($result->{description});
        $self->{covers}->{$instance} = $result;
    }
}

1;

__END__

=head1 MODE

Check covers of the printer.

=over 8

=item B<--unknown-status>

Set unknown threshold for status (Default: '%%{status} =~ /other|unknown/').
Can used special variables like: %{status}, %{description}

=item B<--warning-status>

Set warning threshold for status (Default: '%%{status} =~ /coverOpen|interlockOpen/').
Can used special variables like: %{status}, %{description}

=item B<--critical-status>

Set critical threshold for status.
Can used special variables like: %{status}, %{description}

=back

=cut
