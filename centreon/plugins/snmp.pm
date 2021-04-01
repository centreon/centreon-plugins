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

package centreon::plugins::snmp;

use strict;
use warnings;
use SNMP;
use Socket;
use POSIX;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;
    # $options{options} = options object
    # $options{output} = output object
    # $options{exit_value} = integer

    if (!defined($options{output})) {
        print "Class SNMP: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class SNMP: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }

    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'hostname|host:s'    => { name => 'host' },
            'snmp-community:s'   => { name => 'snmp_community', default => 'public' },
            'snmp-version:s'     => { name => 'snmp_version', default => 1 },
            'snmp-port:s'        => { name => 'snmp_port', default => 161 },
            'snmp-timeout:s'     => { name => 'snmp_timeout', default => 1 },
            'snmp-retries:s'     => { name => 'snmp_retries', default => 5 },
            'maxrepetitions:s'   => { name => 'maxrepetitions', default => 50 },
            'subsetleef:s'       => { name => 'subsetleef', default => 50 },
            'subsettable:s'      => { name => 'subsettable', default => 100 },
            'snmp-autoreduce:s'  => { name => 'snmp_autoreduce' },
            'snmp-force-getnext' => { name => 'snmp_force_getnext' },
            'snmp-username:s'    => { name => 'snmp_security_name' },
            'authpassphrase:s'   => { name => 'snmp_auth_passphrase' },
            'authprotocol:s'     => { name => 'snmp_auth_protocol' },
            'privpassphrase:s'   => { name => 'snmp_priv_passphrase' },
            'privprotocol:s'     => { name => 'snmp_priv_protocol' },
            'contextname:s'      => { name => 'snmp_context_name' },
            'contextengineid:s'  => { name => 'snmp_context_engine_id' },
            'securityengineid:s' => { name => 'snmp_security_engine_id' },
            'snmp-errors-exit:s' => { name => 'snmp_errors_exit', default => 'unknown' },
        });
        $options{options}->add_help(package => __PACKAGE__, sections => 'SNMP OPTIONS');
    }

    #####
    $self->{session} = undef;
    $self->{output} = $options{output};
    $self->{snmp_params} = {};

    # Dont load MIB
    $SNMP::auto_init_mib = 0;
    $ENV{MIBS} = '';
    # For snmpv v1 - get request retries when you have "NoSuchName"
    $self->{RetryNoSuch} = 1;
    # Dont try to translate OID (we keep value)
    $self->{UseNumeric} = 1;

    $self->{error_msg} = undef;
    $self->{error_status} = 0;

    return $self;
}

sub connect {
    my ($self, %options) = @_;

    $self->{snmp_params}->{RetryNoSuch} = $self->{RetryNoSuch};
    $self->{snmp_params}->{UseNumeric} = $self->{UseNumeric};

    if (!$self->{output}->is_litteral_status(status => $self->{snmp_errors_exit})) {
        $self->{output}->add_option_msg(short_msg => "Unknown value '" . $self->{snmp_errors_exit}  . "' for --snmp-errors-exit.");
        $self->{output}->option_exit(exit_litteral => 'unknown');
    }

    $self->{session} = new SNMP::Session(%{$self->{snmp_params}});
    if (!defined($self->{session})) {
        $self->{output}->add_option_msg(short_msg => 'SNMP Session : unable to create');
        $self->{output}->option_exit(exit_litteral => $self->{snmp_errors_exit});
    }
    if ($self->{session}->{ErrorNum}) {
        $self->{output}->add_option_msg(short_msg => 'SNMP Session : ' . $self->{session}->{ErrorStr});
        $self->{output}->option_exit(exit_litteral => $self->{snmp_errors_exit});
    }
}

sub load {
    my ($self, %options) = @_;
    # $options{oids} = ref to array of oids (example: ['.1.2', '.1.2'])
    # $options{instances} = ref to array of oids instances
    # $options{begin}, $args->{end} = integer instance end
    # $options{instance_regexp} = str
    # 3 way to use: with instances, with end, none
    
    if (defined($options{end})) {
        for (my $i = $options{begin}; $i <= $options{end}; $i++) {
            foreach (@{$options{oids}}) {
                push @{$self->{oids_loaded}}, $_ . "." . $i;
            }
        }
        return ;
    }
    
    if (defined($options{instances})) {
        $options{instance_regexp} = defined($options{instance_regexp}) ? $options{instance_regexp} : '(\d+)$';
        foreach my $instance (@{$options{instances}}) {
            $instance =~ /$options{instance_regexp}/;
            foreach (@{$options{oids}}) {
                push @{$self->{oids_loaded}}, $_ . "." . $1;
            }
        }
        return ;
    }
    
    push @{$self->{oids_loaded}}, @{$options{oids}};
}

