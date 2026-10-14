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

package apps::vmware::vsphere8::custom::vim25;

# Performance counters source based on the vim25 SOAP API (PerformanceManager).
#
# The vStats API used by apps::vmware::vsphere8::custom::api has been removed in
# vSphere 9.1, while PerformanceManager is still served by /sdk on that version.
# This package speaks vim25 directly over centreon::plugins::http: it does NOT
# depend on the unmaintained VMware Perl SDK, nor on the centreon_vmware daemon.
#
# Only what is needed to read a single counter value is implemented:
#   RetrieveServiceContent -> Login -> QueryPerfCounter -> QueryPerf -> Logout

use strict;
use warnings;
use XML::LibXML;
use centreon::plugins::http;
use centreon::plugins::statefile;
use Digest::SHA qw(sha256_hex);
use centreon::plugins::misc qw/is_empty/;

my $VIM_NS = 'urn:vim25';

# Managed object types, keyed by the prefix found in a resource id (host-35, vm-42).
my %entity_types = (
    'HOST' => 'HostSystem',
    'VM'   => 'VirtualMachine'
);

# Rollup types accepted for a counter, by order of preference. vStats exposes a
# single value per counter, PerformanceManager exposes one per rollup.
my @rollup_preference = qw(average latest none summation maximum minimum);

# vStats counter ids are first looked up as-is in the PerformanceManager catalogue
# ('cpu.capacity.usage' -> 'cpu.capacity.usage.<rollup>'). When the vCenter does not
# advertise that name, these historical equivalents are tried instead. A substitution
# is always reported in the long output so that it can be reviewed.
# The unit is never assumed: it is read from the catalogue and converted.
my %counter_aliases = (
    'cpu.capacity.usage'       => [ 'cpu.usagemhz' ],
    'cpu.capacity.provisioned' => [ 'cpu.totalCapacity' ],
    'cpu.capacity.entitlement' => [ 'cpu.totalCapacity' ],
    'cpu.capacity.demand'      => [ 'cpu.demand' ],
    'cpu.capacity.contention'  => [ 'cpu.readiness' ],
    'mem.capacity.usable'      => [ 'mem.totalCapacity' ],
    'mem.capacity.usage'       => [ 'mem.consumed' ],
    'mem.capacity.entitlement' => [ 'mem.granted' ],
    'mem.consumed.vms'         => [ 'mem.consumed' ],
    'mem.swap.current'         => [ 'mem.swapused' ],
    'mem.swap.target'          => [ 'mem.swaptarget' ],
    'mem.swap.readrate'        => [ 'mem.swapinRate' ],
    'mem.swap.writerate'       => [ 'mem.swapoutRate' ],
    'disk.throughput.usage'    => [ 'disk.usage' ],
    'disk.throughput.contention' => [ 'disk.maxTotalLatency' ],
    'net.throughput.usage'     => [ 'net.usage' ],
    'power.capacity.usage'     => [ 'power.power' ]
);

# Unit conversion. Every unit is expressed as a factor towards the base unit of
# its dimension, so a conversion is only allowed inside one dimension.
# Beware: the vim25 'percent' unit is expressed in hundredths of a percent.
my %units = (
    # vim25 unit keys (unitInfo.key), used as conversion sources
    'hertz'                 => [ 'frequency', 1 ],
    'kiloHertz'             => [ 'frequency', 1e3 ],
    'megaHertz'             => [ 'frequency', 1e6 ],
    'byte'                  => [ 'bytes',     1 ],
    'kiloBytes'             => [ 'bytes',     1024 ],
    'megaBytes'             => [ 'bytes',     1024 ** 2 ],
    'gigaBytes'             => [ 'bytes',     1024 ** 3 ],
    'teraBytes'             => [ 'bytes',     1024 ** 4 ],
    'bytesPerSecond'        => [ 'rate',      1 ],
    'kiloBytesPerSecond'    => [ 'rate',      1024 ],
    'megaBytesPerSecond'    => [ 'rate',      1024 ** 2 ],
    'percent'               => [ 'percent',   0.01 ],
    'number'                => [ 'number',    1 ],
    'watt'                  => [ 'power',     1 ],
    'joule'                 => [ 'energy',    1 ],
    'nanosecond'            => [ 'time',      1e-9 ],
    'microsecond'           => [ 'time',      1e-6 ],
    'millisecond'           => [ 'time',      1e-3 ],
    'second'                => [ 'time',      1 ],
    # canonical target units, used to express what the modes expect
    'Hz'                    => [ 'frequency', 1 ],
    'kHz'                   => [ 'frequency', 1e3 ],
    'MHz'                   => [ 'frequency', 1e6 ],
    'B'                     => [ 'bytes',     1 ],
    'KB'                    => [ 'bytes',     1024 ],
    'MB'                    => [ 'bytes',     1024 ** 2 ],
    'Bps'                   => [ 'rate',      1 ],
    'KBps'                  => [ 'rate',      1024 ],
    'pct'                   => [ 'percent',   1 ],
    'count'                 => [ 'number',    1 ],
    'W'                     => [ 'power',     1 ],
    'ms'                    => [ 'time',      1e-3 ]
);

