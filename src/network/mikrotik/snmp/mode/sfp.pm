#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package network::mikrotik::snmp::mode::sfp;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/is_excluded/;
use centreon::plugins::statefile;
use centreon::plugins::lockfile;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::SHA qw(sha256_hex);

my $map_boolean = { 0 => 'false', 1 => 'true' };

# MIKROTIK-MIB::mtxrOpticalTable, indexed by ifIndex. Only the ports with a module plugged in are listed.
my $oid_mtxrOpticalName = '.1.3.6.1.4.1.14988.1.1.19.1.1.2';
my $mapping = {
    rx_loss     => { oid => '.1.3.6.1.4.1.14988.1.1.19.1.1.3', map => $map_boolean }, # mtxrOpticalRxLoss
    tx_fault    => { oid => '.1.3.6.1.4.1.14988.1.1.19.1.1.4', map => $map_boolean }, # mtxrOpticalTxFault
    wavelength  => { oid => '.1.3.6.1.4.1.14988.1.1.19.1.1.5' },  # mtxrOpticalWavelength (nm * 100)
    temperature => { oid => '.1.3.6.1.4.1.14988.1.1.19.1.1.6' },  # mtxrOpticalTemperature (C)
    voltage     => { oid => '.1.3.6.1.4.1.14988.1.1.19.1.1.7' },  # mtxrOpticalSupplyVoltage (mV)
    bias        => { oid => '.1.3.6.1.4.1.14988.1.1.19.1.1.8' },  # mtxrOpticalTxBiasCurrent (mA)
    tx_power    => { oid => '.1.3.6.1.4.1.14988.1.1.19.1.1.9' },  # mtxrOpticalTxPower (dBm * 1000)
    rx_power    => { oid => '.1.3.6.1.4.1.14988.1.1.19.1.1.10' }, # mtxrOpticalRxPower (dBm * 1000)
    vendor      => { oid => '.1.3.6.1.4.1.14988.1.1.19.1.1.11' }, # mtxrOpticalVendorName
    serial      => { oid => '.1.3.6.1.4.1.14988.1.1.19.1.1.12' }  # mtxrOpticalVendorSerial
};

sub prefix_sfp_output {
    my ($self, %options) = @_;

    return sprintf(
        "SFP '%s' [vendor: %s, serial: %s, wavelength: %s] ",
        $options{instance},
        $options{instance_value}->{vendor},
        $options{instance_value}->{serial},
        defined($options{instance_value}->{wavelength}) ? sprintf('%.2f nm', $options{instance_value}->{wavelength}) : '-'
    );
}