sub autoreduce_table {
    my ($self, %options) = @_;
    
    return 1 if (defined($self->{snmp_force_getnext}) || $self->is_snmpv1());
    if ($self->{snmp_params}->{Retries} > 1) {
        $self->{snmp_params}->{Retries} = 1;
        $self->connect();
    }
    
    return 1 if (${$options{repeat_count}} == 1);
    ${$options{repeat_count}} = int(${$options{repeat_count}} / $self->{snmp_autoreduce_divisor});
    ${$options{repeat_count}} = 1 if (${$options{repeat_count}} < 1);
    return 0;
}

sub autoreduce_multiple_table {
    my ($self, %options) = @_;
    
    if ($self->{snmp_params}->{Retries} > 1) {
        $self->{snmp_params}->{Retries} = 1;
        $self->connect();
    }
    return 1 if (${$options{repeat_count}} == 1);
    
    ${$options{repeat_count}} = int(${$options{repeat_count}} / $self->{snmp_autoreduce_divisor});
    $self->{subsettable} = int($self->{subsettable} / $self->{snmp_autoreduce_divisor});
    ${$options{repeat_count}} = 1 if (${$options{repeat_count}} < 1);
    return 0;
}

sub autoreduce_leef {
    my ($self, %options) = @_;
    
    if ($self->{snmp_params}->{Retries} > 1) {
        $self->{snmp_params}->{Retries} = 1;
        $self->connect();
    }
    
    return 1 if ($self->{subsetleef} == 1);
    $self->{subsetleef} = int($self->{subsetleef} / $self->{snmp_autoreduce_divisor});
    $self->{subsetleef} = 1 if ($self->{subsetleef} < 1);
    
    my $array_ref = [];
    my $subset_current = 0;
    my $subset_construct = [];
    foreach ([@{$options{current}}], @{$self->{array_ref_ar}}) {
        foreach my $entry (@$_) {;
            push @$subset_construct, [$entry->[0], $entry->[1]];
            $subset_current++;
            if ($subset_current == $self->{subsetleef}) {
                push @$array_ref, \@$subset_construct;
                $subset_construct = [];
                $subset_current = 0;
            }
        }
    }
    
    if ($subset_current) {
        push @$array_ref, \@$subset_construct;
    }

    $self->{array_ref_ar} = \@$array_ref;
    return 0;
}

