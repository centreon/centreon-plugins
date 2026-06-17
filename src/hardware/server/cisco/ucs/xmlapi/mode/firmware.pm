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

package hardware::server::cisco::ucs::xmlapi::mode::firmware;

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
                { name => 'display' }, { name => 'type' },
                { name => 'version' }, { name => 'deployed_version' },
            ],
            output_template => "firmware '%s' [type: %s] version: %s (deployed: %s)",
            output_use      => ['display', 'type', 'version', 'deployed_version'],
            closure_custom_perfdata        => sub { return 0; },
            closure_custom_threshold_check => \&_threshold_check,
          }
        },
    ];
}

sub _threshold_check {
    my ($self, %options) = @_;

    my $version  = $self->{result_values}->{version};
    my $display  = $self->{result_values}->{display};
    my $type     = $self->{result_values}->{type};

    if (defined($self->{instance_mode}->{option_results}->{critical_status})
        && $self->{instance_mode}->{option_results}->{critical_status} ne '') {
        ## no critic
        return 'CRITICAL' if eval "$self->{instance_mode}->{option_results}->{critical_status}";
    }
    if (defined($self->{instance_mode}->{option_results}->{warning_status})
        && $self->{instance_mode}->{option_results}->{warning_status} ne '') {
        return 'WARNING' if eval "$self->{instance_mode}->{option_results}->{warning_status}";
    }
    return 'OK';
}

sub prefix_output {
    my ($self, %options) = @_;
    return "Component '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-component:s'   => { name => 'filter_component' },
        'filter-type:s'        => { name => 'filter_type' },
        'expected-version:s'   => { name => 'expected_version' },
        'warning-status:s'     => { name => 'warning_status',  default => '' },
        'critical-status:s'    => { name => 'critical_status',
            # Alert when version does not match expected (if --expected-version is set)
            default => 'defined($self->{instance_mode}->{option_results}->{expected_version}) '
                     . '&& $self->{instance_mode}->{option_results}->{expected_version} ne "" '
                     . '&& $version !~ /$self->{instance_mode}->{option_results}->{expected_version}/' },
    });

    return $self;
}

# Firmware type normalisation map (UCS class names to human-readable)
my %type_label = (
    'blade-controller' => 'blade-controller',
    'blade-bios'       => 'bios',
    'adaptor'          => 'adaptor',
    'fex-controller'   => 'fex',
    'switch-kernel'    => 'fi-kernel',
    'switch-software'  => 'fi-software',
    'iocard'           => 'iocard',
    'storage-controller' => 'storage-ctrl',
);

sub manage_selection {
    my ($self, %options) = @_;

    my $fw_list = $options{custom}->request(class_id => 'firmwareRunning');

    $self->{global}     = { total => 0 };
    $self->{components} = {};

    my %seen;  # dedup by (dn+type) since UCSM may return duplicates

    for my $fw (@{$fw_list}) {
        my $dn       = $fw->{dn}              // '';
        my $type     = $fw->{type}            // 'unknown';
        my $version  = $fw->{packageVersion}  // $fw->{version} // 'unknown';
        my $deployed = $fw->{deployedVersion} // $version;

        next if $version eq '' || $version =~ /^0\.0/;

        my $type_friendly = $type_label{$type} // $type;

        next if defined($self->{option_results}->{filter_type})
            && $self->{option_results}->{filter_type} ne ''
            && $type_friendly !~ /$self->{option_results}->{filter_type}/;

        # Build human-readable display name from DN
        (my $display = $dn) =~ s{/fw-running$}{};
        $display =~ s{sys/}{};
        $display =~ s{/mgmt}{};

        next if defined($self->{option_results}->{filter_component})
            && $self->{option_results}->{filter_component} ne ''
            && $display !~ /$self->{option_results}->{filter_component}/;

        my $key = "${display}::${type_friendly}";
        next if $seen{$key}++;

        $self->{global}->{total}++;
        $self->{components}->{$key} = {
            display          => $display,
            type             => $type_friendly,
            version          => $version,
            deployed_version => $deployed,
        };
    }
}

1;

__END__

=head1 MODE

Check Cisco UCS firmware versions via XML API (firmwareRunning class).

=over 8

=item B<--filter-component>

Filter components by display name (regexp). Example: --filter-component='blade-1'

=item B<--filter-type>

Filter by firmware type (regexp): blade-controller, bios, adaptor, fi-kernel, fi-software.
Example: --filter-type='bios'

=item B<--expected-version>

Expected firmware version (regexp). Generates a CRITICAL when a component version
does not match. Example: --expected-version='4\.2\(1'

=item B<--warning-status>

Warning threshold. Perl expression using $version, $display, $type.

=item B<--critical-status>

Critical threshold. Defaults to matching against --expected-version if provided.

=back

=cut
