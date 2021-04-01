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

package os::linux::local::mode::discoverynmap;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::snmp;
use JSON::XS;
use XML::Simple;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'subnet:s'              => { name => 'subnet' },
        'prettify'              => { name => 'prettify' }
    });
                                    
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
}

my $lookup_type = [
    { type => 'cisco standard', re => qr/Cisco IOS Software/i },
    { type => 'emc data domain', re => qr/Data Domain/i },
    { type => 'sonicwall', re => qr/SonicWALL/i },
    { type => 'silverpeak', re => qr/Silver Peak/i },
    { type => 'stonesoft', re => qr/Forcepoint/i },
    { type => 'redback', re => qr/Redback/i },
    { type => 'palo alto', re => qr/Palo Alto/i },
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

sub decode_xml_response {
    my ($self, %options) = @_;

    my $content;
    eval {
        $content = XMLin($options{response}, ForceArray => $options{ForceArray}, KeyAttr => []);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode xml response: $@");
        $self->{output}->option_exit();
    }
    
    return $content;
}

sub run {
    my ($self, %options) = @_;

    my @disco_data;
    my $disco_stats;
    
    $disco_stats->{start_time} = time();

    my ($stdout) = $options{custom}->execute_command(
        command => 'nmap',
        command_options => '-sS -sU -R -O --osscan-limit --osscan-guess -p U:161,162,T:21-25,80,139,443,3306,8080,8443 -oX - ',
        command_options_suffix => $self->{option_results}->{subnet},
        timeout => 120
    );

    my $results = $self->decode_xml_response(
        response => $stdout,
        ForceArray => ['host', 'port', 'address', 'hostname', 'osmatch']
    );

    foreach my $entry (@{$results->{host}}) {
        my %host;
        $host{status} = $entry->{status}->{state};
        $host{os} = $entry->{os}->{osmatch}[0]->{name};
        $host{os_accuracy} = $entry->{os}->{osmatch}[0]->{accuracy};
        $host{type} = $self->define_type(desc => $host{os});
        $host{ip} = undef;
        $host{addresses} = undef;
        $host{hostname} = undef;
        $host{hostnames} = undef;
        $host{vendor} = undef;
        $host{services} = undef;

        foreach my $hostname (@{$entry->{hostnames}->{hostname}}) {
            push @{$host{hostnames}}, { name => $hostname->{name}, type => $hostname->{type} };
            $host{hostname} = $hostname->{name} if (!defined($host{hostname}));
        }
        foreach my $address (@{$entry->{address}}) {
            push @{$host{addresses}}, { address => $address->{addr}, type => $address->{addrtype} };
            $host{ip} = $address->{addr} if (!defined($host{ip}) && $address->{addrtype} =~ /^ipv/);
            $host{vendor} = $address->{vendor} if (!defined($host{vendor}) && defined($address->{vendor}));
        }
        foreach my $port (@{$entry->{ports}->{port}}) {
            next if ($port->{state}->{state} !~ /open/);
            push @{$host{services}}, {
                port => $port->{portid} . '/' . $port->{protocol},
                name => $port->{service}->{name}
            };
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
Command used: nmap -sS -sU -R -O --osscan-limit --osscan-guess -p U:161,162,T:21-25,80,139,443,3306,8080,8443 -oX - __SUBNET_OPTION__

Timeout defaults to 120 seconds.

=over 8

=item B<--subnet>

Specify subnet from which discover
resources (Must be <ip>/<cidr> format) (Mandatory).

=item B<--prettify>

Prettify JSON output.

=back

=cut