sub get_leef {
    my ($self, %options) = @_;
    # $options{dont_quit} = integer
    # $options{nothing_quit} = integer
    # $options{oids} = ref to array of oids (example: ['.1.2', '.1.2'])

    # Returns array
    #    'undef' value for an OID means NoSuchValue

    my ($dont_quit) = (defined($options{dont_quit}) && $options{dont_quit} == 1) ? 1 : 0;
    my ($nothing_quit) = (defined($options{nothing_quit}) && $options{nothing_quit} == 1) ? 1 : 0;
    $self->set_error();

    if (!defined($options{oids})) {
        if ($#{$self->{oids_loaded}} < 0) {
            if ($dont_quit == 1) {
                $self->set_error(error_status => -1, error_msg => "Need to specify OIDs");
                return undef;
            }
            $self->{output}->add_option_msg(short_msg => 'Need to specify OIDs');
            $self->{output}->option_exit(exit_litteral => $self->{snmp_errors_exit});
        }
        push @{$options{oids}}, @{$self->{oids_loaded}};
        @{$self->{oids_loaded}} = ();
    }

    my $results = {};
    $self->{array_ref_ar} = [];
    my $subset_current = 0;
    my $subset_construct = [];
    foreach my $oid (@{$options{oids}}) {
        # Get last value
        next if ($oid !~ /(.*)\.(\d+)([\.\s]*)$/);
        
        my ($oid, $instance) = ($1, $2);
        $results->{$oid . "." . $instance} = undef;
        push @$subset_construct, [$oid, $instance];
        $subset_current++;
        if ($subset_current == $self->{subsetleef}) {
            push @{$self->{array_ref_ar}}, \@$subset_construct;
            $subset_construct = [];
            $subset_current = 0;
        }
    }
    if ($subset_current) {
        push @{$self->{array_ref_ar}}, \@$subset_construct;
    }

    ############################
    # If wrong oid with SNMP v1, packet resent (2 packets more). Not the case with SNMP > 1.
    # Can have "NoSuchName", if nothing works...
    # = v1: wrong oid
    #   bless( [
    #       '.1.3.6.1.2.1.1.3',
    #       '0',
    #       '199720062',
    #       'TICKS'
    #       ], 'SNMP::Varbind' ),
    #   bless( [
    #       '.1.3.6.1.2.1.1.999',
    #       '0'
    #       ], 'SNMP::Varbind' ),
    #   bless( [
    #       '.1.3.6.1.2.1.1',
    #       '1000'
    #       ], 'SNMP::Varbind' )
    # > v1: wrong oid
    #   bless( [
    #        '.1.3.6.1.2.1.1.3',
    #        '0',
    #        '199728713',
    #        'TICKS'
    #       ], 'SNMP::Varbind' ),
    #   bless( [
    #         '.1.3.6.1.2.1.1',
    #         '3',
    #         'NOSUCHINSTANCE',
    #        'TICKS'
    #    ], 'SNMP::Varbind' )
    #   bless( [
    #        '.1.3.6.1.2.1.1.999',
    #        '0',
    #        'NOSUCHOBJECT',
    #        'NOSUCHOBJECT'
    #       ], 'SNMP::Varbind' ),
    #   bless( [
    #        '.1.3.6.1.2.1.1',
    #        '1000',
    #        'NOSUCHOBJECT',
    #        'NOSUCHOBJECT'
    #       ], 'SNMP::Varbind' )
    ############################

    my $total = 0;
    while (my $entry = shift(@{$self->{array_ref_ar}})) {
        my $vb = new SNMP::VarList(@{$entry});
        $self->{session}->get($vb);

        if ($self->{session}->{ErrorNum}) {
            # 0    noError       Pas d'erreurs.
            # 1    tooBig        Reponse de taille trop grande.
            # 2    noSuchName    Variable inexistante.
            # -24  Timeout
            if ($self->{session}->{ErrorNum} == 2) {
                # We are at the end with snmpv1. We next.
                next;
            }

            if ($self->{snmp_autoreduce} == 1 && 
                ($self->{session}->{ErrorNum} == 1 || $self->{session}->{ErrorNum} == 5 || $self->{session}->{ErrorNum} == -24)) {
                next if ($self->autoreduce_leef(current => $entry) == 0);
            }
            my $msg = 'SNMP GET Request : ' . $self->{session}->{ErrorStr};    
            if ($dont_quit == 0) {
                $self->{output}->add_option_msg(short_msg => $msg);
                $self->{output}->option_exit(exit_litteral => $self->{snmp_errors_exit});
            }

            $self->set_error(error_status => -1, error_msg => $msg);
            return undef;
        }

        # Some equipments gives a partial response and no error.
        # We look the last value if it's empty or not
        # In snmpv1 we have the retryNoSuch
        if (((scalar(@$vb) != scalar(@{$entry})) || (scalar(@{@$vb[-1]}) < 3)) && !$self->is_snmpv1()) {
            next if ($self->{snmp_autoreduce} == 1 && $self->autoreduce_leef(current => $entry) == 0);
            if ($dont_quit == 0) {
                $self->{output}->add_option_msg(short_msg => 'SNMP partial response. Please try --snmp-autoreduce option');
                $self->{output}->option_exit(exit_litteral => $self->{snmp_errors_exit});
            }

            $self->set_error(error_status => -1, error_msg => 'SNMP partial response');
            return undef;
        }

        foreach my $entry (@$vb) {
            if ($#$entry < 3) {
                # Can be snmpv1 not find
                next;
            }
            if (${$entry}[2] eq 'NOSUCHOBJECT' || ${$entry}[2] eq 'NOSUCHINSTANCE') {
                # Error in snmp > 1
                next;
            }

            $total++;
            $results->{${$entry}[0] . "." . ${$entry}[1]} = ${$entry}[2];
        }
    }

    if ($nothing_quit == 1 && $total == 0) {
        $self->{output}->add_option_msg(short_msg => 'SNMP GET Request : Cant get a single value.');
        $self->{output}->option_exit(exit_litteral => $self->{snmp_errors_exit});
    }

    return $results;
}

sub multiple_find_bigger {
    my ($self, %options) = @_;
    
    my $getting = {};
    my @values = ();
    foreach my $key (keys %{$options{working_oids}}) {
        push @values, $options{working_oids}->{$key}->{start};
        $getting->{ $options{working_oids}->{$key}->{start} } = $key;
    }
    @values = $self->oid_lex_sort(@values);
    
    return $getting->{pop(@values)};
}

