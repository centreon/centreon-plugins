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

package apps::voip::asterisk::ami::mode::dahdistatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf('status : %s', $self->{result_values}->{status});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{description} = $options{new_datas}->{$self->{instance} . '_description'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'dahdi', type => 1, cb_prefix_output => 'prefix_dahdi_output', message_multiple => 'All dahdi lines are ok' },
    ];
    
    $self->{maps_counters}->{dahdi} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'description' }, { name => 'status' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "filter-description:s"    => { name => 'filter_description' },
                                  "warning-status:s"        => { name => 'warning_status', default => '%{status} =~ /UNCONFIGURED|YEL|BLU/i' },
                                  "critical-status:s"       => { name => 'critical_status', default => '%{status} =~ /RED/i' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub prefix_dahdi_output {
    my ($self, %options) = @_;
    
    return "Line '" . $options{instance_value}->{description} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;
    
    # Status can be: OK, UNCONFIGURED, BLU, YEL, RED, REC (recover), NOP (notopen), UUU
    
    #Description                              Alarms     IRQ        bpviol     CRC4      
    #Wildcard TDM410P Board 1                 OK         0          0          0         
    #Wildcard TDM800P Board 2                 OK         0          0          0  
    
    #Description                              Alarms  IRQ    bpviol CRC    Fra Codi Options  LBO
    #Wildcard TE131/TE133 Card 0              BLU/RED 0      0      0      CCS HDB3          0 db (CSU)/0-133 feet (DSX-1)
    my $result = $options{custom}->command(cmd => 'dahdi show status');
    
    $self->{dahdi} = {};
    foreach my $line (split /\n/, $result) {
        if ($line =~ /^(.*?)\s+((?:OK|UNCONFIGURED|BLU|YEL|RED|REC|NOP|UUU)[^\s]*)\s+/msg) {
            my ($description, $status) = ($1, $2);
            if (defined($self->{option_results}->{filter_description}) && $self->{option_results}->{filter_description} ne '' &&
                $description !~ /$self->{option_results}->{filter_description}/) {
                $self->{output}->output_add(long_msg => "skipping '" . $description . "': no matching filter.", debug => 1);
                next;
            }
            
            $self->{dahdi}->{$description} = {
                description => $description,
                status => $status,
            };
        }
    }

    if (scalar(keys %{$self->{dahdi}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No dahdi lines found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check status of dahdi lines.

=over 8

=item B<--filter-description>

Filter dahdi description (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '%{status} =~ /UNCONFIGURED|YEL|BLU/i').
Can used special variables like: %{description}, %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /RED/i').
Can used special variables like: %{description}, %{status}

=back

=cut
