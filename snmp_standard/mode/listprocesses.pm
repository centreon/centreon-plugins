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

package snmp_standard::mode::listprocesses;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' },
        'add-stats'     => { name => 'add_stats' },
    });

    $self->{order} = ['name', 'path', 'parameters', 'type', 'pid', 'status'];
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    if (defined($self->{option_results}->{add_stats})) {
        push @{$self->{order}}, 'cpu', 'mem';
    }
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
};
my $mapping2 = {
    cpu  => { oid => '.1.3.6.1.2.1.25.5.1.1.1' }, # hrSWRunPerfCPU
    mem  => { oid => '.1.3.6.1.2.1.25.5.1.1.2' }, # hrSWRunPerfMem
};

sub manage_stats {
    my ($self, %options) = @_;

    $options{snmp}->load(oids => [
            map($_->{oid}, values(%$mapping2))
        ],
        instances => [keys %{$options{results}}],
        instance_regexp => '^(.*)$'
    );
    my $snmp_result = $options{snmp}->get_leef();
    foreach (keys %{$options{results}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result, instance => $_);

        $options{results}->{$_} = { %{$options{results}->{$_}}, %$result };
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_hrSWRunEntry = '.1.3.6.1.2.1.25.4.2.1';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_hrSWRunEntry,
        start => $mapping->{name}->{oid},
        end => $mapping->{status}->{oid},
        nothing_quit => 1
    );
    my $results = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{name}->{oid}\.(.*?)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{name} . "': no matching filter.", debug => 1);
            next;
        }

        $results->{$instance} = { %$result, pid => $instance };
    }

    $self->manage_stats(results => $results, %options) if ($self->{option_results}->{add_stats});
    return $results;
}

sub run {
    my ($self, %options) = @_;
  
    my $results = $self->manage_selection(%options);
    foreach (values %$results) {
        my $entry = '';
        foreach my $label (@{$self->{order}}) {
            $entry .= '[' . $label . ' = ' . $_->{$label} . '] ';
        }
        $self->{output}->output_add(long_msg => $entry);
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List processes:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => $self->{order});
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

=item B<--filter-name>

Filter by service name (can be a regexp).

=item B<--add-stats>

Add cpu and memory stats.

=back

=cut