sub get_multiple_table {
    my ($self, %options) = @_;
    # $options{dont_quit} = integer
    # $options{oids} = refs array
    #     [ { oid => 'x.x.x.x', start => '', end => ''}, { oid => 'y.y.y.y', start => '', end => ''} ]
    # $options{return_type} = integer

    my ($return_type) = (defined($options{return_type}) && $options{return_type} == 1) ? 1 : 0;
    my ($dont_quit) = (defined($options{dont_quit}) && $options{dont_quit} == 1) ? 1 : 0;
    my ($nothing_quit) = (defined($options{nothing_quit}) && $options{nothing_quit} == 1) ? 1 : 0;
    $self->set_error();

    my $working_oids = {};
    my $results = {};
    # Check overlap
    foreach my $entry (@{$options{oids}}) {
        # Transform asking
        if ($entry->{oid} !~ /(.*)\.(\d+)([\.\s]*)$/) {
            if ($dont_quit == 1) {
                $self->set_error(error_status => -1, error_msg => "Method 'get_multiple_table': Wrong OID '" . $entry->{oid} . "'.");
                return undef;
            }
            $self->{output}->add_option_msg(short_msg => "Method 'get_multiple_table': Wrong OID '" . $entry->{oid} . "'.");
            $self->{output}->option_exit(exit_litteral => $self->{snmp_errors_exit});
        }

        if (defined($entry->{start})) {
            $working_oids->{$entry->{oid}} = { start => $entry->{start}, end => $entry->{end} }; # last in it
        } else {
            $working_oids->{$entry->{oid}} = { start => $entry->{oid}, end => $entry->{end} };
        }

        if ($return_type == 0) {
            $results->{$entry->{oid}} = {};
        }
    }

    # we use a medium (UDP have a PDU limit. SNMP protcol cant send multiples for one request)
    # So we need to manage
    # It's for "bulk". We ask 50 next values. If you set 1, it's like a getnext (snmp v1)
    my $repeat_count = 50;
    if (defined($self->{maxrepetitions}) && 
        $self->{maxrepetitions} =~ /^\d+$/) {
        $repeat_count = $self->{maxrepetitions};
    }

    # Quit if base not the same or 'ENDOFMIBVIEW' value. Need all oid finish otherwise we continue :)
    while (1) {
        my $current_oids = 0;
        my @bindings = ();
        my @bases = ();
        foreach my $key (keys %{$working_oids}) {
            $working_oids->{$key}->{start} =~ /(.*)\.(\d+)([\.\s]*)$/;
            push @bindings, [$1, $2];
            push @bases, $key;

            $current_oids++;
            last if ($current_oids > $self->{subsettable});
        }

        # Nothing more to check. We quit
        last if ($current_oids == 0);

        my $vb = new SNMP::VarList(@bindings);

        if ($self->is_snmpv1() || defined($self->{snmp_force_getnext})) {
            $self->{session}->getnext($vb);
        } else {
            my $current_repeat_count = floor($repeat_count / $current_oids);
            $current_repeat_count = 1 if ($current_repeat_count == 0);
            $self->{session}->getbulk(0, $current_repeat_count, $vb);
        }

        # Error
        if ($self->{session}->{ErrorNum}) {
            # 0    noError       Pas d'erreurs.
            # 1    tooBig        Reponse de taille trop grande.
            # 2    noSuchName    Variable inexistante.
            if ($self->{session}->{ErrorNum} == 2) {
                # We are at the end with snmpv1. Need to find the most up oid ;)
                my $oid_base = $self->multiple_find_bigger(working_oids => $working_oids);
                delete $working_oids->{$oid_base};
                next;
            }

            if ($self->{snmp_autoreduce} == 1 && 
                ($self->{session}->{ErrorNum} == 1 || $self->{session}->{ErrorNum} == 5 || $self->{session}->{ErrorNum} == -24)) {
                next if ($self->autoreduce_multiple_table(repeat_count => \$repeat_count) == 0);
            }

            my $msg = 'SNMP Table Request : ' . $self->{session}->{ErrorStr};
            if ($dont_quit == 0) {
                $self->{output}->add_option_msg(short_msg => $msg);
                $self->{output}->option_exit(exit_litteral => $self->{snmp_errors_exit});
            }

            $self->set_error(error_status => -1, error_msg => $msg);
            return undef;
        }

        # Manage
        # step by step: [ 1 => 1, 2 => 1, 3 => 1 ], [ 1 => 2, 2 => 2, 3 => 2 ],...

        my $pos = -1;
        foreach my $entry (@$vb) {
            $pos++;

            # Already destruct. we continue
            next if (!defined($working_oids->{ $bases[$pos % $current_oids] }));

            # ENDOFMIBVIEW is on each iteration. So we need to delete and skip after that
            if (${$entry}[2] eq 'ENDOFMIBVIEW') {
                delete $working_oids->{ $bases[$pos % $current_oids] };
                # END mib
                next;
            }

            # Not in same table
            my $complete_oid = ${$entry}[0] . "." . ${$entry}[1];
            my $base = $bases[$pos % $current_oids];
            if ($complete_oid !~ /^$base\./ ||
                (defined($working_oids->{ $bases[$pos % $current_oids] }->{end}) && 
                 $self->check_oid_up(current => $complete_oid, end => $working_oids->{ $bases[$pos % $current_oids] }->{end}))) {
                delete $working_oids->{ $bases[$pos % $current_oids] };
                next;
            }

            if ($return_type == 0) {
                $results->{$bases[$pos % $current_oids]}->{$complete_oid} = ${$entry}[2];
            } else {
                $results->{$complete_oid} = ${$entry}[2];
            }

            $working_oids->{ $bases[$pos % $current_oids] }->{start} = $complete_oid;
        }

        # infinite loop. Some equipments it returns nothing!!??
        if ($pos == -1) {
            $self->{output}->add_option_msg(short_msg => 'SNMP Table Request: problem to get values (try --snmp-force-getnext option)');
            $self->{output}->option_exit(exit_litteral => $self->{snmp_errors_exit});
        }
    }

    my $total = 0;
    if ($nothing_quit == 1) {
        if ($return_type == 1) {
            $total = scalar(keys %{$results});
        } else {
            foreach (keys %{$results}) {
                $total += scalar(keys %{$results->{$_}});
            }
        }

        if ($total == 0) {
            $self->{output}->add_option_msg(short_msg => 'SNMP Table Request: Cant get a single value.');
            $self->{output}->option_exit(exit_litteral => $self->{snmp_errors_exit});
        }
    }

    return $results;
}

