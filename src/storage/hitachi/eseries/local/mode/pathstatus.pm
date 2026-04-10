#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package storage::hitachi::eseries::local::mode::pathstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters);
use centreon::plugins::misc qw/is_excluded/;

sub prefix_path_output {
    my ($self, %options) = @_;
    return "Path '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'paths', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_path_output',
          message_multiple => 'All paths are normal' }
    ];

    $self->{maps_counters}->{paths} = [
        { label => 'status', type => COUNTER_KIND_TEXT, critical_default => '%{status} ne "NML"', set => {
                key_values => [ { name => 'status' }, { name => 'display' }  ],
                output_template => 'Status: %s',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'include-port:s' => { name => 'include_port', default => '' },
        'exclude-port:s' => { name => 'exclude_port', default => '' },
        'include-lun:s'  => { name => 'include_lun',  default => '' },
        'exclude-lun:s'  => { name => 'exclude_lun',  default => '' }

    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    # https://docs.hitachivantara.com/r/en-us/command-control-interface/01-87-03/mk-90rd7009/configuration-setting-commands/raidcom-get-path
    # raidcom get path -I$<baie_id>

    my ($stdout) = $options{custom}->execute_command(
        command         => 'raidcom',
        command_options => 'get path -I' . $options{custom}->get_baie_id()
    );

    # Columns: PHG Group STS CM IF MP Port WWN PR LUN PHS Serial# ...
    $self->{paths} = {};
    foreach my $line (split /\n/, $stdout) {
        next if $line =~ /^PHG/ || $line =~ /^\s*$/;

        my @fields = split /\s+/, $line;
	next unless @fields > 10;
        my ($port, $lun, $phs) = ($fields[6], $fields[9], $fields[10]);

        next unless defined($port) && defined($lun) && defined($phs);

        next if is_excluded($port, $self->{option_results}->{include_port}, $self->{option_results}->{exclude_port});
        next if is_excluded($lun, $self->{option_results}->{include_lun}, $self->{option_results}->{exclude_lun});

        my $key = $port . ':' . $lun;
        $self->{paths}->{$key} = {
            display => $key,
            status  => $phs
        };
    }

    $self->{output}->option_exit(short_msg => "No path found.")
        unless keys %{$self->{paths}};
}

1;

__END__

=head1 MODE

Check Hitachi E-Series path status.

Command used: C<raidcom get path -I<baie-id>>

=over 8

=item B<--include-port>

Filter paths by port name (regexp, e.g. C<--include-port='CL1-A'>).

=item B<--exclude-port>

Exclude paths by port name (regexp).

=item B<--include-lun>

Filter paths by LUN ID (regexp).

=item B<--exclude-lun>

Exclude paths by LUN ID (regexp).

=item B<--warning-status>

Warning threshold for path status.

=item B<--critical-status>

Critical threshold for path status (default: C<'%{status} ne "NML"'>).

=back

=cut
