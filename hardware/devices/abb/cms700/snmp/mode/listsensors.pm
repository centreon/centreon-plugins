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

package hardware::devices::abb::cms700::snmp::mode::listsensors;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my $oid_GroupName = '.1.3.6.1.4.1.51055.1.20';
my $oid_BranchNamesens = '.1.3.6.1.4.1.51055.1.19';
my $mapping = {
    Phasesens => { oid => '.1.3.6.1.4.1.51055.1.21' },
    Groupsens => { oid => '.1.3.6.1.4.1.51055.1.22' },
};

sub manage_selection {
    my ($self, %options) = @_;
    
    my %groups;
    my $snmp_result = $options{snmp}->get_table(oid => $oid_GroupName);
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$oid_GroupName\.(.*)/);
        next if ($snmp_result->{$oid} eq '');
        $groups{$1} = $snmp_result->{$oid};
    }

    my %sensors;
    $snmp_result = $options{snmp}->get_table(oid => $oid_BranchNamesens);
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$oid_BranchNamesens\.(.*)/);
        next if ($snmp_result->{$oid} eq '');
        my $instance = $1;

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $snmp_result->{$oid} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping sensor '" . $snmp_result->{$oid} . "'.", debug => 1);
            next;
        }

        $sensors{$instance} = $snmp_result->{$oid};
    }

    $options{snmp}->load(
        oids => [
            $mapping->{Phasesens}->{oid},
            $mapping->{Groupsens}->{oid},
        ],
        instances => [ keys %sensors ],
        instance_regexp => '^(.*)$'
    );
    my $snmp_result_data = $options{snmp}->get_leef(nothing_quit => 1);
    
    foreach my $oid (keys %$snmp_result_data) {
        next if ($oid !~ /^$mapping->{Phasesens}->{oid}\.(.*)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(
            mapping => $mapping,
            results => $snmp_result_data,
            instance => $instance
        );

        $self->{sensors}->{$instance}->{name} = $sensors{$instance};
        $self->{sensors}->{$instance}->{phase} = ($result->{Phasesens} != 0) ? $result->{Phasesens} : '-';
        $self->{sensors}->{$instance}->{group} =
            (defined($groups{$result->{Groupsens}})) ? $groups{$result->{Groupsens}} : '-';
    }
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{sensors}}) {
        $self->{output}->output_add(
            long_msg => sprintf("[name = %s] [group = %s] [phase = %s]",
                $self->{sensors}->{$instance}->{name},
                $self->{sensors}->{$instance}->{group},
                $self->{sensors}->{$instance}->{phase})
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List sensors:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['name', 'group', 'phase']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{sensors}}) {
        $self->{output}->add_disco_entry(
            name => $self->{sensors}->{$instance}->{name},
            group => $self->{sensors}->{$instance}->{group},
            phase => $self->{sensors}->{$instance}->{phase},
        );
    }
}

1;

__END__

=head1 MODE

List sensors.

=over 8

=back

=cut