sub get_table {
    my ($self, %options) = @_;
    # $options{dont_quit} = integer
    # $options{oid} = string (example: '.1.2')
    # $options{start} = string (example: '.1.2')
    # $options{end} = string (example: '.1.2')

    my ($dont_quit) = (defined($options{dont_quit}) && $options{dont_quit} == 1) ? 1 : 0;
    my ($nothing_quit) = (defined($options{nothing_quit}) && $options{nothing_quit} == 1) ? 1 : 0;
    $self->set_error();

    if (defined($options{start})) {
        $options{start} = $self->clean_oid($options{start});
    }
    if (defined($options{end})) {
        $options{end} = $self->clean_oid($options{end});
    }

    # we use a medium (UDP have a PDU limit. SNMP protcol cant send multiples for one request)
    # So we need to manage
    # It's for "bulk". We ask 50 next values. If you set 1, it's like a getnext (snmp v1)
    my $repeat_count = 50;
    if (defined($self->{maxrepetitions}) && 
        $self->{maxrepetitions} =~ /^\d+$/) {
        $repeat_count = $self->{maxrepetitions};
    }

    # Transform asking
    if ($options{oid} !~ /(.*)\.(\d+)([\.\s]*)$/) {
        if ($dont_quit == 1) {
            $self->set_error(error_status => -1, error_msg => "Method 'get_table': Wrong OID '" . $options{oid} . "'.");
            return undef;
        }
        $self->{output}->add_option_msg(short_msg => "Method 'get_table': Wrong OID '" . $options{oid} . "'.");
        $self->{output}->option_exit(exit_litteral => $self->{snmp_errors_exit});
    }

    my $main_indice = $1 . "." . $2;
    my $results = {};

    # Quit if base not the same or 'ENDOFMIBVIEW' value
    my $leave = 1;
    my $last_oid;

    if (defined($options{start})) {
        $last_oid = $options{start};
    } else {
        $last_oid = $options{oid};
    }
    while ($leave) {
        $last_oid =~ /(.*)\.(\d+)([\.\s]*)$/;
        my $vb = new SNMP::VarList([$1, $2]);

        if ($self->is_snmpv1() || defined($self->{snmp_force_getnext})) {
            $self->{session}->getnext($vb);
        } else {
            $self->{session}->getbulk(0, $repeat_count, $vb);
        }

        # Error
        if ($self->{session}->{ErrorNum}) {
            # 0    noError       Pas d'erreurs.
            # 1    tooBig        Reponse de taille trop grande.
            # 2    noSuchName    Variable inexistante.
            # -24  Timeout
            if ($self->{session}->{ErrorNum} == 2) {
                # We are at the end with snmpv1. We quit.
                last;
            }
            if ($self->{snmp_autoreduce} == 1 && 
                ($self->{session}->{ErrorNum} == 1 || $self->{session}->{ErrorNum} == 5 || $self->{session}->{ErrorNum} == -24)) {
                next if ($self->autoreduce_table(repeat_count => \$repeat_count) == 0);
            }

            my $msg = 'SNMP Table Request : ' . $self->{session}->{ErrorStr};

            if ($dont_quit == 0) {
                $self->{output}->add_option_msg(short_msg => $msg);
                $self->{output}->option_exit(exit_litteral => $self->{snmp_errors_exit});
            }

            $self->set_error(error_status => -1, error_msg => $msg);
            return undef;
        }

        # Manage
        foreach my $entry (@$vb) {
            if (${$entry}[2] eq 'ENDOFMIBVIEW') {
                # END mib
                $leave = 0;
                last;
            }

            # Not in same table
            my $complete_oid = ${$entry}[0] . "." . ${$entry}[1];
            if ($complete_oid !~ /^$main_indice\./ ||
                (defined($options{end}) && $self->check_oid_up(current => $complete_oid, end => $options{end}))) {
                $leave = 0;
                last;
            }

            $results->{$complete_oid} = ${$entry}[2];
            $last_oid = $complete_oid;
        }
    }

    if ($nothing_quit == 1 && scalar(keys %$results) == 0) {
        $self->{output}->add_option_msg(short_msg => 'SNMP Table Request: Cant get a single value.');
        $self->{output}->option_exit(exit_litteral => $self->{snmp_errors_exit});
    }

    return $results;
}