# Unit each vStats counter id is expressed in, derived from the arithmetic the
# modes apply to the returned value (for instance esx/mode/memory.pm multiplies
# mem.capacity.usable.HOST by 1024*1024 to obtain bytes, so it expects MB).
# Values read from vim25 are converted to these units so that no mode has to change.
my %target_units = (
    'cpu.capacity.provisioned.HOST'   => 'kHz',
    'cpu.capacity.usage.HOST'         => 'kHz',
    'cpu.capacity.demand.HOST'        => 'kHz',
    'cpu.capacity.contention.HOST'    => 'pct',
    'cpu.corecount.provisioned.HOST'  => 'count',
    'cpu.corecount.usage.HOST'        => 'count',
    'cpu.corecount.contention.HOST'   => 'pct',
    'cpu.capacity.provisioned.VM'     => 'MHz',
    'cpu.capacity.entitlement.VM'     => 'MHz',
    'cpu.capacity.usage.VM'           => 'MHz',
    'mem.capacity.provisioned.HOST'   => 'MB',
    'mem.capacity.usable.HOST'        => 'MB',
    'mem.capacity.usage.HOST'         => 'MB',
    'mem.capacity.contention.HOST'    => 'pct',
    'mem.consumed.vms.HOST'           => 'MB',
    'mem.consumed.userworlds.HOST'    => 'MB',
    'mem.reservedCapacityPct.HOST'    => 'pct',
    'mem.swap.current.HOST'           => 'KB',
    'mem.swap.target.HOST'            => 'KB',
    'mem.swap.readrate.HOST'          => 'KBps',
    'mem.swap.writerate.HOST'         => 'KBps',
    'mem.capacity.entitlement.VM'     => 'MB',
    'mem.capacity.usage.VM'           => 'MB',
    'disk.throughput.usage.HOST'      => 'KBps',
    'disk.throughput.contention.HOST' => 'ms',
    'disk.throughput.usage.VM'        => 'KBps',
    'disk.throughput.contention.VM'   => 'ms',
    'net.throughput.usage.HOST'       => 'KBps',
    'net.throughput.usable.HOST'      => 'KBps',
    'net.throughput.provisioned.HOST' => 'KBps',
    'net.throughput.contention.HOST'  => 'count',
    'net.throughput.usage.VM'         => 'KBps',
    'net.throughput.contention.VM'    => 'count',
    'power.capacity.usage.HOST'       => 'W',
    'power.capacity.usage.VM'         => 'W'
);

