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

package storage::netapp::ontap::snmp::mode::partnerstatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %mapping_partner_status = (
    1 => 'maybeDown',
    2 => 'ok',
    3 => 'dead',
);
my %mapping_interconnect_status = (
    1 => 'notPresent',
    2 => 'down',
    3 => 'partialFailure',
    4 => 'up',
);
my $thresholds = {
    partner => [
        ['maybeDown', 'WARNING'],
        ['ok', 'OK'],
        ['dead', 'CRITICAL'],
    ],
    interconnect => [
        ['notPresent', 'CRITICAL'],
        ['down', 'CRITICAL'],
        ['partialFailure', 'WARNING'],
        ['up', 'OK'],
    ],
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'threshold-overload:s@' => { name => 'threshold_overload' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ($1, $2, $3);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status};
    }
}

my $mapping = {
    cfPartnerStatus => { oid => '.1.3.6.1.4.1.789.1.2.3.4', map => \%mapping_partner_status },  
};
my $mapping2 = {
    cfInterconnectStatus => { oid => '.1.3.6.1.4.1.789.1.2.3.8', map => \%mapping_interconnect_status },  
};
my $mapping3 = {
    haPartnerStatus => { oid => '.1.3.6.1.4.1.789.1.21.2.1.6', map => \%mapping_partner_status },  
};
my $mapping4 = {
    haInterconnectStatus => { oid => '.1.3.6.1.4.1.789.1.21.2.1.10', map => \%mapping_interconnect_status },  
};

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $oid_cfPartnerName = '.1.3.6.1.4.1.789.1.2.3.6';
    my $oid_haNodeName = '.1.3.6.1.4.1.789.1.21.2.1.1';
    my $results = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_cfPartnerName },
                                                            { oid => $mapping->{cfPartnerStatus}->{oid} },
                                                            { oid => $mapping2->{cfInterconnectStatus}->{oid} },
                                                            { oid => $oid_haNodeName },
                                                            { oid => $mapping3->{haPartnerStatus}->{oid} },
                                                            { oid => $mapping4->{haInterconnectStatus}->{oid} },
                                                            ], nothing_quit => 1);
    
    if (defined($results->{$mapping->{cfPartnerStatus}->{oid}}->{$mapping->{cfPartnerStatus}->{oid} . '.0'})) {
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $results->{$mapping->{cfPartnerStatus}->{oid}}, instance => '0');
        my $exit = $self->get_severity(section => 'partner', value => $result->{cfPartnerStatus});
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Partner '%s' status is '%s'", $results->{$oid_cfPartnerName}->{$oid_cfPartnerName . '.0'}, $result->{cfPartnerStatus}));
        $result = $self->{snmp}->map_instance(mapping => $mapping2, results => $results->{$mapping2->{cfInterconnectStatus}->{oid}}, instance => '0');
        $exit = $self->get_severity(section => 'interconnect', value => $result->{cfInterconnectStatus});
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Interconnect status is '%s'", $result->{cfInterconnectStatus}));
    } else {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'HA status are ok on all nodes');
        foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$results->{$mapping3->{haPartnerStatus}->{oid}}})) {
            $oid =~ /^$mapping3->{haPartnerStatus}->{oid}\.(.*)$/;
            my $instance = $1;
            my $name = $results->{$oid_haNodeName}->{$oid_haNodeName . '.' . $instance};
            my $result = $self->{snmp}->map_instance(mapping => $mapping3, results => $results->{$mapping3->{haPartnerStatus}->{oid}}, instance => $instance);
            
            my $exit = $self->get_severity(section => 'partner', value => $result->{haPartnerStatus});
            $self->{output}->output_add(long_msg => sprintf("Partner status of node '%s' is '%s'", 
                                                            $name, $result->{haPartnerStatus}));
            if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Partner status of node '%s' is '%s'", 
                                                            $name, $result->{haPartnerStatus}));
            }
            
            $result = $self->{snmp}->map_instance(mapping => $mapping4, results => $results->{$mapping4->{haInterconnectStatus}->{oid}}, instance => $instance);
            $exit = $self->get_severity(section => 'interconnect', value => $result->{haInterconnectStatus});
            $self->{output}->output_add(long_msg => sprintf("Interconnect status on node '%s' is '%s'", 
                                                            $name, $result->{haInterconnectStatus}));
            if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Interconnect status on node '%s' is '%s'", 
                                                            $name, $result->{haInterconnectStatus}));
            }
        }
    }

    $self->{output}->display();
    $self->{output}->exit();
}

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'UNKNOWN'; # default 
    
    if (defined($self->{overload_th}->{$options{section}})) {
        foreach (@{$self->{overload_th}->{$options{section}}}) {            
            if ($options{value} =~ /$_->{filter}/i) {
                $status = $_->{status};
                return $status;
            }
        }
    }
    foreach (@{$thresholds->{$options{section}}}) {           
        if ($options{value} =~ /$$_[0]/i) {
            $status = $$_[1];
            return $status;
        }
    }
    
    return $status;
}


1;

__END__

=head1 MODE

Check status of clustered failover partner.

=over 8

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='partner,CRITICAL,^(?!(ok)$)'

=back

=cut
    