sub set {
    my ($self, %options) = @_;
    # $options{dont_quit} = integer
    # $options{oids} = ref to hash table
    my ($dont_quit) = (defined($options{dont_quit}) && $options{dont_quit} == 1) ? 1 : 0;
    $self->set_error();

    my $vars = [];
    foreach my $oid (keys %{$options{oids}}) {
        # Get last value
        next if ($oid !~ /(.*)\.(\d+)([\.\s]*)$/);

        my $value = $options{oids}->{$oid}->{value};
        my $type = $options{oids}->{$oid}->{type};
        my ($oid, $instance) = ($1, $2);

        push @$vars, [$oid, $instance, $value, $type];
    }

    $self->{session}->set($vars);
    if ($self->{session}->{ErrorNum}) {
        # 0    noError       Pas d'erreurs.
        # 1    tooBig        Reponse de taille trop grande.
        # 2    noSuchName    Variable inexistante.

        my $msg = 'SNMP SET Request : ' . $self->{session}->{ErrorStr};
        if ($dont_quit == 0) {
            $self->{output}->add_option_msg(short_msg => $msg);
            $self->{output}->option_exit(exit_litteral => $self->{snmp_errors_exit});
        }

        $self->set_error(error_status => -1, error_msg => $msg);
        return undef;
    }

    return 0;
}

sub is_snmpv1 {
    my ($self) = @_;

    if ($self->{snmp_params}->{Version} eq '1') {
        return 1;
    }
    return 0;
}

sub clean_oid {
    my ($self, $oid) = @_;

    $oid =~ s/\.$//;
    $oid =~ s/^(\d)/\.$1/;
    return $oid;
}

sub check_oid_up {
    my ($self, %options) = @_;

    my $current_oid = $options{current};
    my $end_oid = $options{end};

    my @current_oid_splitted = split /\./, $current_oid;
    my @end_oid_splitted = split /\./, $end_oid;
    # Skip first value (before first '.' empty)
    for (my $i = 1; $i <= $#current_oid_splitted && $i <= $#end_oid_splitted; $i++) {
        if (int($current_oid_splitted[$i]) > int($end_oid_splitted[$i])) {
            return 1;
        }
    }

    return 0;
}

