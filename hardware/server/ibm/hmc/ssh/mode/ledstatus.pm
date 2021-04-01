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

package hardware::server::ibm::hmc::ssh::mode::ledstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;
    
    return 'led state : ' . $self->{result_values}->{ledstate};
}

sub prefix_physical_output {
    my ($self, %options) = @_;
    
    return "System '" . $options{instance_value}->{display} . "' physical ";
}

sub prefix_virtuallpar_output {
    my ($self, %options) = @_;
    
    return "Virtual partition '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'physical', type => 1, cb_prefix_output => 'prefix_physical_output', message_multiple => 'All physical status are ok' },
        { name => 'virtuallpar', type => 1, cb_prefix_output => 'prefix_virtuallpar_output', message_multiple => 'All virtual partition status are ok' }
    ];
    
    $self->{maps_counters}->{physical} = [
        { label => 'physical-status', type => 2, critical_default => '%{ledstate} =~ /on/', set => {
                key_values => [ { name => 'ledstate' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{virtuallpar} = [
        { label => 'virtuallpar-status', type => 2, critical_default => '%{ledstate} =~ /on/', set => {
                key_values => [ { name => 'ledstate' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
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
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    #system: Server-8203-E4A-SN06DF9A5
    #  phys led: state=on
    #  lpar [LPAR1] led: off
    my ($content) = $options{custom}->execute_command(
        command => 'while read system ; do echo "system: $system"; echo -n "  phys led: "; lsled -r sa -m "$system" -t "phys" ; while read lpar; do echo -n "  lpar [$lpar] led: "; lsled -m "$system" -r sa -t virtuallpar --filter "lpar_names=$lpar" -F state ; done < <(lssyscfg -m "$system" -r lpar -F name) ; done < <(lssyscfg -r sys -F "name")
',
        command_options => '2>&1'
    );

    $self->{physical} = {};
    $self->{virtuallpar} = {};
    while ($content =~ /^system:\s+(.*?)\n(.*?)(?:system:|\Z)/msg) {
        my ($system_name, $subcontent) = ($1, $2);
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $system_name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $system_name . "': no matching filter.", debug => 1);
            next;
        }

        $subcontent =~ /phys\s+led:\s+state=(\S+)/;
        my $system_ledstate = $1;
        while ($subcontent =~ /lpar\s+\[(.*?)\]\s+led:\s+(\S+)/msg) {
            my ($lpar_name, $lpar_ledstate) = ($system_name . ':' . $1, $2);
            
            if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
                $lpar_name !~ /$self->{option_results}->{filter_name}/) {
                $self->{output}->output_add(long_msg => "skipping  '" . $lpar_name . "': no matching filter.", debug => 1);
                next;
            }

            $self->{virtuallpar}->{$lpar_name} = { display => $lpar_name, ledstate => $lpar_ledstate };
        }

        $self->{physical}->{$system_name} = { display => $system_name, ledstate => $system_ledstate };        
    }

    if (scalar(keys %{$self->{physical}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No managed system found.');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check LED status for managed systems.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^physical-status$'

=item B<--filter-name>

Filter name (can be a regexp).
Format of names: systemname[:lparname]

=item B<--warning-physical-status>

Set warning threshold (Default: '').
Can used special variables like: %{ledstate}, %{display}

=item B<--critical-physical-status>

Set critical threshold (Default: '%{ledstate} =~ /on/').
Can used special variables like: %{ledstate}, %{display}

=item B<--warning-virtuallpar-status>

Set warning threshold (Default: '').
Can used special variables like: %{ledstate}, %{display}

=item B<--critical-virtuallpar-status>

Set critical threshold (Default: '%{ledstate} =~ /on/').
Can used special variables like: %{ledstate}, %{display}

=back

=cut
