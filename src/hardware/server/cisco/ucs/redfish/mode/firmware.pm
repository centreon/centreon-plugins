#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

package hardware::server::cisco::ucs::redfish::mode::firmware;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global',     type => 0 },
        { name => 'components', type => 1, cb_prefix_output => 'prefix_output',
          message_multiple => 'All firmware components are ok' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'firmware.components.total.count', set => {
            key_values      => [ { name => 'total' } ],
            output_template => 'Total firmware components: %d',
            perfdatas       => [ { template => '%d', min => 0 } ],
        }},
    ];

    $self->{maps_counters}->{components} = [
        { label => 'status', type => 2,
          set => {
            key_values => [
                { name => 'id' }, { name => 'name' }, { name => 'version' }, { name => 'health' },
            ],
            output_template => "firmware '%s' version: %s [health: %s]",
            output_use      => ['name', 'version', 'health'],
            closure_custom_perfdata        => sub { return 0; },
            closure_custom_threshold_check => \&_threshold_check,
          }
        },
    ];
}

sub _threshold_check {
    my ($self, %options) = @_;

    my $version = $self->{result_values}->{version};
    my $name    = $self->{result_values}->{name};
    my $health  = $self->{result_values}->{health};

    if (defined($self->{instance_mode}->{option_results}->{critical_status})
        && $self->{instance_mode}->{option_results}->{critical_status} ne '') {
        ## no critic
        return 'CRITICAL' if eval "$self->{instance_mode}->{option_results}->{critical_status}";
    }
    if (defined($self->{instance_mode}->{option_results}->{warning_status})
        && $self->{instance_mode}->{option_results}->{warning_status} ne '') {
        return 'WARNING' if eval "$self->{instance_mode}->{option_results}->{warning_status}";
    }

    # Health-based check (Redfish Status.Health)
    return 'CRITICAL' if $health =~ /^Critical$/i;
    return 'WARNING'  if $health =~ /^Warning$/i;
    return 'OK';
}

sub prefix_output {
    my ($self, %options) = @_;
    return "Component '" . $options{instance_value}->{name} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-component:s'   => { name => 'filter_component' },
        'expected-version:s'   => { name => 'expected_version' },
        'warning-status:s'     => { name => 'warning_status',  default => '' },
        'critical-status:s'    => { name => 'critical_status', default => '' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $api_path = $options{custom}->{api_path};
    $self->{global}     = { total => 0 };
    $self->{components} = {};

    # Try /UpdateService/FirmwareInventory (standard Redfish)
    my $inventory;
    eval {
        $inventory = $options{custom}->request(endpoint => '/UpdateService/FirmwareInventory');
    };
    if ($@ || !defined($inventory)) {
        $self->{output}->add_option_msg(
            short_msg => 'Firmware inventory not available (/UpdateService/FirmwareInventory). '
                       . 'Check that UpdateService is enabled on this device.'
        );
        $self->{output}->option_exit();
    }

    for my $member_ref (@{$inventory->{Members} // []}) {
        my $member_url = $member_ref->{'@odata.id'} // '';
        next if $member_url eq '';
        $member_url =~ s{^\Q$api_path\E}{};

        my $fw     = $options{custom}->request(endpoint => $member_url);
        my $id      = $fw->{'Id'}      // 'unknown';
        my $name    = $fw->{'Name'}    // $id;
        my $version = $fw->{'Version'} // 'unknown';
        my $health  = $fw->{Status}->{Health} // 'OK';

        next if defined($self->{option_results}->{filter_component})
            && $self->{option_results}->{filter_component} ne ''
            && $name !~ /$self->{option_results}->{filter_component}/;

        # Override critical_status if --expected-version is set
        if (defined($self->{option_results}->{expected_version})
            && $self->{option_results}->{expected_version} ne ''
            && ($self->{option_results}->{critical_status} // '') eq '') {
            my $expected = $self->{option_results}->{expected_version};
            $self->{option_results}->{critical_status} = "\$version !~ /$expected/";
        }

        $self->{global}->{total}++;
        $self->{components}->{$id} = {
            id      => $id,
            name    => $name,
            version => $version,
            health  => $health,
        };
    }
}

1;

__END__

=head1 MODE

Check Cisco UCS firmware versions via Redfish API (/UpdateService/FirmwareInventory).

=over 8

=item B<--filter-component>

Filter components by name (regexp). Example: --filter-component='BIOS'

=item B<--expected-version>

Expected firmware version (regexp). Triggers CRITICAL when a version does not match.
Example: --expected-version='4\.1\.'

=item B<--warning-status>

Warning threshold. Perl expression using $version, $name, $health.

=item B<--critical-status>

Critical threshold. Perl expression using $version, $name, $health.
If --expected-version is set and this option is empty, it is set automatically.

=back

=cut
