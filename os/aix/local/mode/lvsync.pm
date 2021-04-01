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

package os::aix::local::mode::lvsync;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output { 
    my ($self, %options) = @_;

    return sprintf(
        'state: %s [lp: %s  pp: %s  pv: %s]',
        $self->{result_values}->{state},
        $self->{result_values}->{lp},
        $self->{result_values}->{pp},
        $self->{result_values}->{pv}
    );
}

sub prefix_lv_output {
    my ($self, %options) = @_;

    return sprintf(
        "Logical volume '%s' [mount point: %s] ",
        $options{instance_value}->{lv},
        $options{instance_value}->{mount}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'lvs', type => 1, cb_prefix_output => 'prefix_lv_output', message_multiple => 'All logical volumes are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{lvs} = [
        { label => 'status', threshold => 0, set => {
                key_values => [
                    { name => 'state' }, { name => 'mount' },
                    { name => 'lv' }, { name => 'pp' },
                    { name => 'pv' }, { name => 'lp' },
                    { name => 'type' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
    ];
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-type:s'     => { name => 'filter_type' },
        'unknown-status:s'  => { name => 'unknown_status', default => '' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{state} =~ /stale/i' },
    });

    $self->{result} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status', 'unknown_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'lsvg',
        command_options => '-o | lsvg -i -l 2>&1'
    );

    $self->{lvs} = {};
    my @lines = split /\n/, $stdout;
    # Header not needed
    shift @lines;
    if (scalar @lines != 0){
        foreach my $line (@lines) {
            next if ($line !~ /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.*)/);
            my ($lv, $type, $lp, $pp, $pv, $lvstate, $mount) = ($1, $2, $3, $4, $5, $6, $7);
            
            next if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
                $type !~ /$self->{option_results}->{filter_type}/);
            next if (defined($self->{option_results}->{filter_mount}) && $self->{option_results}->{filter_mount} ne '' &&
                $mount !~ /$self->{option_results}->{filter_mount}/);
            
            $self->{lvs}->{$mount} = {
                lv => $lv,
                mount => $mount,
                type => $type,
                lp => $lp,
                pp => $pp,
                pv => $pv, 
                state => $lvstate
            };
        }
    }

    if (scalar(keys %{$self->{lvs}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No logical volumes found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check vg mirroring.
Command used: lsvg -o | lsvg -i -l 2>&1

=over 8

=item B<--filter-type>

Filter filesystem type (regexp can be used).

=item B<--filter-mount>

Filter storage mount point (regexp can be used).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{state}, %{lv}, %{mount}, %{type}.

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{state}, %{lv}, %{mount}, %{type}.

=item B<--critical-status>

Set critical threshold for status (Default: '%{state} =~ /stale/i').
Can used special variables like: %{state}, %{lv}, %{mount}, %{type}.

=back

=cut
