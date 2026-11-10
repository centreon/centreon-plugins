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

package apps::incus::restapi::custom::api;

use strict;
use warnings;
use Encode qw(encode);
use centreon::plugins::http;
use centreon::plugins::misc qw(is_empty json_decode);

# CURLOPT_SSLCERT and CURLOPT_SSLKEY are set only by the curl backend.
# Source: centreon::plugins::backend::http::curl::set_auth
# https://github.com/centreon/centreon-plugins/blob/develop/src/centreon/plugins/backend/http/curl.pm

sub new {
    my ($class, %options) = @_;
    my $self = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->option_exit(short_msg => "Class Custom: Need to specify 'options' argument.");
    }

    if (!defined($options{noptions})) {
        # not_empty, port and protocol_http are applied by centreon::plugins::options
        # (plugins_global.md, section 11.1). The checks in check_options() cover a
        # core that does not implement those validators yet.
        $options{options}->add_options(arguments => {
            'hostname:s'    => { name => 'hostname', not_empty => 1 },
            'port:s'        => { name => 'port', default => 8443, type => 'port' },
            'proto:s'       => { name => 'proto', default => 'https', type => 'protocol_http' },
            'timeout:s'     => { name => 'timeout', default => 10, numeric => 1, greater_than => 0 },
            'cert-file:s'   => { name => 'cert_file', not_empty => 1 },
            'key-file:s'    => { name => 'key_file', not_empty => 1 },
            'cacert-file:s' => { name => 'cacert_file' },
            'project:s'     => { name => 'project', default => 'default' },
            'all-projects'  => { name => 'all_projects' },
            'filter-name:s' => { name => 'filter_name' },
            'exclude-name:s'=> { name => 'exclude_name' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, default_backend => 'curl');

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

# UNKNOWN before any request. curl.pm sets SSL_VERIFYPEER and SSL_VERIFYHOST to 0
# when --insecure is set, and it is the only backend that sets SSLCERT and SSLKEY.
sub transport_block {
    my (%args) = @_;

    my $backend = $args{http_backend};
    if (defined($backend) && $backend ne '' && $backend !~ /^\s*curl\s*$/i) {
        return 'HTTP backend must be curl';
    }
    if ($args{insecure}) {
        return 'Refusing --insecure: the server certificate must be verified';
    }
    return undef;
}

sub check_options {
    my ($self, %options) = @_;

    # A password on the command line shows up in ps and in the Centreon logs.
    # The client key stays unencrypted. This option is never forwarded.
    delete $self->{option_results}->{cert_pwd};

    $self->{hostname} = $self->{option_results}->{hostname} // '';
    $self->{port} = is_empty($self->{option_results}->{port}) ? 8443 : $self->{option_results}->{port};
    $self->{proto} = is_empty($self->{option_results}->{proto}) ? 'https' : $self->{option_results}->{proto};
    $self->{timeout} = is_empty($self->{option_results}->{timeout}) ? 10 : $self->{option_results}->{timeout};

    if (is_empty($self->{hostname})) {
        $self->{output}->option_exit(short_msg => 'Please set hostname option');
    }
    if ($self->{port} !~ /^\d+$/ || $self->{port} < 1 || $self->{port} > 65535) {
        $self->{output}->option_exit(short_msg => "Bad value provided for option port: '$self->{port}'. '$self->{port}' must be a numeric TCP port value between 1 and 65535.");
    }
    if ($self->{proto} ne 'http' && $self->{proto} ne 'https') {
        $self->{output}->option_exit(short_msg => "Bad value provided for option proto: '$self->{proto}'. '$self->{proto}' must be a valid HTTP protocol ('http' or 'https').");
    }
    if ($self->{timeout} !~ /^\d+$/ || $self->{timeout} <= 0) {
        $self->{output}->option_exit(short_msg => "Bad value provided for option timeout: '$self->{timeout}'. '$self->{timeout}' must be a numeric value.");
    }

    my $block = transport_block(
        http_backend => $self->{option_results}->{http_backend},
        insecure => $self->{option_results}->{insecure}
    );
    if (defined($block)) {
        $self->{output}->option_exit(short_msg => $block);
    }
    delete $self->{option_results}->{insecure};
    $self->{option_results}->{http_backend} = 'curl';

    if (is_empty($self->{option_results}->{cert_file}) || is_empty($self->{option_results}->{key_file})) {
        $self->{output}->option_exit(short_msg => 'Please set --cert-file and --key-file');
    }

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
    $self->{option_results}->{timeout} = $self->{timeout};

    return 0;
}

sub settings {
    my ($self, %options) = @_;

    delete $self->{option_results}->{cert_pwd};
    delete $self->{option_results}->{insecure};
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->set_options(%{$self->{option_results}});
}

sub cache_id {
    my ($self, %options) = @_;

    my $scope = $self->{option_results}->{all_projects} ? 'all-projects' : ($self->{option_results}->{project} // 'default');
    return join('_', $self->{hostname}, $self->{port}, $scope);
}

# Percent-encode one path segment (RFC 3986 unreserved characters are left as-is).
sub encode_path_segment {
    my ($name) = @_;

    return undef if !defined($name);
    my $bytes = encode('UTF-8', "$name");
    $bytes =~ s/([^A-Za-z0-9\-\._~])/sprintf('%%%02X', ord($1))/ge;
    return $bytes;
}

sub decode_json_body {
    my ($content) = @_;

    return undef if (!defined($content) || ref($content) || $content eq '');
    # silence: the caller reports a bad body. json_decode would warn on STDERR.
    # Source: centreon::plugins::misc::json_decode
    my $decoded = json_decode($content, silence => 1);
    return undef if (ref($decoded) ne 'HASH');
    return $decoded;
}

# Sync response, shortened:
# {"type":"sync","status":"Success","status_code":200,"metadata":[]}
# status_code other than 200, or missing metadata: failure, keeping error when present.
# Source: https://github.com/lxc/incus/blob/main/doc/rest-api.yaml
sub parse_sync {
    my ($decoded) = @_;

    if (ref($decoded) ne 'HASH') {
        return (undef, 'unreadable JSON');
    }

    my $code = $decoded->{status_code};
    if (defined($code) && $code != 200) {
        my $err = (defined($decoded->{error}) && $decoded->{error} ne '')
            ? $decoded->{error}
            : "status_code $code";
        return (undef, $err);
    }
    if (!exists($decoded->{metadata}) || !defined($decoded->{metadata})) {
        my $err = (defined($decoded->{error}) && $decoded->{error} ne '')
            ? $decoded->{error}
            : 'metadata missing';
        return (undef, $err);
    }
    if (!defined($code)) {
        my $err = (defined($decoded->{error}) && $decoded->{error} ne '')
            ? $decoded->{error}
            : 'status_code missing';
        return (undef, $err);
    }
    return ($decoded->{metadata}, undef);
}

sub build_get_params {
    my (%options) = @_;

    if ($options{all_projects} && !$options{allow_all_projects}) {
        return (undef, 'This Incus endpoint does not document all-projects');
    }

    my @params;
    push @params, 'recursion=' . $options{recursion} if (defined($options{recursion}));
    if ($options{all_projects} && $options{allow_all_projects}) {
        push @params, 'all-projects=true';
    } elsif ($options{allow_project}) {
        my $project = (defined($options{project}) && $options{project} ne '') ? $options{project} : 'default';
        push @params, 'project=' . $project;
    }
    return (\@params, undef);
}

# misc::is_excluded() dies on a broken pattern. The eval turns that into an
# UNKNOWN that names --filter-name or --exclude-name.
sub keep_name {
    my ($name, $filter, $exclude) = @_;

    $name = '' if (!defined($name));
    if (defined($filter) && $filter ne '') {
        my $matched = eval { $name =~ /$filter/ };
        return (undef, "Invalid --filter-name regex: $filter") if ($@);
        return (0, undef) if (!$matched);
    }
    if (defined($exclude) && $exclude ne '') {
        my $matched = eval { $name =~ /$exclude/ };
        return (undef, "Invalid --exclude-name regex: $exclude") if ($@);
        return (0, undef) if ($matched);
    }
    return (1, undef);
}

sub rfc3339_epoch {
    my ($timestamp) = @_;

    return undef if (!defined($timestamp) || $timestamp !~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.\d+)?(Z|[+-]\d{2}:\d{2})$/);
    my ($year, $month, $day, $hour, $minute, $second, $zone) = ($1, $2, $3, $4, $5, $6, $7);
    require Time::Local;
    my $epoch = Time::Local::timegm($second, $minute, $hour, $day, $month - 1, $year);
    return $epoch if ($zone eq 'Z');
    return undef if ($zone !~ /^([+-])(\d{2}):(\d{2})$/);
    my $offset = (($2 * 3600) + ($3 * 60));
    $offset = -$offset if ($1 eq '-');
    return $epoch - $offset;
}

sub filter_records {
    my ($self, %options) = @_;

    my $name_key = defined($options{name_key}) ? $options{name_key} : 'name';
    my @kept;
    foreach my $record (@{$options{records}}) {
        my ($keep, $error) = keep_name(
            $record->{$name_key},
            $self->{option_results}->{filter_name},
            $self->{option_results}->{exclude_name}
        );
        if (defined($error)) {
            $self->{output}->option_exit(short_msg => $error);
        }
        push @kept, $record if ($keep);
    }
    return \@kept;
}

sub get {
    my ($self, %options) = @_;

    my ($params, $error) = build_get_params(
        recursion => $options{recursion},
        allow_project => $options{allow_project},
        allow_all_projects => $options{allow_all_projects},
        project => $self->{option_results}->{project},
        all_projects => $self->{option_results}->{all_projects} ? 1 : 0
    );
    if (defined($error)) {
        $self->{output}->option_exit(short_msg => $error);
    }

    $self->settings();
    my $content = $self->{http}->request(
        method => 'GET',
        url_path => $options{path},
        get_param => $params,
        unknown_status => '',
        warning_status => '',
        critical_status => ''
    );

    if (!defined($content) || $content eq '') {
        $self->{output}->option_exit(short_msg => 'Incus API returned an empty response');
    }
    my $decoded = decode_json_body($content);
    if (!defined($decoded)) {
        $self->{output}->option_exit(short_msg => 'Cannot decode Incus JSON response');
    }
    my ($metadata, $api_error) = parse_sync($decoded);
    if (defined($api_error)) {
        $self->{output}->option_exit(short_msg => "Incus API error: $api_error");
    }
    if (defined($options{expect}) && ref($metadata) ne $options{expect}) {
        $self->{output}->option_exit(short_msg => "Incus metadata is not a $options{expect}");
    }
    return $metadata;
}

sub instances {
    my ($self, %options) = @_;

    my $recursion = defined($options{recursion}) ? $options{recursion} : 1;
    return $self->get(
        path => '/1.0/instances',
        recursion => $recursion,
        allow_project => 1,
        allow_all_projects => 1,
        expect => 'ARRAY'
    );
}

sub storage_pools {
    my ($self, %options) = @_;

    return $self->get(
        path => '/1.0/storage-pools',
        recursion => 1,
        allow_project => 1,
        allow_all_projects => 0,
        expect => 'ARRAY'
    );
}

sub storage_pool_resources {
    my ($self, %options) = @_;

    my $segment = encode_path_segment($options{name});
    if (!defined($segment) || $segment eq '') {
        $self->{output}->option_exit(short_msg => 'Storage pool name is empty');
    }
    return $self->get(
        path => '/1.0/storage-pools/' . $segment . '/resources',
        allow_project => 0,
        allow_all_projects => 0,
        expect => 'HASH'
    );
}

sub warnings {
    my ($self, %options) = @_;

    return $self->get(
        path => '/1.0/warnings',
        recursion => 1,
        allow_project => 1,
        allow_all_projects => 0,
        expect => 'ARRAY'
    );
}

sub networks {
    my ($self, %options) = @_;

    return $self->get(
        path => '/1.0/networks',
        recursion => 1,
        allow_project => 1,
        allow_all_projects => 1,
        expect => 'ARRAY'
    );
}

sub cluster {
    my ($self, %options) = @_;

    return $self->get(
        path => '/1.0/cluster',
        allow_project => 0,
        allow_all_projects => 0,
        expect => 'HASH'
    );
}

sub cluster_members {
    my ($self, %options) = @_;

    return $self->get(
        path => '/1.0/cluster/members',
        recursion => 1,
        allow_project => 0,
        allow_all_projects => 0,
        expect => 'ARRAY'
    );
}

# GET /1.0/operations?recursion=1 groups operations by status class
# ({"running": [...], "success": [...], "failure": [...]}), not in one list.
sub flatten_operations {
    my ($metadata) = @_;

    return [ map { @{$metadata->{$_} // []} } sort keys %{$metadata // {}} ];
}

sub operations {
    my ($self, %options) = @_;

    my $metadata = $self->get(
        path => '/1.0/operations',
        recursion => 1,
        allow_project => 1,
        allow_all_projects => 1,
        expect => 'HASH'
    );
    return flatten_operations($metadata);
}

1;

__END__

=head1 NAME

Incus REST API client.

=head1 REST API OPTIONS

Incus HTTPS API. TLS client authentication uses the curl backend, which is the
only Centreon HTTP backend that sets CURLOPT_SSLCERT and CURLOPT_SSLKEY.
--insecure is refused before any request: curl would disable server certificate
verification.

=over 8

=item B<--hostname>

Incus address.

=item B<--port>

API port (default: 8443).

=item B<--proto>

Protocol (default: https).

=item B<--cert-file>

Client certificate (PEM).

=item B<--key-file>

Unencrypted client private key (PEM). There is no --cert-pwd option: a key
password on the command line is visible in process listings and Centreon logs.

=item B<--cacert-file>

Server certificate used as the trust anchor (CAINFO).

=item B<--timeout>

HTTP timeout in seconds (default: 10).

=item B<--project>

Incus project (default: default). Sent only on endpoints that document it.
Ignored when --all-projects is set.

=item B<--all-projects>

Request every project. Refused, before any call, on endpoints whose OpenAPI
definition has no all-projects parameter.

=item B<--filter-name>

Perl regular expression. A record is kept when its name matches.
Warnings are matched on uuid, operations on id, cluster members on server_name.

=item B<--exclude-name>

Perl regular expression. A record is dropped when its name matches.

=back

=cut