sub check_options {
    my ($self, %options) = @_;
    # $options{option_results} = ref to options result

    if (!defined($options{option_results}->{host})) {
        $self->{output}->add_option_msg(short_msg => 'Missing parameter --hostname.');
        $self->{output}->option_exit();
    }

    $options{option_results}->{snmp_version} =~ s/^v//;
    if ($options{option_results}->{snmp_version} !~ /1|2c|2|3/) {
        $self->{output}->add_option_msg(short_msg => 'Unknown snmp version.');
        $self->{output}->option_exit();
    }

    $self->{snmp_force_getnext} = $options{option_results}->{snmp_force_getnext};
    $self->{maxrepetitions} = $options{option_results}->{maxrepetitions};
    $self->{subsetleef} = (defined($options{option_results}->{subsetleef}) && $options{option_results}->{subsetleef} =~ /^[0-9]+$/) ? $options{option_results}->{subsetleef} : 50;
    $self->{subsettable} = (defined($options{option_results}->{subsettable}) && $options{option_results}->{subsettable} =~ /^[0-9]+$/) ? $options{option_results}->{subsettable} : 100;
    $self->{snmp_errors_exit} = $options{option_results}->{snmp_errors_exit};
    $self->{snmp_autoreduce} = 0;
    $self->{snmp_autoreduce_divisor} = 2;
    if (defined($options{option_results}->{snmp_autoreduce})) {
        $self->{snmp_autoreduce} = 1;
        $self->{snmp_autoreduce_divisor} = $1 if ($options{option_results}->{snmp_autoreduce} =~ /(\d+(\.\d+)?)/ && $1 > 1);
    }

    %{$self->{snmp_params}} = (
        DestHost => $options{option_results}->{host},
        Community => $options{option_results}->{snmp_community},
        Version => $options{option_results}->{snmp_version},
        RemotePort => $options{option_results}->{snmp_port},
        Retries => 5
    );

    if (defined($options{option_results}->{snmp_timeout}) && $options{option_results}->{snmp_timeout} =~ /^[0-9]+$/) {
        $self->{snmp_params}->{Timeout} = $options{option_results}->{snmp_timeout} * (10**6);
    }

    if (defined($options{option_results}->{snmp_retries}) && $options{option_results}->{snmp_retries} =~ /^[0-9]+$/) {
        $self->{snmp_params}->{Retries} = $options{option_results}->{snmp_retries};
    }

    if ($options{option_results}->{snmp_version} eq '3') {
        delete $self->{snmp_params}->{Community};

        $self->{snmp_params}->{Context} = $options{option_results}->{snmp_context_name} if (defined($options{option_results}->{snmp_context_name}));
        $self->{snmp_params}->{ContextEngineId} = $options{option_results}->{snmp_context_engine_id} if (defined($options{option_results}->{snmp_context_engine_id}));
        $self->{snmp_params}->{SecEngineId} = $options{option_results}->{snmp_security_engine_id} if (defined($options{option_results}->{snmp_security_engine_id}));
        $self->{snmp_params}->{SecName} = $options{option_results}->{snmp_security_name} if (defined($options{option_results}->{snmp_security_name}));

        # Certificate SNMPv3. Need net-snmp > 5.6
        if ($options{option_results}->{host} =~ /^(dtls|tls|ssh).*:/) {
            $self->{snmp_params}->{OurIdentity} = $options{option_results}->{snmp_our_identity} if (defined($options{option_results}->{snmp_our_identity}));
            $self->{snmp_params}->{TheirIdentity} = $options{option_results}->{snmp_their_identity} if (defined($options{option_results}->{snmp_their_identity}));
            $self->{snmp_params}->{TheirHostname} = $options{option_results}->{snmp_their_hostname} if (defined($options{option_results}->{snmp_their_hostname}));
            $self->{snmp_params}->{TrustCert} = $options{option_results}->{snmp_trust_cert} if (defined($options{option_results}->{snmp_trust_cert}));
            $self->{snmp_params}->{SecLevel} = 'authPriv';
            return ;
        }

        if (!defined($options{option_results}->{snmp_security_name}) || $options{option_results}->{snmp_security_name} eq '') {
            $self->{output}->add_option_msg(short_msg => 'Missing parameter Security Name.');
            $self->{output}->option_exit();
        }

        # unauthenticated and unencrypted
        $self->{snmp_params}->{SecLevel} = 'noAuthNoPriv';

        my $user_activate = 0;
        if (defined($options{option_results}->{snmp_auth_passphrase}) && $options{option_results}->{snmp_auth_passphrase} ne '') {
            if (!defined($options{option_results}->{snmp_auth_protocol})) {
                $self->{output}->add_option_msg(short_msg => 'Missing parameter authenticate protocol.');
                $self->{output}->option_exit();
            }
            $options{option_results}->{snmp_auth_protocol} = uc($options{option_results}->{snmp_auth_protocol});
            if ($options{option_results}->{snmp_auth_protocol} ne 'MD5' && $options{option_results}->{snmp_auth_protocol} ne 'SHA') {
                $self->{output}->add_option_msg(short_msg => 'Wrong authentication protocol. Must be MD5 or SHA.');
                $self->{output}->option_exit();
            }

            $self->{snmp_params}->{SecLevel} = 'authNoPriv';
            $self->{snmp_params}->{AuthProto} = $options{option_results}->{snmp_auth_protocol};
            $self->{snmp_params}->{AuthPass} = $options{option_results}->{snmp_auth_passphrase};
            $user_activate = 1;
        }

        if (defined($options{option_results}->{snmp_priv_passphrase}) && $options{option_results}->{snmp_priv_passphrase} ne '') {
            if (!defined($options{option_results}->{snmp_priv_protocol})) {
                $self->{output}->add_option_msg(short_msg => 'Missing parameter privacy protocol.');
                $self->{output}->option_exit();
            }

            $options{option_results}->{snmp_priv_protocol} = uc($options{option_results}->{snmp_priv_protocol});
            if ($options{option_results}->{snmp_priv_protocol} ne 'DES' && $options{option_results}->{snmp_priv_protocol} ne 'AES') {
                $self->{output}->add_option_msg(short_msg => 'Wrong privacy protocol. Must be DES or AES.');
                $self->{output}->option_exit();
            }
            if ($user_activate == 0) {
                $self->{output}->add_option_msg(short_msg => 'Cannot use snmp v3 privacy option without snmp v3 authentification options.');
                $self->{output}->option_exit();
            }
            $self->{snmp_params}->{SecLevel} = 'authPriv';
            $self->{snmp_params}->{PrivPass} = $options{option_results}->{snmp_priv_passphrase};
            $self->{snmp_params}->{PrivProto} = $options{option_results}->{snmp_priv_protocol};
        }
    }
}

