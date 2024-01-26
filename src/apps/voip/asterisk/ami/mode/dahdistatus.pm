#
# Copyright 2024 Centreon (http://www.centreon.com/)
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
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;
    
    return sprintf('status : %s', $self->{result_values}->{status});
}

sub prefix_dahdi_output {
    my ($self, %options) = @_;
    
    return "Line '" . $options{instance_value}->{description} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'dahdi', type => 1, cb_prefix_output => 'prefix_dahdi_output', message_multiple => 'All dahdi lines are ok' },
    ];
    
    $self->{maps_counters}->{dahdi} = [
        { 
            label => 'status', 
            type => 2, 
            warning_default => '%{status} =~ /UNCONFIGURED|YEL|BLU/i',
            critical_default => '%{status} =~ /RED/i',
            set => {
                key_values => [ { name => 'description' }, { name => 'status' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "filter-description:s" => { name => 'filter_description' }
    });
    
    return $self;
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

Define the conditions to match for the status to be WARNING (default: '%{status} =~ /UNCONFIGURED|YEL|BLU/i').
You can use the following variables: %{description}, %{status}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /RED/i').
You can use the following variables: %{description}, %{status}

=back

=cut
