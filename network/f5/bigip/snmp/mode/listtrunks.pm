#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package network::f5::bigip::snmp::mode::listtrunks;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "name:s"                => { name => 'name' },
                                  "regexp"                => { name => 'use_regexp' },
                                });
    $self->{trunks_selected} = [];

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my %map_trunk_status = (
    0 => 'up',
    1 => 'down',
    2 => 'disable',
    3 => 'uninitialized',
    4 => 'loopback',
    5 => 'unpopulated',
);

my $sysTrunkTable = '.1.3.6.1.4.1.3375.2.1.2.12.1.2';
my $sysTrunkName = '.1.3.6.1.4.1.3375.2.1.2.12.1.2.1.1';
my $sysTrunkStatus = '.1.3.6.1.4.1.3375.2.1.2.12.1.2.1.2';
my $sysTrunkOperBw = '.1.3.6.1.4.1.3375.2.1.2.12.1.2.1.5';

my $sysTrunkCfgMember      = '.1.3.6.1.4.1.3375.2.1.2.12.3';
my $sysTrunkCfgMemberTable = '.1.3.6.1.4.1.3375.2.1.2.12.3.2';
my $sysTrunkCfgMemberName  = '.1.3.6.1.4.1.3375.2.1.2.12.3.2.1.2';

my $ifDescr = '.1.3.6.1.2.1.2.2.1.2';
my $ifOperStatus = '.1.3.6.1.2.1.2.2.1.8';

my $ifOperStatusMap = {
  1 => 'up',
  2 => 'down',
  3 => 'testing',
  4 => 'unknown',
  5 => 'dormant',
  6 => 'notPresent',
  7 => 'lowerLayerDown',
};

sub manage_selection {
    my ($self, %options) = @_;

    # Get interfaces descriptions
    my $result_interface = $self->{snmp}->get_table(oid => $ifDescr, nothing_quit => 1);

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$result_interface})) {
        next if ($oid !~ /^$ifDescr\.(.*)$/);
        my $instance = $1;
        $self->{ifDescr}->{$result_interface->{$oid}} = $instance;
    }

    # Get interfaces operating statuses
    my $result_interface_status = $self->{snmp}->get_table(oid => $ifOperStatus, nothing_quit => 1);

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$result_interface_status})) {
        next if ($oid !~ /^$ifOperStatus\.(.*)$/);
        my $instance = $1;
        $self->{ifOperStatus}->{$instance} = $result_interface_status->{$oid};
    }

    $self->{result} = $self->{snmp}->get_table(oid => $sysTrunkTable, nothing_quit => 1);

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{result}})) {
        next if ($oid !~ /^$sysTrunkName\.(.*)$/);
        my $instance = $1;

        # Get all without a name
        if (!defined($self->{option_results}->{name})) {
            push @{$self->{trunks_selected}}, $instance; 
            next;
        }
        
        if (!defined($self->{option_results}->{use_regexp}) && $self->{result}->{$sysTrunkName . '.' . $instance} eq $self->{option_results}->{name}) {
            push @{$self->{trunks_selected}}, $instance;
            next;
        }
        if (defined($self->{option_results}->{use_regexp}) && $self->{result}->{$sysTrunkName . '.' . $instance} =~ /$self->{option_results}->{name}/) {
            push @{$self->{trunks_selected}}, $instance;
            next;
        }
        
        $self->{output}->output_add(long_msg => "Skipping pool '" . $self->{result}->{$sysTrunkName . '.' . $instance} . "': no matching filter name", debug => 1);
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    foreach my $instance (sort @{$self->{trunks_selected}}) { 
        my $sysTrunkCfgMemberNameInstance = $sysTrunkCfgMemberName . '.' .  $instance;
        my $member_result = $self->{snmp}->get_table(oid => $sysTrunkCfgMemberNameInstance, nothing_quit => 1);

        foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$member_result})) {
            next if ($oid !~ /^$sysTrunkCfgMemberName\.(.*)$/);

            my $trunk_member_status = 'interface not found';
            if($self->{ifDescr}->{$member_result->{$oid}}) {
                if($self->{ifOperStatus}->{$self->{ifDescr}->{$member_result->{$oid}}}) {
                    $trunk_member_status = $ifOperStatusMap->{$self->{ifOperStatus}->{$self->{ifDescr}->{$member_result->{$oid}}}};
                }
                else {
                    $trunk_member_status = 'interface status not found';
                    $self->{output}->output_add(severity => 'WARNING', short_msg => "member " . $member_result->{$oid} . ': ' . $trunk_member_status);
                }
            }
            else {
                $self->{output}->output_add(severity => 'WARNING', short_msg => "member " . $member_result->{$oid} . ': ' . $trunk_member_status);
            }

            $self->{result}->{$sysTrunkCfgMemberName . '.' . $instance} .= " " . $member_result->{$oid} . "(" . $trunk_member_status . ")";
        }

        $self->{output}->output_add(long_msg => sprintf("'%s' [status: %s] [speed: %s] [members:%s]",
                                                $self->{result}->{$sysTrunkName . '.' . $instance},
                                                $map_trunk_status{$self->{result}->{$sysTrunkStatus . '.' . $instance}},
                                                $self->{result}->{$sysTrunkOperBw . '.' . $instance},
                                                $self->{result}->{$sysTrunkCfgMemberName . '.' . $instance}
                                                ));
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List Trunks:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'status', 'speed']);
}

sub disco_show {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    $self->manage_selection(disco => 1);
    foreach my $instance (sort @{$self->{trunks_selected}}) {        
        my $name = $self->{result}->{$sysTrunkName . '.' . $instance};
        my $status = $map_trunk_status{$self->{result}->{$sysTrunkStatus . '.' . $instance}};
        my $speed = $self->{result}->{$sysTrunkOperBw . '.' . $instance};
        
        $self->{output}->add_disco_entry(name => $name, status => $status, speed => $speed);
    }
}

1;

__END__

=head1 MODE

List Trunks.

=over 8

=item B<--name>

Set the trunk name.

=item B<--regexp>

Allows to use regexp to filter trunk name (with option --name).

=back

=cut
    
