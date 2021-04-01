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

package snmp_standard::mode::printererror;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'printer', type => 3, cb_prefix_output => 'prefix_printer_output', cb_long_output => 'printer_long_output', indent_long_output => '    ', message_multiple => 'All printers are ok',
            group => [
                { name => 'errors', message_multiple => 'Printer is ok', type => 1, skipped_code => { -10 => 1 } },
            ]
        }
    ];

    $self->{maps_counters}->{errors} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                output_template => "status is '%s'",
                output_use => 'status',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_printer_output {
    my ($self, %options) = @_;

    return "Printer '" . $options{instance_value}->{display} . "' ";
}

sub printer_long_output {
    my ($self, %options) = @_;

    return "checking printer '" . $options{instance_value}->{display} . "'";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'ok-status:s'       => { name => 'ok_status', default => '%{status} =~ /ok/' },
        'unknown-status:s'  => { name => 'unknown_status', default => '' },
        'warning-status:s'  => { name => 'warning_status', default => '%{status} =~ /.*/' },
        'critical-status:s' => { name => 'critical_status', default => '' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['ok_status', 'unknown_status', 'warning_status', 'critical_status']);
}

my %errors_printer = (
    0 => 'low paper', 
    1 => 'no paper',
    2 => 'low toner',
    3 => 'no toner', 
    4 => 'door open', 
    5 => 'jammed', 
    6 => 'offline', 
    7 => 'service requested', 
    8 => 'input tray missing', 
    9 => 'output tray missing', 
    10 => 'maker supply missing',
    11 => 'output near full',
    12 => 'output full', 
    13 => 'input tray empty', 
    14 => 'overdue prevent maint', 
);

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_hrPrinterDetectedErrorState = '.1.3.6.1.2.1.25.3.5.1.2';
    my $result = $options{snmp}->get_table(oid => $oid_hrPrinterDetectedErrorState, nothing_quit => 1);

    $self->{printer} = {};
    foreach (keys %$result) {
        /\.(\d+)$/;
        my $instance = $1;
        # 16 bits value
        my $value = unpack('S', $result->{$_});
        if (!defined($value)) {
            $value = ord($result->{$_});
        }

        $self->{printer}->{$instance} = { display => $instance, errors => {} };
        my $i = 0;
        foreach my $key (keys %errors_printer) {        
            if (($value & (1 << $key))) {
                $self->{printer}->{$instance}->{errors}->{$i} = { status => $errors_printer{$key} };
                $i++;
            }
        }
        
        if ($i == 0) {
            $self->{printer}->{$instance}->{errors}->{0} = { status => 'ok' };
            next;
        }
    }
}

1;

__END__

=head1 MODE

Check printer errors (HOST-RESOURCES-MIB).

=over 8

=item B<--ok-status>

Set warning threshold for status (Default: '%{status} =~ /ok/').
Can used special variables like: %{status}

=item B<--unknown-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}

=item B<--warning-status>

Set warning threshold for status (Default: '%{status} =~ /.*/').
Can used special variables like: %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{status}

=back

=cut
