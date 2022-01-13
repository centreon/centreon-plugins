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

package os::windows::wmi::mode::listservices;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my %map_operating_status = (
    'OK'         => 'ok',
    'Error'      => 'error',
    'Degraded'   => 'degraded',
    'Unknown'    => 'unknown',
    'Pred Fail'  => 'pred-fail',
    'Starting'   => 'starting',
    'Stopping'   => 'stopping',
    'Stressed'   => 'stressed',
    'NonRecover' => 'non-recover',
    'No contact' => 'no-contact',
    'Lost Comm'  => 'lost-comm',
);
my %map_operating_state = (
    'Stopped'          => 'stopped',
    'Start Pending'    => 'start-pending',
    'Stop Pending'     => 'stop-pending',
    'Running'          => 'running',
    'Continue Pending' => 'continue-pending',
    'Pause Pending'    => 'pause-pending',
    'Paused'           => 'paused',
    'Unknown'          => 'unknown',
);
my %map_start_mode = (
    'Boot'     => 'boot',
    'System'   => 'system',
    'Auto'     => 'auto',
    'Manual'   => 'manual',
    'Disabled' => 'disabled',
);


sub manage_selection {
    my ($self, %options) = @_;

    my $WQL = 'select name, displayname, Started, StartMode, State, Status FROM Win32_Service';
    my ($result, $exit_code) = $options{custom}->execute_command(
        query => $WQL,
        no_quit => 1
    );
    $result =~ s/\|/;/g;

    #
    #CLASS: Win32_Service
    #DisplayName;Name;Started;StartMode;State;Status
    #NSClient++ Monitoring Agent;nscp;True;Auto;Running;OK
    #

    my $results = {};
    while ($result =~ /^(.*?);(.*?);(.*?);(.*?);(.*?);(.*?)$/msg) {
        my ($svc_display, $svc_name, $svc_started, $svc_mode, $svc_operating_state, $svc_operating_status) = ($1, $2, $3, $4, $5, $6);
        next if ($svc_mode =~ /StartMode/);
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $svc_name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $svc_name . "': no matching filter.", debug => 1);
            next;
        }

        $results->{$svc_name} = { 
            name => $svc_name,
            state => $svc_operating_state,
            status => $svc_operating_status,
            mode => $svc_mode
        };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;
  
    my $results = $self->manage_selection(%options);
    foreach (sort keys %$results) {
        $self->{output}->output_add(long_msg => '[name = ' . $results->{$_}->{name} .
            "] [state = " . $map_operating_state{$results->{$_}->{state}} .
            "] [status = " . $map_operating_status{$results->{$_}->{status}} . 
            "] [mode = " . $map_start_mode{$results->{$_}->{mode}} . "]"
        );
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List services:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'status', 'state', 'mode']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(%options);
    foreach (sort keys %$results) {
        $self->{output}->add_disco_entry(
            name => $results->{$_}->{name},
            operating => $map_operating_state{$results->{$_}->{state}},
            installed => $map_operating_status{$results->{$_}->{status}},
            mode => $map_start_mode{$results->{$_}->{mode}},
        );
    }
}

1;

__END__

=head1 MODE

List windows services.

=over 8

=item B<--filter-name>

Filter by service name (can be a regexp).

=back

=cut
    
