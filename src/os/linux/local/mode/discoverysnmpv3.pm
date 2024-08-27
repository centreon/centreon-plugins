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

package os::linux::local::mode::discoverysnmpv3;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use os::linux::local::mode::resources::discovery qw($discovery_match);
use centreon::plugins::snmp;
use NetAddr::IP;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'subnet:s'          => { name => 'subnet' },
        'authpassphrase:s'  => { name => 'snmp_auth_passphrase' },
        'privpassphrase:s'  => { name => 'snmp_priv_passphrase' },
        'authprotocol:s'    => { name => 'snmp_auth_protocol' },
        'privprotocol:s'    => { name => 'snmp_priv_protocol' },
        'snmp-username:s'   => { name => 'snmp_security_name' },
        'snmp-port:s'       => { name => 'snmp_port', default => 161 },
        'snmp-timeout:s'    => { name => 'snmp_timeout', default => 1 },
        'prettify'          => { name => 'prettify' },
        'extra-oids:s'      => { name => 'extra_oids' }
    });

    $self->{snmp} = centreon::plugins::snmp->new(%options, noptions => 1);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{subnet}) ||
        $self->{option_results}->{subnet} !~ /(\d+)\.(\d+)\.(\d+)\.(\d+)\/(\d+)/) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --subnet option (<ip>/<cidr>).");
        $self->{output}->option_exit();
    }

    delete $self->{snmp}->{snmp_params}->{Community};
    $self->{snmp}->set_snmp_connect_params(SecName => $self->{option_results}->{snmp_security_name}) if (defined($self->{option_results}->{snmp_security_name}));

    if (!defined($self->{option_results}->{snmp_security_name}) || $self->{option_results}->{snmp_security_name} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Missing parameter Security Name.');
        $self->{output}->option_exit();
    }

    # unauthenticated and unencrypted
    $self->{snmp}->set_snmp_connect_params(SecLevel => 'noAuthNoPriv');
    my $user_activate = 0;
    if (defined($self->{option_results}->{snmp_auth_passphrase}) && $self->{option_results}->{snmp_auth_passphrase} ne '') {
        if (!defined($self->{option_results}->{snmp_auth_protocol})) {
            $self->{output}->add_option_msg(short_msg => 'Missing parameter authenticate protocol.');
            $self->{output}->option_exit();
        }
        $self->{option_results}->{snmp_auth_protocol} = uc($self->{option_results}->{snmp_auth_protocol});
        if ($self->{option_results}->{snmp_auth_protocol} !~ /^(?:MD5|SHA|SHA224|SHA256|SHA384|SHA512)$/) {
            $self->{output}->add_option_msg(short_msg => 'Wrong authentication protocol.');
            $self->{output}->option_exit();
        }
        $self->{snmp}->set_snmp_connect_params(SecLevel => 'authNoPriv');
        $self->{snmp}->set_snmp_connect_params(AuthProto => $self->{option_results}->{snmp_auth_protocol});
        $self->{snmp}->set_snmp_connect_params(AuthPass => $self->{option_results}->{snmp_auth_passphrase});
        $user_activate = 1;
    }

    if (defined($self->{option_results}->{snmp_priv_passphrase}) && $self->{option_results}->{snmp_priv_passphrase} ne '') {
        if (!defined($self->{option_results}->{snmp_priv_protocol})) {
            $self->{output}->add_option_msg(short_msg => 'Missing parameter privacy protocol.');
            $self->{output}->option_exit();
        }
        $self->{option_results}->{snmp_priv_protocol} = uc($self->{option_results}->{snmp_priv_protocol});
        if ($self->{option_results}->{snmp_priv_protocol} !~ /^(?:DES|AES|AES192|AES192C|AES256|AES256C)$/) {
            $self->{output}->add_option_msg(short_msg => 'Wrong privacy protocol.');
            $self->{output}->option_exit();
        }
        if ($user_activate == 0) {
            $self->{output}->add_option_msg(short_msg => 'Cannot use snmp v3 privacy option without snmp v3 authentification options.');
            $self->{output}->option_exit();
        }
        $self->{snmp}->set_snmp_connect_params(SecLevel => 'authPriv');
        $self->{snmp}->set_snmp_connect_params(PrivPass => $self->{option_results}->{snmp_priv_passphrase});
        $self->{snmp}->set_snmp_connect_params(PrivProto => $self->{option_results}->{snmp_priv_protocol});
    }

    $self->{snmpv3_combo} = '';
    my $options_mapping = {
        snmp_auth_passphrase    => "--authpassphrase",
        snmp_priv_passphrase    => "--privpassphrase" ,
        snmp_auth_protocol      => "--authprotocol",
        snmp_priv_protocol      => "--privprotocol",
        snmp_security_name      => "--snmp-username"
    };
    foreach my $option (keys %$options_mapping) {
        next if (!defined($self->{option_results}->{$option}) || $self->{option_results}->{$option} eq "");
        $self->{snmpv3_combo} .= " " . $options_mapping->{$option} . "='" .  $self->{option_results}->{$option} . "'";
    }

    $self->{snmp}->set_snmp_connect_params(Timeout => $self->{option_results}->{snmp_timeout} * (10**6));
    $self->{snmp}->set_snmp_connect_params(Retries => 0);
    $self->{snmp}->set_snmp_connect_params(RemotePort => $self->{option_results}->{port});
    $self->{snmp}->set_snmp_connect_params(Version => 3);
    $self->{snmp}->set_snmp_params(subsetleef => 1);
    $self->{snmp}->set_snmp_params(snmp_autoreduce => 0);
    $self->{snmp}->set_snmp_params(snmp_errors_exit => 'unknown');

    $self->{oid_sysDescr} = '.1.3.6.1.2.1.1.1.0';
    $self->{oid_sysName} = '.1.3.6.1.2.1.1.5.0';

    $self->{oids} = [$self->{oid_sysDescr}, $self->{oid_sysName}];
    $self->{extra_oids} = {};
    if (defined($self->{option_results}->{extra_oids})) {
        my @extra_oids = split(/,/, $self->{option_results}->{extra_oids});
        foreach my $extra_oid (@extra_oids) {
            next if ($extra_oid eq '');

            my @values = split(/=/, $extra_oid);
            my ($name, $oid) = ('', $values[0]);
            if (defined($values[1])) {
                $name = $values[0];
                $oid = $values[1];
            }

            $oid =~ s/^(\d+)/\.$1/;
            $self->{extra_oids}->{$oid} = $name;
            push @{$self->{oids}}, $oid;
        }
    }
}