sub new {
    my ($class, %options) = @_;
    my $self = bless {}, $class;

    $self->{output} = $options{output};
    for my $key (qw/hostname port proto username password timeout/) {
        $self->{$key} = $options{$key};
    }
    $self->{http}  = centreon::plugins::http->new(%options);
    $self->{cache} = $options{cache};

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub settings {
    my ($self, %options) = @_;

    return 1 if (defined($self->{settings_done}));

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{port}     = $self->{port};
    $self->{option_results}->{proto}    = $self->{proto};
    $self->{option_results}->{timeout}  = $self->{timeout};
    # SOAP faults come with a 500 status and carry the error message: they must be read
    $self->{option_results}->{unknown_status}  = '';
    $self->{option_results}->{warning_status}  = '';
    $self->{option_results}->{critical_status} = '';

    $self->{http}->set_options(%{$self->{option_results}});
    $self->{settings_done} = 1;

    return 1;
}

# Returns the managed object type ('HostSystem', 'VirtualMachine') for a resource id.
sub entity_type {
    my ($self, %options) = @_;

    if ($options{rsrc_id} =~ /^([a-z]+)-(\d+)$/) {
        my $type = $entity_types{ uc($1) };
        return $type if (defined($type));
    }

    $self->{output}->option_exit(short_msg => "vim25: cannot determine the managed object type of resource '"
        . $options{rsrc_id} . "'.");
}

# Parses a vim25 response. The payload is untrusted input, so entity expansion and
# external DTD/network fetching are disabled: without this, a hostile or compromised
# endpoint could read local files through an external entity (XXE) or exhaust memory
# through nested entity expansion. Returns undef when the payload is not valid XML.
sub parse_xml {
    my ($self, %options) = @_;

    my $doc = eval {
        XML::LibXML->load_xml(
            string          => $options{content},
            no_network      => 1,
            expand_entities => 0,
            load_ext_dtd    => 0,
            no_blanks       => 1
        )
    };

    return ($@ || !defined($doc)) ? undef : $doc;
}

sub soap_request {
    my ($self, %options) = @_;

    $self->settings();

    my $envelope = '<?xml version="1.0" encoding="UTF-8"?>'
        . '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"'
        . ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"'
        . ' xmlns:xsd="http://www.w3.org/2001/XMLSchema"'
        . ' xmlns="' . $VIM_NS . '">'
        . '<soapenv:Body>' . $options{body} . '</soapenv:Body>'
        . '</soapenv:Envelope>';

    $self->{http}->add_header(key => 'Content-Type', value => 'text/xml; charset=utf-8');
    $self->{http}->add_header(key => 'SOAPAction', value => '"' . $VIM_NS . '"');
    $self->{http}->add_header(key => 'Cookie', value => $self->{cookie}) if (defined($self->{cookie}));

    my $content = $self->{http}->request(
        method          => 'POST',
        url_path        => '/sdk',
        query_form_post => $envelope,
        # SOAP faults are returned with a 500 status and must be read, not swallowed
        unknown_status  => '',
        insecure        => (defined($self->{option_results}->{insecure}) ? 1 : 0)
    );

    my $doc = $self->parse_xml(content => $content);
    if (!defined($doc)) {
        $self->{output}->option_exit(short_msg => "vim25: cannot parse the response of '" . $options{operation}
            . "' [http code: '" . $self->{http}->get_code() . "']. "
            . "Check that the vim25 SOAP API is reachable on " . $self->{proto} . '://' . $self->{hostname} . '/sdk');
    }

    my $xpc = XML::LibXML::XPathContext->new($doc);
    $xpc->registerNs('soapenv', 'http://schemas.xmlsoap.org/soap/envelope/');
    $xpc->registerNs('vim', $VIM_NS);

    my ($fault) = $xpc->findnodes('//soapenv:Fault');
    if (defined($fault)) {
        my ($reason) = $xpc->findnodes('.//faultstring', $fault);
        $self->{output}->option_exit(short_msg => "vim25: operation '" . $options{operation} . "' failed: "
            . (defined($reason) ? $reason->textContent() : 'unknown SOAP fault'));
    }

    return $xpc;
}

sub login {
    my ($self, %options) = @_;

    return 1 if (defined($self->{session_established}));

    my $xpc = $self->soap_request(
        operation => 'RetrieveServiceContent',
        body      => '<RetrieveServiceContent><_this type="ServiceInstance">ServiceInstance</_this></RetrieveServiceContent>'
    );

    for my $property (qw/sessionManager perfManager/) {
        my ($node) = $xpc->findnodes('//vim:' . $property);
        if (!defined($node)) {
            $self->{output}->option_exit(short_msg => "vim25: the service content returned by "
                . $self->{hostname} . " has no '" . $property . "' entry.");
        }
        $self->{$property} = $node->textContent();
    }

    # the session cookie must be replayed on every subsequent call
    my $cookie = $self->{http}->get_first_header(name => 'Set-Cookie');
    $self->{cookie} = $1 if (defined($cookie) && $cookie =~ /(vmware_soap_session=[^;]+)/);

    $self->soap_request(
        operation => 'Login',
        body      => '<Login><_this type="SessionManager">' . xml_escape($self->{sessionManager}) . '</_this>'
            . '<userName>' . xml_escape($self->{username}) . '</userName>'
            . '<password>' . xml_escape($self->{password}) . '</password></Login>'
    );

    # the cookie is normally issued by the Login call itself
    $cookie = $self->{http}->get_first_header(name => 'Set-Cookie');
    $self->{cookie} = $1 if (defined($cookie) && $cookie =~ /(vmware_soap_session=[^;]+)/);

    $self->{session_established} = 1;

    return 1;
}

sub logout {
    my ($self, %options) = @_;

    return 1 if (!defined($self->{session_established}));

    $self->soap_request(
        operation => 'Logout',
        body      => '<Logout><_this type="SessionManager">' . xml_escape($self->{sessionManager}) . '</_this></Logout>'
    );
    delete $self->{session_established};

    return 1;
}

# Builds, once per vCenter, the '<group>.<name>.<rollup>' => {key, unit} catalogue.
# It only changes with the vCenter version, so it is cached on disk.
sub counter_catalogue {
    my ($self, %options) = @_;

    return $self->{catalogue} if (defined($self->{catalogue}));

    my $statefile = 'vsphere8_vim25_counters_' . sha256_hex($self->{hostname} . ':' . $self->{port});
    if (defined($self->{cache}) && $self->{cache}->read(statefile => $statefile)) {
        my $cached = $self->{cache}->get(name => 'counters');
        if (ref($cached) eq 'HASH' && keys %$cached) {
            $self->{catalogue} = $cached;
            return $self->{catalogue};
        }
    }

    $self->login();

    my $xpc = $self->soap_request(
        operation => 'QueryPerfCounter',
        body      => '<RetrievePropertiesEx><_this type="PropertyCollector">propertyCollector</_this>'
            . '<specSet><propSet><type>PerformanceManager</type><pathSet>perfCounter</pathSet></propSet>'
            . '<objectSet><obj type="PerformanceManager">' . xml_escape($self->{perfManager}) . '</obj></objectSet></specSet>'
            . '<options/></RetrievePropertiesEx>'
    );

    my %catalogue;
    for my $counter ($xpc->findnodes('//vim:val/vim:PerfCounterInfo | //vim:PerfCounterInfo')) {
        my ($key)    = $xpc->findnodes('./vim:key', $counter);
        my ($group)  = $xpc->findnodes('./vim:groupInfo/vim:key', $counter);
        my ($name)   = $xpc->findnodes('./vim:nameInfo/vim:key', $counter);
        my ($rollup) = $xpc->findnodes('./vim:rollupType', $counter);
        my ($unit)   = $xpc->findnodes('./vim:unitInfo/vim:key', $counter);
        next if (grep { !defined($_) } ($key, $group, $name, $rollup, $unit));

        $catalogue{ join('.', $group->textContent(), $name->textContent(), $rollup->textContent()) } = {
            key  => $key->textContent(),
            unit => $unit->textContent()
        };
    }

    if (!keys %catalogue) {
        $self->{output}->option_exit(short_msg => "vim25: PerformanceManager returned an empty counter catalogue on "
            . $self->{hostname} . ". Performance counters cannot be collected.");
    }

    $self->{catalogue} = \%catalogue;
    $self->{cache}->write(data => { updated => time(), counters => \%catalogue }) if (defined($self->{cache}));

    return $self->{catalogue};
}

# Resolves a vStats counter id ('cpu.capacity.usage.HOST') to a vim25 counter.
sub resolve_counter {
    my ($self, %options) = @_;

    my $cid = $options{cid};
    (my $base = $cid) =~ s/\.(HOST|VM)$//;

    my $catalogue = $self->counter_catalogue();
    my @candidates = ($base, @{ $counter_aliases{$base} // [] });

    for my $candidate (@candidates) {
        for my $rollup (@rollup_preference) {
            my $counter = $catalogue->{ $candidate . '.' . $rollup };
            next if (!defined($counter));

            $self->{output}->add_option_msg(long_msg => "vim25: counter '" . $cid . "' is not advertised as such by "
                . $self->{hostname} . ", reading '" . $candidate . '.' . $rollup . "' instead.")
                if ($candidate ne $base);

            return $counter;
        }
    }

    $self->{output}->option_exit(short_msg => "vim25: counter '" . $cid . "' has no PerformanceManager equivalent on "
        . $self->{hostname} . " (looked for " . join(', ', map { "'" . $_ . ".<" . join('|', @rollup_preference) . ">'" } @candidates)
        . "). This counter cannot be collected from the vim25 API.");
}

sub convert_unit {
    my ($self, %options) = @_;

    my $from = $units{ $options{from} };
    my $to   = $units{ $options{to} };

    if (!defined($from) || !defined($to)) {
        $self->{output}->option_exit(short_msg => "vim25: unknown unit in conversion of counter '" . $options{cid}
            . "' ('" . $options{from} . "' to '" . $options{to} . "').");
    }
    if ($from->[0] ne $to->[0]) {
        $self->{output}->option_exit(short_msg => "vim25: counter '" . $options{cid} . "' is returned in '"
            . $options{from} . "' but is expected in '" . $options{to} . "', which measures something else ('"
            . $from->[0] . "' against '" . $to->[0] . "'). Refusing to report a wrong value.");
    }

    return $options{value} * $from->[1] / $to->[1];
}

# Reads one counter for one resource and returns it in the unit the modes expect.
sub get_perf_value {
    my ($self, %options) = @_;

    if (is_empty($options{cid}) || is_empty($options{rsrc_id})) {
        $self->{output}->option_exit(short_msg => "vim25: get_perf_value needs both a cid and a rsrc_id.");
    }

    my $target = $target_units{ $options{cid} };
    if (!defined($target)) {
        $self->{output}->option_exit(short_msg => "vim25: counter '" . $options{cid}
            . "' has no known target unit, its value cannot be converted safely.");
    }

    my $counter = $self->resolve_counter(cid => $options{cid});
    my $type    = $self->entity_type(rsrc_id => $options{rsrc_id});

    my $xpc = $self->soap_request(
        operation => 'QueryPerf',
        body      => '<QueryPerf><_this type="PerformanceManager">' . xml_escape($self->{perfManager}) . '</_this>'
            . '<querySpec><entity type="' . $type . '">' . xml_escape($options{rsrc_id}) . '</entity>'
            . '<maxSample>1</maxSample>'
            . '<metricId><counterId>' . $counter->{key} . '</counterId><instance></instance></metricId>'
            . '<intervalId>' . ($options{interval} // 20) . '</intervalId>'
            . '</querySpec></QueryPerf>'
    );

    my @values = $xpc->findnodes('//vim:value/vim:value');
    if (!@values) {
        $self->{output}->add_option_msg(short_msg => "no data for resource " . $options{rsrc_id}
            . " counter " . $options{cid} . " at the moment.");
        return undef;
    }

    # last sample of the series, consistent with what the vStats implementation returned
    my $raw = $values[-1]->textContent();
    return undef if (!defined($raw) || $raw !~ /^-?\d+(\.\d+)?$/ || $raw == -1);

    return $self->convert_unit(
        value => $raw,
        from  => $counter->{unit},
        to    => $target,
        cid   => $options{cid}
    );
}

# A vim25 session lives for 30 minutes by default. Every plugin run opens one, so
# leaving them behind would pile sessions up on the vCenter, which caps them (3000 by
# default, with a dedicated alarm since vSphere 9.1). Closing on destruction keeps a
# single short-lived session per run whatever the number of counters read.
sub DESTROY {
    my ($self) = @_;

    # nothing reliable can be called once global destruction has started
    return if (${^GLOBAL_PHASE} eq 'DESTRUCT');

    eval { $self->logout() };
}

sub xml_escape {
    my ($string) = @_;

    return '' if (!defined($string));
    $string =~ s/&/&amp;/g;
    $string =~ s/</&lt;/g;
    $string =~ s/>/&gt;/g;
    $string =~ s/"/&quot;/g;
    $string =~ s/'/&apos;/g;

    return $string;
}

1;

__END__

=head1 NAME

apps::vmware::vsphere8::custom::vim25 - Performance counters read from the vim25 SOAP API

=head1 DESCRIPTION

Collects performance counters through the vim25 C<PerformanceManager>, which is still
served by vCenter 9.1 while the vStats REST API used by
C<apps::vmware::vsphere8::custom::api> has been removed in that version.

Counter ids keep the vStats naming (C<cpu.capacity.usage.HOST>), so the modes are
unchanged: the counter is resolved against the catalogue advertised by the vCenter
itself and the returned value is converted to the unit the modes expect. A counter
with no vim25 equivalent, or whose unit cannot be converted, raises an explicit
error rather than reporting a wrong value.

This package requires neither the unmaintained VMware Perl SDK nor the
C<centreon_vmware> daemon: it builds the SOAP envelopes itself and sends them with
C<centreon::plugins::http>.

=head1 METHODS

=head2 get_perf_value

    my $value = $vim25->get_perf_value(cid => 'cpu.capacity.usage.HOST', rsrc_id => 'host-35');

Returns the last sample of the given counter for the given resource, converted to the
unit expected by the modes, or C<undef> when the vCenter currently has no sample.

=head2 counter_catalogue

Returns, and caches on disk, the C<< '<group>.<name>.<rollup>' => { key, unit } >>
catalogue advertised by the C<PerformanceManager> of the vCenter.

=head2 login / logout

Open and close the vim25 session. C<login> retrieves the service content, keeps the
C<sessionManager> and C<perfManager> managed object references and stores the
C<vmware_soap_session> cookie replayed on every subsequent call.

=cut