sub build_sfp_counter {
    my ($self, %options) = @_;

    return {
        label      => $options{label},
        nlabel     => $options{nlabel},
        display_ok => $options{display_ok} // 1,
        set        => {
            key_values      => [ { name => $options{name} } ],
            output_template => $options{output_template},
            perfdatas       => [
                { template => $options{template}, unit => $options{unit}, label_extra_instance => 1 }
            ]
        }
    };
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'sfp', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_sfp_output',
          message_multiple => 'All SFP modules are ok', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{sfp} = [
        {
            label            => 'status',
            type             => COUNTER_KIND_TEXT,
            critical_default => '%{rx_loss} eq "true" || %{tx_fault} eq "true"',
            set              => {
                key_values                     => [
                    { name => 'name' }, { name => 'rx_loss' }, { name => 'tx_fault' },
                    { name => 'vendor' }, { name => 'serial' }
                ],
                output_template                => 'rx loss: %{rx_loss}, tx fault: %{tx_fault}',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        $self->build_sfp_counter(
            label => 'temperature', nlabel => 'port.temperature.celsius', name => 'temperature',
            output_template => 'temperature: %s C', template => '%s', unit => 'C'
        ),
        $self->build_sfp_counter(
            label => 'volt', nlabel => 'port.voltage.volt', name => 'voltage',
            output_template => 'voltage: %.2f V', template => '%.2f', unit => 'V'
        ),
        $self->build_sfp_counter(
            label => 'bias-current', nlabel => 'port.bias.current.milliampere', name => 'bias',
            output_template => 'bias current: %.2f mA', template => '%.2f', unit => 'mA'
        ),
        $self->build_sfp_counter(
            label => 'tx-output-power-dbm', nlabel => 'port.output.power.dbm', name => 'tx_power_dbm',
            output_template => 'output power: %.2f dBm', template => '%.2f', unit => 'dBm'
        ),
        $self->build_sfp_counter(
            label => 'tx-output-power', display_ok => 0, nlabel => 'port.output.power.milliwatt', name => 'tx_power',
            output_template => 'output power: %.4f mW', template => '%.4f', unit => 'mW'
        ),
        $self->build_sfp_counter(
            label => 'rx-input-power-dbm', nlabel => 'port.input.power.dbm', name => 'rx_power_dbm',
            output_template => 'input power: %.2f dBm', template => '%.2f', unit => 'dBm'
        ),
        $self->build_sfp_counter(
            label => 'rx-input-power', display_ok => 0, nlabel => 'port.input.power.milliwatt', name => 'rx_power',
            output_template => 'input power: %.4f mW', template => '%.4f', unit => 'mW'
        )
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'include-name:s'      => { name => 'include_name' },
        'exclude-name:s'      => { name => 'exclude_name' },
        'include-serial:s'    => { name => 'include_serial' },
        'exclude-serial:s'    => { name => 'exclude_serial' },
        'reload-cache-time:s' => { name => 'reload_cache_time', default => 180, numeric => 1 },
        'show-cache'          => { name => 'show_cache' },
        'no-cache-lock'       => { name => 'no_cache_lock' }
    });

    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    $self->{lockfile_cache} = centreon::plugins::lockfile->new(%options);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{statefile_cache}->check_options(%options);
    $self->{lockfile_cache}->check_options(%options);
}

# Walk the module names: the cache gives the indexes of the plugged modules and their interface name
sub reload_cache {
    my ($self, %options) = @_;

    my $datas = { last_timestamp => time(), sfp => {} };
    my $result = $options{snmp}->get_table(oid => $oid_mtxrOpticalName);
    foreach my $oid (keys %$result) {
        next if ($oid !~ /^$oid_mtxrOpticalName\.(\d+)$/);
        $datas->{sfp}->{$1} = { name => $self->{output}->decode($result->{$oid}) };
    }

    $self->{output}->option_exit(short_msg => "Can't construct cache: no SFP module found.")
        unless (keys %{$datas->{sfp}});

    $self->{statefile_cache}->write(data => $datas) unless ($options{do_not_write});

    return $datas;
}

sub get_selection {
    my ($self, %options) = @_;

    my $cache_name = 'cache_mikrotik_snmp_' . sha256_hex(join('_',
        $options{snmp}->get_hostname(), $options{snmp}->get_port(), $self->{mode}
    ));

    # the lock file has the name of the cache file with the .lck extension
    my $have_lock = $self->{option_results}->{no_cache_lock}
        || $self->{lockfile_cache}->try_lock(lockfile => $cache_name . '.lck');

    my $has_cache_file = $self->{statefile_cache}->read(statefile => $cache_name);
    if (defined($self->{option_results}->{show_cache})) {
        # option_exit() does not display long_msg: add it first
        $self->{output}->add_option_msg(long_msg => $self->{statefile_cache}->get_string_content());
        $self->{output}->option_exit(short_msg => 'Cache content:');
    }

    my $timestamp_cache = $self->{statefile_cache}->get(name => 'last_timestamp');
    if ($has_cache_file == 0 || !defined($timestamp_cache) || !defined($self->{statefile_cache}->get(name => 'sfp'))
        || ($have_lock && (time() - $timestamp_cache) >= ($self->{option_results}->{reload_cache_time} * 60))) {
        # the cache is reloaded when it is missing, or expired and we hold the lock.
        # It is only rewritten when we hold the lock.
        my $datas = $self->reload_cache(snmp => $options{snmp}, do_not_write => !$have_lock);
        $self->{statefile_cache}->read_from(datas => $datas);
    }
    $self->{lockfile_cache}->unlock();

    my $sfp = $self->{statefile_cache}->get(name => 'sfp');
    my $selection = {};
    foreach my $index (sort { $a <=> $b } keys %$sfp) {
        next if (is_excluded($sfp->{$index}->{name}, $self->{option_results}->{include_name},
            $self->{option_results}->{exclude_name}, output => $self->{output}));
        $selection->{$index} = $sfp->{$index}->{name};
    }

    $self->{output}->option_exit(short_msg => 'No SFP module found (check the filters or reload the cache).')
        unless (keys %$selection);

    return $selection;
}

sub dbm_to_milliwatt {
    my ($self, %options) = @_;

    return undef unless (defined($options{dbm}));
    return 10 ** ($options{dbm} / 10);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $selection = $self->get_selection(snmp => $options{snmp});

    $options{snmp}->load(
        oids      => [ map($_->{oid}, values(%$mapping)) ],
        instances => [ keys %$selection ]
    );
    my $snmp_result = $options{snmp}->get_leef();

    $self->{sfp} = {};
    foreach my $index (sort { $a <=> $b } keys %$selection) {
        my $name = $selection->{$index};
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $index);

        # the module was removed since the cache was built
        if (!defined($result->{rx_loss})) {
            $self->{output}->output_add(long_msg => "skipping SFP '$name': no data (module removed?)", debug => 1);
            next;
        }

        my $serial = $self->{output}->decode($result->{serial} // '');
        next if (is_excluded($serial, $self->{option_results}->{include_serial},
            $self->{option_results}->{exclude_serial}, output => $self->{output}));

        my $tx_power_dbm = defined($result->{tx_power}) ? $result->{tx_power} / 1000 : undef;
        my $rx_power_dbm = defined($result->{rx_power}) ? $result->{rx_power} / 1000 : undef;
        $self->{sfp}->{$name} = {
            name         => $name,
            vendor       => $self->{output}->decode($result->{vendor} // ''),
            serial       => $serial,
            rx_loss      => $result->{rx_loss},
            tx_fault     => $result->{tx_fault},
            wavelength   => defined($result->{wavelength}) ? $result->{wavelength} / 100 : undef,
            temperature  => $result->{temperature},
            voltage      => defined($result->{voltage}) ? $result->{voltage} / 1000 : undef,
            bias         => $result->{bias},
            tx_power_dbm => $tx_power_dbm,
            tx_power     => $self->dbm_to_milliwatt(dbm => $tx_power_dbm),
            rx_power_dbm => $rx_power_dbm,
            rx_power     => $self->dbm_to_milliwatt(dbm => $rx_power_dbm)
        };
    }

    $self->{output}->option_exit(short_msg => 'No SFP module found (check the filters or reload the cache).')
        unless (keys %{$self->{sfp}});
}

1;

__END__

=head1 MODE

Check the SFP modules of Mikrotik equipment (C<MIKROTIK-MIB::mtxrOpticalTable>): status, temperature,
supply voltage, bias current, transmit and receive power.

Only the ports with a module plugged in are listed by the equipment. The list of the modules (index and interface name)
is stored in a cache file, reloaded every B<--reload-cache-time> minutes: a module plugged in a free port is
only checked after the next reload. The vendor and the serial number are read at each check.

=over 8

=item B<--include-name>

Only check the modules whose interface name matches this regular expression (example: C<sfp-sfpplus1>).

=item B<--exclude-name>

Exclude the modules whose interface name matches this regular expression.

=item B<--include-serial>

Only check the modules whose serial number matches this regular expression.

=item B<--exclude-serial>

Exclude the modules whose serial number matches this regular expression.

=item B<--reload-cache-time>

Time in minutes before reloading the cache file (default: C<180>). Set C<0> to reload it at each check.

=item B<--show-cache>

Display the content of the cache file.

=item B<--no-cache-lock>

Disable the lock file used to prevent several checks from rewriting the cache file at the same time.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{name}>, C<%{rx_loss}>, C<%{tx_fault}>, C<%{vendor}>, C<%{serial}>.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: C<%{rx_loss} eq "true" || %{tx_fault} eq "true">).
You can use the following variables: C<%{name}>, C<%{rx_loss}>, C<%{tx_fault}>, C<%{vendor}>, C<%{serial}>.

=item B<--warning-temperature>

Threshold for the module temperature (in C).

=item B<--critical-temperature>

Threshold for the module temperature (in C).

=item B<--warning-volt>

Threshold for the module supply voltage (in V).

=item B<--critical-volt>

Threshold for the module supply voltage (in V).

=item B<--warning-bias-current>

Threshold for the transmit bias current (in mA).

=item B<--critical-bias-current>

Threshold for the transmit bias current (in mA).

=item B<--warning-tx-output-power-dbm>

Threshold for the transmit power (in dBm). The values are negative: use for instance C<-9:> to alert below -9 dBm.

=item B<--critical-tx-output-power-dbm>

Threshold for the transmit power (in dBm).

=item B<--warning-tx-output-power>

Threshold for the transmit power (in mW).

=item B<--critical-tx-output-power>

Threshold for the transmit power (in mW).

=item B<--warning-rx-input-power-dbm>

Threshold for the receive power (in dBm). The values are negative: use for instance C<-20:> to alert below -20 dBm.

=item B<--critical-rx-input-power-dbm>

Threshold for the receive power (in dBm).

=item B<--warning-rx-input-power>

Threshold for the receive power (in mW).

=item B<--critical-rx-input-power>

Threshold for the receive power (in mW).

=back

=cut