sub define_type {
    my ($self, %options) = @_;

    return 'unknown' unless (defined($options{desc}) && $options{desc} ne '');
    foreach (@$discovery_match) {
        if ($options{desc} =~ /$_->{re}/) {
            return $_->{type};
        }
    }

    return 'unknown';
}

sub snmp_request {
    my ($self, %options) = @_;

    $self->{snmp}->set_snmp_connect_params(DestHost => $options{ip});
    return undef if ($self->{snmp}->connect(dont_quit => 1) != 0);
    return $self->{snmp}->get_leef(
        oids => $self->{oids},
        nothing_quit => 0, dont_quit => 1
    );
}

sub run {
    my ($self, %options) = @_;

    my @disco_data;
    my $disco_stats;

    my $subnet = NetAddr::IP->new($self->{option_results}->{subnet});
    $disco_stats->{start_time} = time();

    foreach my $ip (@{$subnet->splitref($subnet->bits())}) {
        my $snmp_result = $self->snmp_request(ip => $ip->addr);
        next if (!defined($snmp_result));
        next if (!defined($snmp_result->{$self->{oid_sysDescr}}) && !defined($snmp_result->{$self->{oid_sysName}})); 

        my %host;
        $host{type} = $self->define_type(desc => $snmp_result->{$self->{oid_sysDescr}});
        $host{desc} = $snmp_result->{$self->{oid_sysDescr}};
        $host{desc} =~ s/\n/ /g if (defined($host{desc}));
        $host{ip} = $ip->addr;
        $host{hostname} = $snmp_result->{$self->{oid_sysName}};
        $host{snmp_version} = '3';
        $host{snmp_port} = $self->{option_results}->{snmp_port};
        $host{snmpv3_extraopts} = $self->{snmpv3_combo};
        $host{extra_oids} = [];
        foreach (keys %{$self->{extra_oids}}) {
            my $label = defined($self->{extra_oids}->{$_}) && $self->{extra_oids}->{$_} ne '' ? $self->{extra_oids}->{$_} : $_;
            my $value = defined($snmp_result->{$_}) ? $snmp_result->{$_} : 'unknown';
            push @{$host{extra_oids}}, { oid => $label, value => $value };
        }

        push @disco_data, \%host;
    }
    
    $disco_stats->{end_time} = time();
    $disco_stats->{duration} = $disco_stats->{end_time} - $disco_stats->{start_time};
    $disco_stats->{discovered_items} = @disco_data;
    $disco_stats->{results} = \@disco_data;

    my $encoded_data;
    eval {
        if (defined($self->{option_results}->{prettify})) {
            $encoded_data = JSON::XS->new->utf8->pretty->encode($disco_stats);
        } else {
            $encoded_data = JSON::XS->new->utf8->encode($disco_stats);
        }
    };
    if ($@) {
        $encoded_data = '{"code":"encode_error","message":"Cannot encode discovered data into JSON format"}';
    }
    
    $self->{output}->output_add(short_msg => $encoded_data);
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1);
    $self->{output}->exit();
}
    
1;

__END__

=head1 MODE

Resources discovery.

=over 8

=item B<--subnet>

Specify subnet from which discover
resources (must be <ip>/<cidr> format) (mandatory).

Specify SNMP community (can be defined multiple times) (mandatory).

=item B<--snmp-timeout>

Specify SNMP timeout in second (default: 1).

=item B<--prettify>

Prettify JSON output.

=item B<--extra-oids>

Specify extra OIDs to get (example: --extra-oids='hrSystemInitialLoadParameters=1.3.6.1.2.1.25.1.4.0,sysDescr=.1.3.6.1.2.1.1.1.0').

=back

=cut
