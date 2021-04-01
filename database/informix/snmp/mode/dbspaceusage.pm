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

package database::informix::snmp::mode::dbspaceusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 1, cb_prefix_output => 'prefix_dbspace_output', message_multiple => 'All dbspaces usage are ok' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'usage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'display' } ],
                output_template => 'Used: %.2f%%',
                perfdatas => [
                    { label => 'used', value => 'prct_used', template => '%.2f', min => 0, max => 100, unit => '%',
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_dbspace_output {
    my ($self, %options) = @_;
    
    return "Dbspace '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-name:s"       => { name => 'filter_name' },
    });
    
    return $self;
}

my $mapping = {
    onDbspaceName           => { oid => '.1.3.6.1.4.1.893.1.1.1.6.1.2' },
    onDbspacePagesAllocated => { oid => '.1.3.6.1.4.1.893.1.1.1.6.1.11' },
    onDbspacePagesUsed      => { oid => '.1.3.6.1.4.1.893.1.1.1.6.1.12' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_applName = '.1.3.6.1.2.1.27.1.1.2';
    my $snmp_result = $options{snmp}->get_multiple_table(oids => [
            { oid => $oid_applName },
            { oid => $mapping->{onDbspaceName}->{oid} },
            { oid => $mapping->{onDbspacePagesAllocated}->{oid} },
            { oid => $mapping->{onDbspacePagesUsed}->{oid} },
        ], return_type => 1, nothing_quit => 1
    );

    $self->{global} = {};
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{onDbspaceName}->{oid}\.(.*)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        my $name = 'default';
        $name = $snmp_result->{$oid_applName}->{$oid_applName . '.' . $instance} 
            if (defined($snmp_result->{$oid_applName}->{$oid_applName . '.' . $instance}));
        $name .= '.' . $result->{onDbspaceName};
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $name . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{global}->{$name} = { 
            display => $name, 
            prct_used => $result->{onDbspacePagesUsed} * 100 / $result->{onDbspacePagesAllocated},
        };
    }
    
    if (scalar(keys %{$self->{global}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No dbspace found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check dbspaces usage.

=over 8

=item B<--filter-name>

Filter dbspace name (can be a regexp).

=item B<--warning-usage>

Threshold warning in percent.

=item B<--critical-usage>

Threshold critical in percent.

=back

=cut
