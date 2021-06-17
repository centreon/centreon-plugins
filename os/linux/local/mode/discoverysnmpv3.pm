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

package os::linux::local::mode::discoverysnmpv3;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
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
        'prettify'          => { name => 'prettify' }
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
        if ($self->{option_results}->{snmp_auth_protocol} ne 'MD5' && $self->{option_results}->{snmp_auth_protocol} ne 'SHA') {
            $self->{output}->add_option_msg(short_msg => 'Wrong authentication protocol. Must be MD5 or SHA.');
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
        if ($self->{option_results}->{snmp_priv_protocol} ne 'DES' && $self->{option_results}->{snmp_priv_protocol} ne 'AES') {
            $self->{output}->add_option_msg(short_msg => 'Wrong privacy protocol. Must be DES or AES.');
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

    $self->{snmp}->set_snmp_connect_params(Timeout => $self->{option_results}->{snmp_timeout} * (10**6));
    $self->{snmp}->set_snmp_connect_params(Retries => 0);
    $self->{snmp}->set_snmp_connect_params(RemotePort => $self->{option_results}->{port});
    $self->{snmp}->set_snmp_connect_params(Version => 3);
    $self->{snmp}->set_snmp_params(subsetleef => 1);
    $self->{snmp}->set_snmp_params(snmp_autoreduce => 0);
    $self->{snmp}->set_snmp_params(snmp_errors_exit => 'unknown');

}

my $lookup_type = [
    { type => 'cisco standard', re => qr/Cisco IOS Software/i },
    { type => 'emc data domain', re => qr/Data Domain/i },
    { type => 'sonicwall', re => qr/SonicWALL/i },
    { type => 'silverpeak', re => qr/Silver Peak/i },
    { type => 'stonesoft', re => qr/Forcepoint/i },
    { type => 'redback', re => qr/Redback/i },
    { type => 'palo alto', re => qr/Palo Alto/i },
    { type => 'hp procurve', re => qr/HP.*Switch/i },
    { type => 'hp procurve', re => qr/HP ProCurve/i },
    { type => 'hp standard', re => qr/HPE Comware/i },
    { type => 'hp msl', re => qr/HP MSL/i },
    { type => 'mrv optiswitch', re => qr/OptiSwitch/i },
    { type => 'netapp', re => qr/Netapp/i },
    { type => 'linux', re => qr/linux/i },
    { type => 'windows', re => qr/windows/i },
    { type => 'macos', re => qr/Darwin/i },
    { type => 'hp-ux', re => qr/HP-UX/i },
    { type => 'freebsd', re => qr/FreeBSD/i },
    { type => 'aix', re => qr/ AIX / },
];

sub define_type {
    my ($self, %options) = @_;

    return "unknown" unless (defined($options{desc}) && $options{desc} ne '');
    foreach (@$lookup_type) {
        if ($options{desc} =~ /$_->{re}/) {
            return $_->{type};
        }
    }

    return "unknown";
}

sub snmp_request {
    my ($self, %options) = @_;

    $self->{snmp}->set_snmp_connect_params(DestHost => $options{ip});
    $self->{snmp}->connect();
    return $self->{snmp}->get_leef(oids => [ $self->{oid_sysDescr}, $self->{oid_sysName} ],
        nothing_quit => 0, dont_quit => 1);
}

sub run {
    my ($self, %options) = @_;

    $self->{oid_sysDescr} = ".1.3.6.1.2.1.1.1.0";
    $self->{oid_sysName} = ".1.3.6.1.2.1.1.5.0";

    my @disco_data;
    my $disco_stats;
    my $snmpv3_combo;
    
    my $subnet = NetAddr::IP->new($self->{option_results}->{subnet});

    $disco_stats->{start_time} = time();

    my $options_mapping = {
        snmp_auth_passphrase    => "--authpassphrase",
        snmp_priv_passphrase    => "--privpassphrase" ,
        snmp_auth_protocol      => "--authprotocol",
        snmp_priv_protocol      => "--privprotocol",
        snmp_security_name      => "--snmp-username",
    };

    foreach my $option (keys $options_mapping) {
        next if (!defined($self->{option_results}->{$option}) || $self->{option_results}->{$option} eq "");
        $snmpv3_combo .= " " . $options_mapping->{$option} . "='" .  $self->{option_results}->{$option} . "'";
    }

    foreach my $ip (@{$subnet->splitref($subnet->bits())}) {
        my $snmp_result;
        $self->{snmp}->set_snmp_connect_params(DestHost => $ip->addr);
        my $snmp_connect = $self->{snmp}->connect(disco_ignore_failure => 1);

        next if ($snmp_connect == 1);

        $snmp_result = $self->{snmp}->get_leef(oids => [ $self->{oid_sysDescr}, $self->{oid_sysName} ],
            nothing_quit => 0, dont_quit => 1);

	next if (!defined($snmp_result->{$self->{oid_sysDescr}}) && !defined($snmp_result->{$self->{oid_sysName}})); 

        my %host;
        $host{type} = $self->define_type(desc => $snmp_result->{$self->{oid_sysDescr}});
        $host{desc} = $snmp_result->{$self->{oid_sysDescr}};
        $host{desc} =~ s/\n/ /g if (defined($host{desc}));
        $host{ip} = $ip->addr;
        $host{hostname} = $snmp_result->{$self->{oid_sysName}};
        $host{snmp_version} = "3";
        $host{snmp_port} = $self->{option_results}->{snmp_port};
	$host{snmpv3_extraopts} = $snmpv3_combo;
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
resources (Must be <ip>/<cidr> format) (Mandatory).


Specify SNMP community (Can be multiple) (Mandatory).

=item B<--snmp-timeout>

Specify SNMP timeout in second (Default: 1).

=item B<--prettify>

Prettify JSON output.

=back

=cut
