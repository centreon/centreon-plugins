#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package snmp_standard::mode::listprocessesstats;

use base qw(centreon::plugins::mode);
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);
use Data::Dumper;

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    $self->{statefile_cache}->check_options(%options);
}

my $map_type = {
    1 => 'unknown', 2 => 'operatingSystem', 3 => 'deviceDriver', 4 => 'application',
};
my $map_status = {
    1 => 'running', 2 => 'runnable',  3 => 'notRunnable', 4 => 'invalid',
};

my $mapping = {
    name       => { oid => '.1.3.6.1.2.1.25.4.2.1.2' }, # hrSWRunName
    path       => { oid => '.1.3.6.1.2.1.25.4.2.1.4' }, # hrSWRunPath
    parameters => { oid => '.1.3.6.1.2.1.25.4.2.1.5' }, # hrSWRunParameters
    type       => { oid => '.1.3.6.1.2.1.25.4.2.1.6', map => $map_type }, # hrSWRunType
    status     => { oid => '.1.3.6.1.2.1.25.4.2.1.7', map => $map_status }, # hrSWRunStatus
    cpu        => { oid => '.1.3.6.1.2.1.25.5.1.1.1' }, # hrSWRunPerfCPU
    mem        => { oid => '.1.3.6.1.2.1.25.5.1.1.2' }, # hrSWRunPerfMem
};


my $order = ['name', 'path', 'parameters', 'type', 'pid', 'status', 'cpu', 'mem'];

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_hrSWRunEntry = '.1.3.6.1.2.1.25.4.2.1';
    
   
    my $snmp_process_result = $options{snmp}->get_table(
        oid => $oid_hrSWRunEntry,
        start => $mapping->{name}->{oid},
        end => $mapping->{status}->{oid},
        nothing_quit => 1
    );
    

    $options{snmp}->load(oids => [$mapping->{cpu}->{oid}], instances => [keys %{$snmp_process_result}]);
    $options{snmp}->load(oids => [$mapping->{cpu}->{oid},$mapping->{mem}->{oid}], instances => [keys %{$snmp_process_result}]);
    my $snmp_stats_result = $options{snmp}->get_leef(); 
    my $results = {};
    my $data = {};
    $data->{last_timestamp} = time();
    $self->{statefile_cache}->read(
				      statefile => "snmpstandard_" . $options{snmp}->get_hostname() . '_' . 
                                      $options{snmp}->get_port() . '_' . $self->{mode});
    my $old_timestamp = $self->{statefile_cache}->get(name => 'last_timestamp');

    foreach my $oid (keys %$snmp_process_result) {
        next if ($oid !~ /^$mapping->{name}->{oid}\.(.*?)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_process_result, instance => $instance);
	
        $results->{$instance} = { %$result, pid => $instance, mem => $snmp_stats_result->{$mapping->{mem}->{oid} . '.' . $instance } * 1024};
        
        $data->{'cpu_' . $instance} = $snmp_stats_result->{$mapping->{cpu}->{oid} . '.' . $instance};
        my $old_cpu = $self->{statefile_cache}->get(name => 'cpu_' . $instance);

        if (!defined($old_cpu) || !defined($old_timestamp)) {
            $results->{$instance}->{cpu} = 'Buffer creation...';
            next;
        }
        # Go back to zero
        if ($old_cpu > $data->{'cpu_' . $instance}) {
            $old_cpu = 0;
        }
        my $time_delta = ($data->{last_timestamp} - $old_timestamp);
        # At least one seconds.
        if ($time_delta == 0) {
            $time_delta = 1;
        }
        $results->{$instance}->{cpu} = sprintf("%.2f %%", ($data->{'cpu_' . $instance} - $old_cpu) / $time_delta);
    }
    $self->{statefile_cache}->write(data => $data);
    return $results;
}

sub run {
    my ($self, %options) = @_;
 
    my $results = $self->manage_selection(%options);
    foreach (values %$results) {
        my $entry = '';
        foreach my $label (@$order) {
            $entry .= '[' . $label . ' = ' . $_->{$label} . '] ';
        }
        $self->{output}->output_add(long_msg => $entry);
    }
    
    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List processes:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 0, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => $order);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(%options);
    foreach (values %$results) {
        $self->{output}->add_disco_entry(%$_);
    }
}

1;

__END__

=head1 MODE

List processes.

=over 8

#=item B<--filter-name>

#Filter by service name (can be a regexp).

=back

=cut
    
