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

package hardware::pdu::emerson::snmp::mode::globalstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    my $msg = "status is '" . $self->{result_values}->{status} . "'";

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'pdu', type => 1, cb_prefix_output => 'prefix_pdu_output', message_multiple => 'All PDU status are ok' }
    ];
    
    $self->{maps_counters}->{pdu} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
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
    
    $options{options}->add_options(arguments => { 
        'filter-name:s'     => { name => 'filter_name' },
        'warning-status:s'  => { name => 'warning_status', default => '%{status} =~ /normalWithWarning/i' },
        'critical-status:s' => { name => 'critical_status', default => '%{status} =~ /normalWithAlarm|abnormalOperation/i' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub prefix_pdu_output {
    my ($self, %options) = @_;
    
    return "PDU '" . $options{instance_value}->{display} . "' ";
}

my %bitmap_status = (
    1 => 'normalOperation',
    2 => 'startUp',
    8 => 'normalWithWarning',
    16 => 'normalWithAlarm',
    32 => 'abnormalOperation',
);
my $mapping = {
    lgpPduEntryUsrLabel        => { oid => '.1.3.6.1.4.1.476.1.42.3.8.20.1.10' },
    lgpPduEntrySysStatus       => { oid => '.1.3.6.1.4.1.476.1.42.3.8.20.1.25' },
};
my $oid_lgpPduEntry = '.1.3.6.1.4.1.476.1.42.3.8.20.1';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{pdu} = {};
    $self->{results} = $options{snmp}->get_table(
        oid => $oid_lgpPduEntry,
        start => $mapping->{lgpPduEntryUsrLabel}->{oid},
        end => $mapping->{lgpPduEntrySysStatus}->{oid},
        nothing_quit => 1
    );

    foreach my $oid (keys %{$self->{results}}) {
        next if ($oid !~ /^$mapping->{lgpPduEntrySysStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $self->{results}, instance => $instance);
        my $name = defined($result->{lgpPduEntryUsrLabel}) && $result->{lgpPduEntryUsrLabel} ne '' ? 
            $result->{lgpPduEntryUsrLabel} : $instance;
        my $status = 'unknown';
        foreach (keys %bitmap_status) {
            if ((int($result->{lgpPduEntrySysStatus}) & $_)) {
                $status = $bitmap_status{$_};
                last;
            }
        }
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{pdu}->{$instance} = { display => $name, 
                                      status => $status };
    }
    
    if (scalar(keys %{$self->{pdu}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Cannot found pdu.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check global status.

=over 8

=item B<--filter-name>

Filter PDU name (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '%{status} =~ /normalWithWarning/i').
Can used special variables like: %{status}, %{display}.

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /normalWithAlarm|abnormalOperation/i').
Can used special variables like: %{status}, %{display}

=back

=cut