sub set_snmp_connect_params {
    my ($self, %options) = @_;

    foreach (keys %options) {
        $self->{snmp_params}->{$_} = $options{$_};
    }
}

sub set_snmp_params {
    my ($self, %options) = @_;

    foreach (keys %options) {
        $self->{$_} = $options{$_};
    }
}

sub set_error {
    my ($self, %options) = @_;
    # $options{error_msg} = string error
    # $options{error_status} = integer status

    $self->{error_status} = defined($options{error_status}) ? $options{error_status} : 0;
    $self->{error_msg} = defined($options{error_msg}) ? $options{error_msg} : undef;
}

sub error_status {
    my ($self) = @_;

    return $self->{error_status};
}

sub error {
    my ($self) = @_;

    return $self->{error_msg};
}

sub get_hostname {
    my ($self) = @_;

    my $host = $self->{snmp_params}->{DestHost};
    $host =~ s/.*://;
    return $host;
}

sub get_port {
    my ($self) = @_;

    return $self->{snmp_params}->{RemotePort};
}

sub map_instance {
    my ($self, %options) = @_;

    my $results = {};
    my $instance = '';
    $instance = '.' . $options{instance} if (defined($options{instance}));
    foreach my $name (keys %{$options{mapping}}) {
        my $entry = $options{mapping}->{$name}->{oid} . $instance;
        if (defined($options{results}->{$entry})) {
            $results->{$name} = $options{results}->{$entry};
        } elsif (defined($options{results}->{$options{mapping}->{$name}->{oid}}->{$entry})) {
            $results->{$name} = $options{results}->{$options{mapping}->{$name}->{oid}}->{$entry};
        } else {
            $results->{$name} = defined($options{default}) ? $options{default} : undef;
        }

        if (defined($options{mapping}->{$name}->{map})) {
            if (defined($results->{$name})) {
                $results->{$name} = defined($options{mapping}->{$name}->{map}->{$results->{$name}}) ? $options{mapping}->{$name}->{map}->{$results->{$name}} : (defined($options{default}) ? $options{default} : 'unknown');
            }
        }
    }

    return $results;
}

sub oid_lex_sort {
    my $self = shift;

    if (@_ <= 1) {
        return @_;
    }

    return map { $_->[0] }
        sort { $a->[1] cmp $b->[1] }
        map {
           my $oid = $_;
           $oid =~ s/^\.//;
           $oid =~ s/ /\.0/g;
           [$_, pack 'N*', split m/\./, $oid]
        } @_;
}

1;

__END__

=head1 NAME

SNMP global

=head1 SYNOPSIS

snmp class

=head1 SNMP OPTIONS

=over 8

=item B<--hostname>

Hostname to query (required).

=item B<--snmp-community>

Read community (defaults to public).

=item B<--snmp-version>

Version: 1 for SNMP v1 (default), 2 for SNMP v2c, 3 for SNMP v3.

=item B<--snmp-port>

Port (default: 161).

=item B<--snmp-timeout>

Timeout in secondes (default: 1) before retries.

=item B<--snmp-retries>

Set the number of retries (default: 5) before failure.

=item B<--maxrepetitions>

Max repetitions value (default: 50) (only for SNMP v2 and v3).

=item B<--subsetleef>

How many oid values per SNMP request (default: 50) (for get_leef method. Be cautious whe you set it. Prefer to let the default value).

=item B<--snmp-autoreduce>
 
Auto reduce SNMP request size in case of SNMP errors (By default, the divisor is 2).

=item B<--snmp-force-getnext>

Use snmp getnext function (even in snmp v2c and v3).

=item B<--snmp-username>

Security name (only for SNMP v3).

=item B<--authpassphrase>

Authentication protocol pass phrase.

=item B<--authprotocol>

Authentication protocol (MD5|SHA)

=item B<--privpassphrase>

Privacy protocol pass phrase

=item B<--privprotocol>

Privacy protocol (DES|AES)

=item B<--contextname>

Context name

=item B<--contextengineid>

Context engine ID

=item B<--securityengineid>

Security engine ID

=item B<--snmp-errors-exit>

Exit code for SNMP Errors (default: unknown)

=back

=head1 DESCRIPTION

B<snmp>.

=cut
