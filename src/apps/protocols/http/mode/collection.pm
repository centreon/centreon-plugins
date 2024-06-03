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

package apps::protocols::http::mode::collection;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::http;
use Safe;
use centreon::plugins::misc;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);
use Time::HiRes qw(gettimeofday tv_interval);
use JSON::XS;
use XML::LibXML::Simple;
use JSON::Path;
$JSON::Path::Safe = 0;

sub custom_select_threshold {
    my ($self, %options) = @_;

    my $status = 'ok';
    our $expand = $self->{result_values}->{expand};
    if (defined($self->{result_values}->{config}->{critical}) && $self->{result_values}->{config}->{critical} &&
        $self->{instance_mode}->{safe}->reval($self->{result_values}->{config}->{critical})) {
        $status = 'critical';
    } elsif (defined($self->{result_values}->{config}->{warning}) && $self->{result_values}->{config}->{warning} ne '' &&
        $self->{instance_mode}->{safe}->reval($self->{result_values}->{config}->{warning})) {
        $status = 'warning';
    } elsif (defined($self->{result_values}->{config}->{unknown}) && $self->{result_values}->{config}->{unknown} &&
        $self->{instance_mode}->reval($self->{result_values}->{config}->{unknown})) {
        $status = 'unknown';
    }
    if ($@) {
        $self->{output}->add_option_msg(short_msg => 'Unsafe code evaluation: ' . $@);
        $self->{output}->option_exit();
    }

    $self->{result_values}->{last_status} = $status;
    return $status;
}

sub custom_select_perfdata {
    my ($self, %options) = @_;

    return if (!defined($self->{result_values}->{config}->{perfdatas}));
    foreach (@{$self->{result_values}->{config}->{perfdatas}}) {
        next if (!defined($_->{value}) || $_->{value} !~ /^[+-]?\d+(?:\.\d+)?$/);
        $self->{output}->perfdata_add(%$_);
    }
}

sub custom_select_output {
    my ($self, %options) = @_;

    return '' if (
        $self->{result_values}->{last_status} eq 'ok' && defined($self->{result_values}->{config}->{formatting}) &&
        defined($self->{result_values}->{config}->{formatting}->{display_ok}) &&
        $self->{result_values}->{config}->{formatting}->{display_ok} =~ /^false|0$/
    );

    my $format;
    if (defined($self->{result_values}->{config}->{ 'formatting_' . $self->{result_values}->{last_status} })) {
        $format = $self->{result_values}->{config}->{ 'formatting_' . $self->{result_values}->{last_status} };
    } elsif (defined($self->{result_values}->{config}->{formatting})) {
        $format = $self->{result_values}->{config}->{formatting};
    }

    if (defined($format)) {
        return sprintf(
            $format->{printf_msg}, @{$format->{printf_var}}
        );
    }

    # without formatting: [name: xxxxxx][test: xxxx][test2: xxx][mytable.plcRead: xxx][mytable.plcWrite: xxx]
    my $output = '';
    foreach (sort keys %{$self->{result_values}->{expand}}) {
        next if (/^(?:constants|builtin)\./);
        $output .= '[' . $_ . ': ' . $self->{result_values}->{expand}->{$_} . ']';
    }

    return $output;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'selections', type => 1, message_multiple => 'All selections are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{selections} = [
        { label => 'select', threshold => 0, set => {
                key_values => [ { name => 'expand' }, { name => 'config' } ],
                closure_custom_output => $self->can('custom_select_output'),
                closure_custom_perfdata => $self->can('custom_select_perfdata'),
                closure_custom_threshold_check => $self->can('custom_select_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
   
    $options{options}->add_options(arguments => {
        'config:s'            => { name => 'config' },
        'filter-selection:s%' => { name => 'filter_selection' },
        'constant:s%'         => { name => 'constant' }
    });

    $self->{safe} = Safe->new();
    $self->{safe}->share('$expand');

    $self->{safe_func} = Safe->new();
    $self->{safe_func}->share('$assign_var');

    $self->{builtin} = {};

    $self->{http_cache} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{config})) {
        $self->{output}->add_option_msg(short_msg => 'Please set config option');
        $self->{output}->option_exit();
    }
    $self->{http_cache}->check_options(option_results => $self->{option_results});
}

sub slurp_file {
    my ($self, %options) = @_;

    my $content = do {
        local $/ = undef;
        if (!open my $fh, '<', $options{file}) {
            $self->{output}->add_option_msg(short_msg => "Could not open file $options{file}: $!");
            $self->{output}->option_exit();
        }
        <$fh>;
    };

    return $content;
}

sub read_config {
    my ($self, %options) = @_;

    my $content;
    if ($self->{option_results}->{config} =~ /\n/m || ! -f "$self->{option_results}->{config}") {
        $content = $self->{option_results}->{config};
    } else {
        $content = $self->slurp_file(file => $self->{option_results}->{config});
    }

    eval {
        $self->{config} = JSON::XS->new->decode($content);
    };
    if ($@) {
        $self->{output}->output_add(long_msg => "json config error: $@", debug => 1);
        $self->{output}->add_option_msg(short_msg => 'Cannot decode json config');
        $self->{output}->option_exit();
    }
}

sub get_map_value {
    my ($self, %options) = @_;

    return undef if (
        !defined($self->{config}->{mapping}) ||
        !defined($self->{config}->{mapping}->{ $options{map} })
    );
    return '' if (!defined($self->{config}->{mapping}->{ $options{map} }->{ $options{value} }));
    return $self->{config}->{mapping}->{ $options{map} }->{ $options{value} };
}

sub validate_name {
    my ($self, %options) = @_;

    if (!defined($options{name})) {
        $self->{output}->add_option_msg(short_msg => "name attribute is missing in your http collection (path: $options{section})");
        $self->{output}->option_exit();
    }
    if ($options{name} !~ /^[a-zA-Z0-9]+$/) {
        $self->{output}->add_option_msg(short_msg => "name attribute in your http collection (path: $options{section}) is incorrect: " . $options{name});
        $self->{output}->option_exit();
    }
}

sub get_payload {
    my ($self, %options) = @_;

    return if (!defined($options{rq}->{payload}) || !defined($options{rq}->{payload}->{type}));

    if ($options{rq}->{payload}->{type} !~ /^(?:file|data|json)$/) {
        $self->{output}->add_option_msg(short_msg => "type attribute is wrong [http > requests > $options{rq}->{name} > payload] (allowed types: file / data / json)");
        $self->{output}->option_exit();
    }

    if (!defined($options{rq}->{payload}->{value})) {
        $self->{output}->add_option_msg(short_msg => "value attribute is missing [http > requests > $options{rq}->{name} > payload]");
        $self->{output}->option_exit();
    }

    my $content;
    if ($options{rq}->{payload}->{type} eq 'file') {
        if (ref($options{rq}->{payload}->{value}) ne '' || $options{rq}->{payload}->{value} eq '') {
            $self->{output}->add_option_msg(short_msg => "value attribute is wrong for file type [http > requests > $options{rq}->{name} > payload]");
            $self->{output}->option_exit();
        }

        $content = $self->slurp_file(file => $options{rq}->{payload}->{value});
    } elsif ($options{rq}->{payload}->{type} eq 'data') {
        $content = $options{rq}->{payload}->{value};
    } elsif ($options{rq}->{payload}->{type} eq 'json') {
        eval {
            $content = JSON::XS->new->encode($options{rq}->{payload}->{value});
        };
        if ($@) {
            $self->{output}->output_add(long_msg => "json payload error: $@", debug => 1);
            $self->{output}->add_option_msg(short_msg => "cannot encode json type payload [http > requests > $options{rq}->{name} > payload]");
            $self->{output}->option_exit();
        }
    }

    return $content;
}

sub call_http {
    my ($self, %options) = @_;

    if ((!defined($options{rq}->{full_url}) || $options{rq}->{full_url} eq '') &&
        (!defined($options{rq}->{hostname}) || $options{rq}->{hostname} eq '')) {
        $self->{output}->add_option_msg(short_msg => "hostname or full_url attribute is missing [http > requests > $options{rq}->{name}]");
        $self->{output}->option_exit();
    }
    if (!defined($options{rq}->{rtype}) || $options{rq}->{rtype} !~ /^(?:txt|json|xml)$/) {
        $self->{output}->add_option_msg(short_msg => "rtype attribute is missing/wrong [http > requests > $options{rq}->{name}]");
        $self->{output}->option_exit();
    }

    $self->{current_section} = '[http > requests]';

    my $creds = {};
    if (defined($options{rq}->{authorization}) && defined($options{rq}->{authorization}->{username})) {
        $options{rq}->{authorization}->{username} = $self->substitute_string(value => $options{rq}->{authorization}->{username});
        $options{rq}->{authorization}->{password} = $self->substitute_string(value => $options{rq}->{authorization}->{password});
        $creds = {
            credentials => 1,
            %{$options{rq}->{authorization}}
        };
    }

    my $headers;
    if (defined($options{rq}->{headers}) && ref($options{rq}->{headers}) eq 'ARRAY') {
        $headers = [];
        foreach my $header (@{$options{rq}->{headers}}) {
            push @$headers, $self->substitute_string(value => $header);
        }
    }

    my $get_params;
    if (defined($options{rq}->{get_params}) && ref($options{rq}->{get_params}) eq 'ARRAY') {
        $get_params = [];
        foreach my $param (@{$options{rq}->{get_params}}) {
            push @$get_params, $self->substitute_string(value => $param);
        }
    }

    my $post_param = $self->get_payload(rq => $options{rq});

    my $http = $options{http};
    if (!defined($http)) {
        $http = centreon::plugins::http->new(noptions => 1, output => $self->{output});
    }

    my $full_url;
    my $hostname = $self->substitute_string(value => $options{rq}->{hostname});
    if (defined($options{rq}->{full_url}) && $options{rq}->{full_url} ne '') {
        $full_url = $self->substitute_string(value => $options{rq}->{full_url});
        $hostname = '';
    }

    my $timing0 = [gettimeofday];
    my ($content) = $http->request(
        http_backend => $self->substitute_string(value => $options{rq}->{backend}),
        method => $self->substitute_string(value => $options{rq}->{method}),
        full_url => $full_url,
        hostname => $hostname,
        proto => $self->substitute_string(value => $options{rq}->{proto}),
        port => $self->substitute_string(value => $options{rq}->{port}),
        url_path => $self->substitute_string(value => $options{rq}->{endpoint}),
        proxyurl => $self->substitute_string(value => $options{rq}->{proxyurl}),
        header => $headers,
        timeout => $self->substitute_string(value => $options{rq}->{timeout}),
        get_param => $get_params,
        query_form_post => $self->substitute_string(value => $post_param),
        insecure => $options{rq}->{insecure},
        unknown_status => '',
        warning_status => '',
        critical_status => '',
        %$creds
    );
    $self->add_builtin(name => 'httpExecutionTime.' . $options{rq}->{name}, value => tv_interval($timing0, [gettimeofday]));
    $self->add_builtin(name => 'httpCode.' . $options{rq}->{name}, value => $http->get_code());
    $self->add_builtin(name => 'httpMessage.' . $options{rq}->{name}, value => $http->get_message());

    return ($http->get_header(), $content, $http);
}

sub parse_txt {
    my ($self, %options) = @_;

    if (!defined($options{conf}->{name}) || $options{conf}->{name} eq '') {
        $self->{output}->add_option_msg(short_msg => "name attribute is missing [http > requests > $options{name}]");
        $self->{output}->option_exit();
    }
    if (!defined($options{conf}->{re}) || $options{conf}->{re} eq '') {
        $self->{output}->add_option_msg(short_msg => "re attribute is missing [http > requests > $options{name} > $options{conf}->{name}]");
        $self->{output}->option_exit();
    }
    if (!defined($options{conf}->{entries})) {
        $self->{output}->add_option_msg(short_msg => "entries section is missing [http > requests > $options{name} > $options{conf}->{name}]");
        $self->{output}->option_exit();
    }
    foreach (@{$options{conf}->{entries}}) {
        if (!defined($_->{id})) {
            $self->{output}->add_option_msg(short_msg => "id attribute is missing or wrong [http > requests > $options{name} > $options{conf}->{name}]");
            $self->{output}->option_exit();
        }
        if (!defined($_->{offset}) || $_->{offset} !~ /^(?:[0-9]+)$/) {
            $self->{output}->add_option_msg(short_msg => "offset attribute is missing or wrong [http > requests > $options{name} > $options{conf}->{name}]");
            $self->{output}->option_exit();
        }
    }

    my $modifier = defined($options{conf}->{modifier}) ? $options{conf}->{modifier} : '';

    my @entries = ();
    foreach (@{$options{conf}->{entries}}) {
        next if ($_->{offset} !~ /^[0-9]+$/);

        push @entries, $_;
    }

    my $content = defined($options{conf}->{type}) && $options{conf}->{type} eq 'header' ? $options{headers} : $options{content}; 

    my $local = {};
    my $i = 0;
    while ($content =~ /(?$modifier)$options{conf}->{re}/g) {
        my $instance = $i;
        my $name = $options{name} . ucfirst($options{conf}->{name});

        my $entry = {};
        foreach (@entries) {
            my $offset = "\$" . $_->{offset};
            my $value = eval "$offset";
            if (!defined($value)) {
                $entry->{ $_->{id} } = '';
                next;
            }

            $entry->{ $_->{id} } = $value;

            if (defined($_->{map}) && $_->{map} ne '') {
                if (!defined($self->{config}->{mapping}) || !defined($self->{config}->{mapping}->{ $_->{map} })) {
                    $self->{output}->add_option_msg(short_msg => "unknown map attribute [http > requests > $options{name} > $options{conf}->{name}]: $_->{map}");
                    $self->{output}->option_exit();
                }
                $entry->{ $_->{id} } = $self->{config}->{mapping}->{ $_->{map} }->{$value};
            }

            if (defined($_->{sampling}) && $_->{sampling} == 1) {
                $self->{http_collected_sampling}->{tables}->{$name} = {}
                    if (!defined($self->{http_collected_sampling}->{tables}->{$name}));
                $self->{http_collected_sampling}->{tables}->{$name}->{$instance}->{ $_->{id} } = $value;
            }
        }

        $self->{http_collected}->{tables}->{$name}->{$instance} = $entry;
        $local->{$name}->{$instance} = $entry;
        $i++;

        last if (!defined($options{conf}->{multiple}));
    }

    return $local;
}

sub parse_structure {
    my ($self, %options) = @_;

    if (!defined($options{conf}->{name}) || $options{conf}->{name} eq '') {
        $self->{output}->add_option_msg(short_msg => "name attribute is missing [http > requests > $options{name}]");
        $self->{output}->option_exit();
    }
    if (!defined($options{conf}->{path}) || $options{conf}->{path} eq '') {
        $self->{output}->add_option_msg(short_msg => "path attribute is missing [http > requests > $options{name} > $options{conf}->{name}]");
        $self->{output}->option_exit();
    }
    if (!defined($options{conf}->{entries})) {
        $self->{output}->add_option_msg(short_msg => "entries section is missing [http > requests > $options{name} > $options{conf}->{name}]");
        $self->{output}->option_exit();
    }

    $options{conf}->{path} = $self->substitute_string(value => $options{conf}->{path});

    my $content;
    if ($options{rtype} eq 'json') {
        eval {
            $content = JSON::XS->new->utf8->decode($options{content});
        };
    } elsif ($options{rtype} eq 'xml') {
        eval {
            $SIG{__WARN__} = sub {};
            $content = XMLin($options{content}, ForceArray => $options{force_array}, KeyAttr => []);
        };
    }
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
        $self->{output}->output_add(long_msg => "$@", debug => 1);
        $self->{output}->option_exit();
    }

    if ($self->{output}->is_debug()) {
        my $encoded = JSON::XS->new->allow_nonref(1)->utf8->pretty->encode($content);
        $self->{output}->output_add(long_msg => '======> returned JSON structure:', debug => 1);
        $self->{output}->output_add(long_msg => "$encoded", debug => 1);
    }

    my $jpath = JSON::Path->new($options{conf}->{path});
    my @values = $jpath->values($content);

    my $local = {};
    my $i = 0;
    foreach my $value (@values) {
        my $instance = $i;
        my $name = $options{name} . ucfirst($options{conf}->{name});

        my $entry = {};
        foreach (@{$options{conf}->{entries}}) {
            if (!defined($_->{id})) {
                $self->{output}->add_option_msg(short_msg => "id attribute is missing or wrong [http > requests > $options{name} > $options{conf}->{name}]");
                $self->{output}->option_exit();
            }

            my $ref = ref($value);
            if ($ref eq 'HASH') {

                if (!defined($value->{ $_->{id} })) {
                    # Check and assume in case of hash reference first part is the hash ref and second the hash key
                    if($_->{id} =~ /^(.+?)\.(.*)$/){
                        if (!defined($value->{$1}->{$2})) {
                            $entry->{ $_->{id} } = '';
                            next;
                        }else{
                            $entry->{ $_->{id} } = $value->{$1}->{$2};
                        }
                    }else {
                        $entry->{ $_->{id} } = '';
                        next;
                    }
                }else {
                    $entry->{ $_->{id} } = $value->{ $_->{id} };
                }
            } elsif (ref($value) eq 'ARRAY') {
                next;
            } elsif ($ref eq '' || $ref eq 'JSON::PP::Boolean') {
                $entry->{ $_->{id} } = $value;
            } else {
                next;
            }

            if (defined($_->{map}) && $_->{map} ne '') {
                if (!defined($self->{config}->{mapping}) || !defined($self->{config}->{mapping}->{ $_->{map} })) {
                    $self->{output}->add_option_msg(short_msg => "unknown map attribute [http > requests > $options{name} > $options{conf}->{name}]: $_->{map}");
                    $self->{output}->option_exit();
                }
                $entry->{ $_->{id} } = $self->{config}->{mapping}->{ $_->{map} }->{ $entry->{ $_->{id} } };
            }

            if (defined($_->{sampling}) && $_->{sampling} == 1) {
                $self->{http_collected_sampling}->{tables}->{$name} = {}
                    if (!defined($self->{http_collected_sampling}->{tables}->{$name}));
                $self->{http_collected_sampling}->{tables}->{$name}->{$instance}->{ $_->{id} } = $entry->{ $_->{id} };
            }
        }

        $self->{http_collected}->{tables}->{$name}->{$instance} = $entry;
        $local->{$name}->{$instance} = $entry;
        $i++;
    }

    return $local;
}

sub collect_http_tables {
    my ($self, %options) = @_;

    return if (!defined($options{requests}));

    for (my $i = 0; $i < scalar(@{$options{requests}});) {
        $self->validate_name(name => $options{requests}->[$i]->{name}, section => "[http > requests]");

        # first init
        if ($options{level} == 1 && (!defined($self->{scenario_loop}) || $self->{scenario_loop} == 0)) {
            $self->{scenario_stopped} = 0;
            $self->{scenario_retry} = 0;
            $self->{scenario_loop} = 0;
        }
        # quit recursive sub requests
        if ($self->{scenario_stopped} == 1) {
            return ;
        }

        my ($headers, $content, $http);
        my ($rv, $local_http_cache);
        ($rv, $local_http_cache) = $self->use_local_http_cache(rq => $options{requests}->[$i]);

        if ($rv == 0) {
            ($headers, $content, $http) = $self->call_http(rq => $options{requests}->[$i], http => $options{http});
            $self->set_builtin();

            if (defined($options{requests}->[$i]->{scenario_stopped_first}) && $options{requests}->[$i]->{scenario_stopped_first} &&
                $self->check_filter2(filter => $options{requests}->[$i]->{scenario_stopped_first}, values => $self->{expand})) {
                $self->{scenario_stopped} = 1;
                if (defined($options{requests}->[$i]->{scenario_retry}) && $options{requests}->[$i]->{scenario_retry} =~ /^true|1$/i) {
                    $self->{scenario_loop}++;
                    $self->{scenario_retry} = 1;
                }
            } else {
                my $local = {};
                if (defined($options{requests}->[$i]->{parse})) {
                    foreach my $conf (@{$options{requests}->[$i]->{parse}}) {
                        my $lentries = {};
                        if ($options{requests}->[$i]->{rtype} eq 'txt') {
                            $lentries = $self->parse_txt(name => $options{requests}->[$i]->{name}, headers => $headers, content => $content, conf => $conf);
                        } else {
                            $lentries = $self->parse_structure(
                                name => $options{requests}->[$i]->{name},
                                content => $content,
                                conf => $conf,
                                rtype => $options{requests}->[$i]->{rtype},
                                force_array => $options{requests}->[$i]->{force_array}
                            );
                        }

                        $local = { %$local, %$lentries };
                    }
                }

                $self->set_functions(
                    section => "http > requests > $options{requests}->[$i]->{name}",
                    functions => $options{requests}->[$i]->{functions},
                    default => 1
                );

                if (defined($options{requests}->[$i]->{scenario_stopped}) && $options{requests}->[$i]->{scenario_stopped} &&
                    $self->check_filter2(filter => $options{requests}->[$i]->{scenario_stopped}, values => $self->{expand})) {
                    $self->{scenario_stopped} = 1;
                    if (defined($options{requests}->[$i]->{scenario_retry}) && $options{requests}->[$i]->{scenario_retry} =~ /^true|1$/i) {
                        $self->{scenario_loop}++;
                        $self->{scenario_retry} = 1;
                    }
                } else {
                    $self->save_local_http_cache(local_http_cache => $local_http_cache, local => $local);
                }
            }
        }

        $self->collect_http_tables(requests => $options{requests}->[$i]->{requests}, http => $http, level => $options{level} + 1);

        if ($options{level} == 1 && $self->{scenario_retry} == 1 && $self->{scenario_loop} == 1) {
            $self->clean_local_cache(rq => $options{requests}->[$i]);
            $self->{scenario_stopped} = 0;
            $self->{scenario_retry} = 0;
        } else {
            $i++;
        }
    }
}

sub is_http_cache_enabled {
    my ($self, %options) = @_;

    return 0 if (
        !defined($self->{config}->{http}->{cache}) || 
        !defined($self->{config}->{http}->{cache}->{enable}) ||
        $self->{config}->{http}->{cache}->{enable} !~ /^true|1$/i
    );

    return 1;
}

sub clean_local_cache {
    my ($self, %options) = @_;

    return 0 if (!defined($options{rq}->{cache_file}) || $options{rq}->{cache_file} eq '');

    my $local_http_cache = centreon::plugins::statefile->new(output => $self->{output});
    $local_http_cache->check_options(option_results => $self->{option_results});
    $local_http_cache->read(
        statefile => $self->substitute_string(value => $options{rq}->{cache_file})
    );

    $local_http_cache->write(data => {});
}

sub use_local_http_cache {
    my ($self, %options) = @_;

    return 0 if (!defined($options{rq}->{cache_file}) || $options{rq}->{cache_file} eq '');

    my $local_http_cache = centreon::plugins::statefile->new(output => $self->{output});
    $local_http_cache->check_options(option_results => $self->{option_results});

    my $has_cache_file = $local_http_cache->read(
        statefile => $self->substitute_string(value => $options{rq}->{cache_file})
    );
    $self->{local_http_collected} = $local_http_cache->get(name => 'http_collected');
    my $reload = defined($options{rq}->{cache_reload}) && $options{rq}->{cache_reload} =~ /(\d+)/ ? 
        $options{rq}->{cache_reload} : 60;
    return (0, $local_http_cache) if (
        $has_cache_file == 0 || 
        !defined($self->{local_http_collected}) || 
        ((time() - $self->{local_http_collected}->{epoch}) > ($reload * 60))
    );

    foreach my $name (keys %{$self->{local_http_collected}->{tables}}) {
        $self->{http_collected}->{tables}->{$name} = {}
            if (!defined($self->{http_collected}->{tables}->{$name}));
        foreach my $instance (keys %{$self->{local_http_collected}->{tables}->{$name}}) {
            $self->{http_collected}->{tables}->{$name}->{$instance} = {}
                if (!defined($self->{http_collected}->{tables}->{$name}->{$instance}));
            $self->{http_collected}->{tables}->{$name}->{$instance} = $self->{local_http_collected}->{tables}->{$name}->{$instance};
        }
    }

    my $builtin = $local_http_cache->get(name => 'builtin');
    foreach my $name (keys %$builtin) {
        $self->add_builtin(name => $name, value => $builtin->{$name});
    }

    my $local_vars = $local_http_cache->get(name => 'local_vars');
    foreach my $name (keys %$local_vars) {
        $self->set_local_variable(name => $name, value => $local_vars->{$name});
    }

    return 1;
}

sub save_local_http_cache {
    my ($self, %options) = @_;

    if (defined($options{local_http_cache})) {
        my $expand = {};
        foreach my $name (keys %{$self->{expand}}) {
            next if ($name =~ /^(builtin|constants)\./);
            $expand->{$name} = $self->{expand}->{$name};
        }
        
        $options{local_http_cache}->write(
            data => {
                http_collected => {
                    tables => $options{local},
                    epoch => time()
                },
                builtin => $self->{builtin},
                local_vars => $expand
            }
        );
    }
}

sub use_http_cache {
    my ($self, %options) = @_;

    return 0 if ($self->is_http_cache_enabled() == 0);

    my $has_cache_file = $self->{http_cache}->read(
        statefile => 'cache_http_collection_' . md5_hex($self->{option_results}->{config}) 
    );
    $self->{http_collected} = $self->{http_cache}->get(name => 'http_collected');
    my $reload = defined($self->{config}->{http}->{cache}->{reload}) && $self->{config}->{http}->{cache}->{reload} =~ /(\d+)/ ? 
        $self->{config}->{http}->{cache}->{reload} : 30;
    return 0 if (
        $has_cache_file == 0 || 
        !defined($self->{http_collected}) || 
        ((time() - $self->{http_collected}->{epoch}) > ($reload * 60))
    );

    return 1;
}

sub save_http_cache {
    my ($self, %options) = @_;

    return 0 if ($self->is_http_cache_enabled() == 0);
    $self->{http_cache}->write(data => { http_collected => $self->{http_collected} });
}

sub collect_http_sampling {
    my ($self, %options) = @_;

    return if ($self->{http_collected}->{sampling} == 0);

    my $has_cache_file = $self->{http_cache}->read(
        statefile => 'cache_http_collection_sampling_' . md5_hex($self->{option_results}->{config})
    );
    my $http_collected_sampling_old = $self->{http_cache}->get(name => 'http_collected_sampling');
    # with cache, we need to load the sampling cache maybe. please a statefile-suffix to get uniq files.
    # sampling with a global cache can be a nonsense
    if (!defined($self->{http_collected_sampling})) {
        $self->{http_collected_sampling} = $http_collected_sampling_old;
    }

    my $delta_time;
    if (defined($http_collected_sampling_old->{epoch})) {
        $delta_time = $self->{http_collected_sampling}->{epoch} - $http_collected_sampling_old->{epoch};
        $delta_time = 1 if ($delta_time <= 0);
    }

    foreach my $tbl_name (keys %{$self->{http_collected_sampling}->{tables}}) {
        foreach my $instance (keys %{$self->{http_collected_sampling}->{tables}->{$tbl_name}}) {
            foreach my $attr (keys %{$self->{http_collected_sampling}->{tables}->{$tbl_name}->{$instance}}) {
                next if (
                    !defined($http_collected_sampling_old->{tables}->{$tbl_name}) ||
                    !defined($http_collected_sampling_old->{tables}->{$tbl_name}->{$instance}) ||
                    !defined($http_collected_sampling_old->{tables}->{$tbl_name}->{$instance}->{$attr}) ||
                    $http_collected_sampling_old->{tables}->{$tbl_name}->{$instance}->{$attr} !~ /\d/
                );
                my $old = $http_collected_sampling_old->{tables}->{$tbl_name}->{$instance}->{$attr};
                my $diff = $self->{http_collected_sampling}->{tables}->{$tbl_name}->{$instance}->{$attr} - $old;
                my $diff_counter = $diff;
                $diff_counter = $self->{http_collected_sampling}->{tables}->{$tbl_name}->{$instance}->{$attr} if ($diff_counter < 0);

                $self->{http_collected}->{tables}->{$tbl_name}->{$instance}->{ $attr . 'Diff' } = $diff;
                $self->{http_collected}->{tables}->{$tbl_name}->{$instance}->{ $attr . 'DiffCounter' } = $diff_counter;
                if (defined($delta_time)) {
                    $self->{http_collected}->{tables}->{$tbl_name}->{$instance}->{ $attr . 'PerSeconds' } = $diff_counter / $delta_time;
                    $self->{http_collected}->{tables}->{$tbl_name}->{$instance}->{ $attr . 'PerMinutes' } = $diff_counter / $delta_time / 60;
                }
            }
        }
    }

    $self->{http_cache}->write(data => { http_collected_sampling => $self->{http_collected_sampling} });
}

sub display_variables {
    my ($self, %options) = @_;

    $self->{output}->output_add(long_msg => '======> variables', debug => 1);
    foreach my $tbl_name (keys %{$self->{http_collected}->{tables}}) {
        my $expr = 'http.tables.' . $tbl_name;
        foreach my $instance (keys %{$self->{http_collected}->{tables}->{$tbl_name}}) {
            foreach my $attr (keys %{$self->{http_collected}->{tables}->{$tbl_name}->{$instance}}) {
                $self->{output}->output_add(
                    long_msg => sprintf(
                        '    %s = %s',
                        $expr . ".[$instance].$attr",
                        $self->{http_collected}->{tables}->{$tbl_name}->{$instance}->{$attr}
                    ),
                    debug => 1
                );
            }
        }
    }
    
    foreach my $name (keys %{$self->{expand}}) {
        $self->{output}->output_add(
            long_msg => sprintf(
                '    %s = %s',
                $name,
                $self->{expand}->{$name}
            ),
            debug => 1
        );
    }
}

sub collect_http {
    my ($self, %options) = @_;

    if (!defined($self->{config}->{http})) {
        $self->{output}->add_option_msg(short_msg => 'please set http config');
        $self->{output}->option_exit();
    }

    $self->add_builtin(name => 'currentTime', value => time());
    # to use substitute_string
    $self->{expand} = $self->set_constants();

    if ($self->use_http_cache() == 0) {
        $self->{http_collected_sampling} = { tables => {}, epoch => time() };
        $self->{http_collected} = { tables => {}, epoch => time(), sampling => 0 };

        $self->collect_http_tables(requests => $self->{config}->{http}->{requests}, level => 1);

        $self->{http_collected}->{sampling} = 1 if (
            scalar(keys(%{$self->{http_collected_sampling}->{tables}})) > 0
        );
        $self->save_http_cache();
    }

    $self->collect_http_sampling();

    # can use local_var set for selection/selection_loop
    $self->{local_vars} = {};
    foreach my $name (keys %{$self->{expand}}) {
        next if ($name =~ /^(builtin|constants)\./);
        $self->{local_vars}->{$name} = $self->{expand}->{$name};
    }

    if ($self->{output}->is_debug()) {
        $self->display_variables();
    }
}

sub exist_table_name {
    my ($self, %options) = @_;

    return 1 if (defined($self->{http_collected}->{tables}->{ $options{name} }));
    return 0;
}

sub get_local_variable {
    my ($self, %options) = @_;

    if (defined( $self->{expand}->{ $options{name} })) {
        return $self->{expand}->{ $options{name} };
    } else {
        $self->{output}->add_option_msg(short_msg => "Key '" . $options{name} . "' not found in ('" . join("', '", keys(%{$self->{expand}})) . "')", debug => 1);
        return undef;
    }


}

sub set_local_variables {
    my ($self, %options) = @_;

    foreach (keys %{$self->{local_vars}}) {
        $self->set_local_variable(name => $_, value => $self->{local_vars}->{$_});
    }
}

sub set_local_variable {
    my ($self, %options) = @_;

    $self->{expand}->{ $options{name} } = $options{value};
}

sub get_table {
    my ($self, %options) = @_;

    if (!defined($self->{http_collected}->{tables}->{ $options{table} })) {
        $self->{output}->add_option_msg(short_msg => "Table '" . $options{table} . "' not found in ('" . join("', '", keys(%{$self->{http_collected}->{tables}})) . "')", debug => 1);
        return undef;
    }
    return $self->{http_collected}->{tables}->{ $options{table} };
}

sub get_table_instance {
    my ($self, %options) = @_;

    if (!defined($self->{http_collected}->{tables}->{ $options{table} })) {
        $self->{output}->add_option_msg(short_msg => "Table '" . $options{table} . "' not found in ('" . join("', '", keys(%{$self->{http_collected}->{tables}})) . "')", debug => 1);
        return undef;
    }
    if (!defined($self->{http_collected}->{tables}->{ $options{table} }->{ $options{instance} })) {
        $self->{output}->add_option_msg(short_msg => "Table '" . $options{instance} . "' not found in ('" . join("', '", keys(%{$self->{http_collected}->{tables}->{ $options{table} }})) . "')", debug => 1);
        return undef;
    }
    return $self->{http_collected}->{tables}->{ $options{table} }->{ $options{instance} };
}

sub get_table_attribute_value {
    my ($self, %options) = @_;

    return undef if (
        !defined($self->{http_collected}->{tables}->{ $options{table} }) ||
        !defined($self->{http_collected}->{tables}->{ $options{table} }->{ $options{instance} }) ||
        !defined($self->{http_collected}->{tables}->{ $options{table} }->{ $options{instance} }->{ $options{attribute} })
    );
    return $self->{http_collected}->{tables}->{ $options{table} }->{ $options{instance} }->{ $options{attribute} };
}

sub set_table_attribute_value {
    my ($self, %options) = @_;

    $self->{http_collected}->{tables}->{ $options{table} } = {}
        if (!defined($self->{http_collected}->{tables}->{ $options{table} }));
    $self->{http_collected}->{tables}->{ $options{table} } = {}
        if (!defined($self->{http_collected}->{tables}->{ $options{table} }->{ $options{instance} }));
    $self->{http_collected}->{tables}->{ $options{table} }->{ $options{instance} }->{ $options{attribute} } = $options{value};
}

sub get_special_variable_value {
    my ($self, %options) = @_;

    my $data;
    if ($options{type} == 0) {
        $data = $self->get_local_variable(name => $options{label});
    } elsif ($options{type} == 2) {
        $data = $self->get_table(table => $options{table});
    } elsif ($options{type} == 4) {
        $data = $self->get_table_attribute_value(
            table => $options{table},
            instance => $options{instance},
            attribute => $options{label}
        );
    }

    return $data;
}

sub set_special_variable_value {
    my ($self, %options) = @_;

    my $data;
    if ($options{type} == 0) {
        $data = $self->set_local_variable(name => $options{label}, value => $options{value});
    } elsif ($options{type} == 4) {
        $data = $self->set_table_attribute_value(
            table => $options{table},
            instance => $options{instance},
            attribute => $options{label},
            value => $options{value}
        );
    }

    return $data;
}

sub strcmp {
    my ($self, %options) = @_;

    my @cmp = split //, $options{test};
    for (my $i = 0; $i < scalar(@cmp); $i++) {
        return 0 if (
            !defined($options{chars}->[ $options{start} + $i ]) ||
            $options{chars}->[ $options{start} + $i ] ne $cmp[$i]
        );
    }

    return 1;
}

sub parse_forward {
    my ($self, %options) = @_;

    my ($string, $i) = ('', 0);
    while (1) {
        return (1, 'cannot find ' . $options{stop} . ' character')
            if (!defined($options{chars}->[ $options{start} + $i ]));
        last if ($options{chars}->[ $options{start} + $i ] =~ /$options{stop}/);
        return (1, "character '" . $options{chars}->[ $options{start} + $i ] . "' forbidden")
            if ($options{chars}->[ $options{start} + $i ] !~ /$options{allowed}/);

        $string .= $options{chars}->[ $options{start} + $i ];
        $i++;
    }

    return (0, undef, $options{start} + $i, $string);
}

=pod
managed variables:
    %(http.tables.centreonTest)
    %(http.tables.centreonTest.[1])
    %(http.tables.centreonTest.[1].plop)
    %(http.tables.centreonTest.[%(mytable.instance)]
    %(http.tables.centreonTest.[%(http.tables.centreonTest.[%(mytable.instance)].name)]
    %(test2)
    %(mytable.test)

result:
    - type:
        0=%(test) (label)
        2=%(http.tables.centreonTest)
        3=%(http.tables.centreonTest.[2])
        4=%(http.tables.centreonTest.[2].attrname)
=cut
sub parse_http_tables {
    my ($self, %options) = @_;

    my ($code, $msg_error, $end, $table_label, $instance_label, $label);
    ($code, $msg_error, $end, $table_label) = $self->parse_forward(
        chars => $options{chars},
        start => $options{start}, 
        allowed => '[a-zA-Z0-9_\-]',
        stop => '[).]'
    );
    if ($code) {
        $self->{output}->add_option_msg(short_msg => $self->{current_section} . " $msg_error");
        $self->{output}->option_exit();
    }
    if (!$self->exist_table_name(name => $table_label)) {
        my @names = keys %{$self->{http_collected}->{tables}};
        $self->{output}->add_option_msg(short_msg => $self->{current_section} . " unknown or empty table '$table_label'. Available tables are (not empty based on your conf) : @names");
        $self->{output}->option_exit();
    }
    if ($options{chars}->[$end] eq ')') {
        return { type => 2, end => $end, table => $table_label };
    }

    # instance part managenent
    if (!defined($options{chars}->[$end + 1]) || $options{chars}->[$end + 1] ne '[') {
        $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable http.tables character '[' mandatory");
        $self->{output}->option_exit();
    }
    if ($self->strcmp(chars => $options{chars}, start => $end + 2, test => '%(')) {
        my $result = $self->parse_special_variable(chars => $options{chars}, start => $end + 2);
        # type allowed: 0,4
        if ($result->{type} !~ /^(?:0|4)$/) {
            $self->{output}->add_option_msg(short_msg => $self->{current_section} . ' special variable type not allowed');
            $self->{output}->option_exit();
        }
        $end = $result->{end} + 1;
        if ($result->{type} == 0) {
            $instance_label = $self->get_local_variable(name => $result->{label});
        } elsif ($result->{type} == 4) {
            $instance_label = $self->get_table_attribute_value(
                table => $result->{table},
                instance => $result->{instance},
                attribute => $result->{label}
            );
        }
        $instance_label = defined($instance_label) ? $instance_label : '';
    } else {
        ($code, $msg_error, $end, $instance_label) = $self->parse_forward(
            chars => $options{chars},
            start => $end + 2, 
            allowed => '[^\]]',
            stop => '[\]]'
        );
        if ($code) {
            $self->{output}->add_option_msg(short_msg => $self->{current_section} . " $msg_error");
            $self->{output}->option_exit();
        }
    }

    if (!defined($options{chars}->[$end + 1]) ||
        $options{chars}->[$end + 1] !~ /[.)]/) {
        $self->{output}->add_option_msg(short_msg => $self->{current_section} . ' special variable http.tables character [.)] missing');
        $self->{output}->option_exit();
    }

    if ($options{chars}->[$end + 1] eq ')') {
        return { type => 3, end => $end + 1, table => $table_label, instance => $instance_label };
    }

    ($code, $msg_error, $end, $label) = $self->parse_forward(
        chars => $options{chars},
        start => $end + 2,
        allowed => '[a-zA-Z0-9_\-]',
        stop => '[)]'
    );
    if ($code) {
        $self->{output}->add_option_msg(short_msg => $self->{current_section} . " $msg_error");
        $self->{output}->option_exit();
    }

    return { type => 4, end => $end, table => $table_label, instance => $instance_label, label => $label };
}

sub parse_http_type {
    my ($self, %options) = @_;

    if ($self->strcmp(chars => $options{chars}, start => $options{start}, test => 'tables.')) {
        return $self->parse_http_tables(chars => $options{chars}, start => $options{start} + 7);
    } else {
        $self->{output}->add_option_msg(short_msg => $self->{current_section} . ' special variable http not followed by tables');
        $self->{output}->option_exit();
    }
}

sub parse_special_variable {
    my ($self, %options) = @_;

    my $start = $options{start};
    if ($options{chars}->[$start] ne '%' || 
        $options{chars}->[$start + 1] ne '(') {
        $self->{output}->add_option_msg(short_msg => $self->{current_section} . ' special variable not starting by %(');
        $self->{output}->option_exit();
    }

    my $result = { start => $options{start} };
    if ($self->strcmp(chars => $options{chars}, start => $start + 2, test => 'http.')) {
        my $parse = $self->parse_http_type(chars => $options{chars}, start => $start + 2 + 5);
        $result = { %$parse, %$result };
    } else {
        my ($code, $msg_error, $end, $label) = $self->parse_forward(
            chars => $options{chars},
            start => $start + 2, 
            allowed => '[a-zA-Z0-9\._\-]',
            stop => '[)]'
        );
        if ($code) {
            $self->{output}->add_option_msg(short_msg => $self->{current_section} . " $msg_error");
            $self->{output}->option_exit();
        }
        $result->{end} = $end;
        $result->{type} = 0;
        $result->{label} = $label;
    }

    return $result;
}

sub substitute_string {
    my ($self, %options) = @_;

    return undef if (!defined($options{value}));

    my $arr = [split //, $options{value}];
    my $results = {};
    my $last_end = -1;
    while ($options{value} =~ /\Q%(\E/g) {
        next if ($-[0] < $last_end);
        my $result = $self->parse_special_variable(chars => $arr, start => $-[0]);
        if ($result->{type} !~ /^(?:0|4)$/) {
            $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed");
            $self->{output}->option_exit();
        }
        $last_end = $result->{end};
        $results->{ $result->{start} } = $result;
    }

    my $end = -1;
    my $str = '';
    for (my $i = 0; $i < scalar(@$arr); $i++) {
        next if ($i <= $end);
        if (defined($results->{$i})) {
            my $data = $self->get_special_variable_value(%{$results->{$i}});
            $end = $results->{$i}->{end};
            $str .= defined($data) ? $data : '';
        } else {
            $str .= $arr->[$i];
        }
    }

    return $str;
}

sub add_builtin {
    my ($self, %options) = @_;

    $self->{builtin}->{ $options{name} } = $options{value};
}

sub set_builtin {
    my ($self, %options) = @_;

    foreach (keys %{$self->{builtin}}) {
        $self->{expand}->{ 'builtin.' . $_ } = $self->{builtin}->{$_};
    }
}

sub create_constants {
    my ($self, %options) = @_;

    $self->{constants} = {};
    if (defined($self->{config}->{constants})) {
        foreach (keys %{$self->{config}->{constants}}) {
            $self->{constants}->{'constants.' . $_} = $self->{config}->{constants}->{$_};
        }
    }
    foreach (keys %{$self->{option_results}->{constant}}) {
        $self->{constants}->{'constants.' . $_} = $self->{option_results}->{constant}->{$_};
    }
}

sub set_constants {
    my ($self, %options) = @_;

    return { %{$self->{constants}} };
}

sub set_expand_table {
    my ($self, %options) = @_;

    return if (!defined($options{expand}));
    foreach my $name (keys %{$options{expand}}) {
        $self->{current_section} = '[' . $options{section} . ' > ' . $name . ']';
        my $result = $self->parse_special_variable(chars => [split //, $options{expand}->{$name}], start => 0);
        if ($result->{type} != 3) {
            $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed");
            $self->{output}->option_exit();
        }
        my $table = $self->get_table_instance(table => $result->{table}, instance => $result->{instance});
        next if (!defined($table));

        $self->{expand}->{ $name . '.instance' } = $result->{instance};
        foreach (keys %$table) {
            $self->{expand}->{ $name . '.' . $_ } = $table->{$_};
        }
    }
}

sub set_expand {
    my ($self, %options) = @_;

    return if (!defined($options{expand}));
    foreach my $name (keys %{$options{expand}}) {
        $self->{current_section} = '[' . $options{section} . ' > ' . $name . ']';
        $self->{expand}->{$name} = $self->substitute_string(value => $options{expand}->{$name});
    }
}

sub exec_func_map {
    my ($self, %options) = @_;

    if (!defined($options{map_name}) || $options{map_name} eq '') {
        $self->{output}->add_option_msg(short_msg => "$self->{current_section} please set map_name attribute");
        $self->{output}->option_exit();
    }
    if (!defined($options{src}) || $options{src} eq '') {
        $self->{output}->add_option_msg(short_msg => "$self->{current_section} please set src attribute");
        $self->{output}->option_exit();
    }

    my $result = $self->parse_special_variable(chars => [split //, $options{src}], start => 0);
    if ($result->{type} !~ /^(?:0|1|4)$/) {
        $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in src attribute");
        $self->{output}->option_exit();
    }
    my $data = $self->get_special_variable_value(%$result);
    my $value = $self->get_map_value(value => $data, map => $options{map_name});
    if (!defined($value)) {
        $self->{output}->add_option_msg(short_msg => "$self->{current_section} unknown map attribute: $options{map_name}");
        $self->{output}->option_exit();
    }
    my $save = $result;
    if (defined($options{save}) && $options{save} ne '') {
        $save = $self->parse_special_variable(chars => [split //, $options{save}], start => 0);
        if ($save->{type} !~ /^(?:0|1|4)$/) {
            $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in save attribute");
            $self->{output}->option_exit();
        }
    } elsif (defined($options{dst}) && $options{dst} ne '') {
        $save = $self->parse_special_variable(chars => [split //, $options{dst}], start => 0);
        if ($save->{type} !~ /^(?:0|1|4)$/) {
            $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in dst attribute");
            $self->{output}->option_exit();
        }
    }

    $self->set_special_variable_value(value => $value, %$save);
}

sub scale {
    my ($self, %options) = @_;

    my ($src_quantity, $src_unit) = (undef, 'B');
    if ($options{src_unit} =~ /([kmgtpe])?(b)/i) {
        $src_quantity = $1;
        $src_unit = $2;
    }
    my ($dst_quantity, $dst_unit) = ('auto', $src_unit);
    if ($options{dst_unit} =~ /([kmgtpe])?(b)/i) {
        $dst_quantity = $1;
        $dst_unit = $2;
    }

    my $base = 1024;
    $options{value} *= 8 if ($dst_unit eq 'b' && $src_unit eq 'B');
    $options{value} /= 8 if ($dst_unit eq 'B' && $src_unit eq 'b');
    $base = 1000 if ($dst_unit eq 'b');

    my %expo = (k => 1, m => 2, g => 3, t => 4, p => 5, e => 6);
    my $src_expo = 0;
    $src_expo = $expo{ lc($src_quantity) } if (defined($src_quantity));

    if (defined($dst_quantity) && $dst_quantity eq 'auto') {
        my @auto = ('', 'k', 'm', 'g', 't', 'p', 'e');
        for (; $src_expo < scalar(@auto); $src_expo++) {
            last if ($options{value} < $base);
            $options{value} = $options{value} / $base;
        }

        return ($options{value}, uc($auto[$src_expo]) . $dst_unit);
    }

    my $dst_expo = 0;
    $dst_expo = $expo{ lc($dst_quantity) } if (defined($dst_quantity));
    if ($dst_expo - $src_expo > 0) {
        $options{value} = $options{value} / ($base ** ($dst_expo - $src_expo));
    } elsif ($dst_expo - $src_expo < 0) {
        $options{value} = $options{value} * ($base ** (($dst_expo - $src_expo) * -1));
    }

    return ($options{value}, $options{dst_unit});
}

sub exec_func_scale {
    my ($self, %options) = @_;

    #{
    #    "type": "scale",
    #    "src": "%(memoryUsed)",
    #    "src_unit": "KB", (default: 'B')
    #    "dst_unit": "auto", (default: 'auto')
    #    "save_value": "%(memoryUsedScaled)",
    #    "save_unit": "%(memoryUsedUnit)"
    #}
    if (!defined($options{src}) || $options{src} eq '') {
        $self->{output}->add_option_msg(short_msg => "$self->{current_section} please set src attribute");
        $self->{output}->option_exit();
    }

    my $result = $self->parse_special_variable(chars => [split //, $options{src}], start => 0);
    if ($result->{type} !~ /^(?:0|4)$/) {
        $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in src attribute");
        $self->{output}->option_exit();
    }
    my $data = $self->get_special_variable_value(%$result);
    my ($save_value, $save_unit) = $self->scale(
        value => $data,
        src_unit => $options{src_unit},
        dst_unit => $options{dst_unit}
    );

    if (defined($options{save_value}) && $options{save_value} ne '') {
        my $var_save_value = $self->parse_special_variable(chars => [split //, $options{save_value}], start => 0);
        if ($var_save_value->{type} !~ /^(?:0|4)$/) {
            $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in save_value attribute");
            $self->{output}->option_exit();
        }
        $self->set_special_variable_value(value => $save_value, %$var_save_value);
    }
    if (defined($options{save_unit}) && $options{save_unit} ne '') {
        my $var_save_unit = $self->parse_special_variable(chars => [split //, $options{save_unit}], start => 0);
        if ($var_save_unit->{type} !~ /^(?:0|4)$/) {
            $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in save_value attribute");
            $self->{output}->option_exit();
        }
        $self->set_special_variable_value(value => $save_unit, %$var_save_unit);
    }
}

sub exec_func_second2human {
    my ($self, %options) = @_;

    #{
    #    "type": "second2human",
    #    "src": "%(duration)",
    #    "save_value": "%(humanDuration)",
    #    "start": "d",
    #}
    if (!defined($options{src}) || $options{src} eq '') {
        $self->{output}->add_option_msg(short_msg => "$self->{current_section} please set src attribute");
        $self->{output}->option_exit();
    }

    my $result = $self->parse_special_variable(chars => [split //, $options{src}], start => 0);
    if ($result->{type} !~ /^(?:0|4)$/) {
        $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in src attribute");
        $self->{output}->option_exit();
    }
    my $data = $self->get_special_variable_value(%$result);
    my ($str, $str_append) = ('', '');
    my $periods = [
        { unit => 'y', value => 31556926 },
        { unit => 'M', value => 2629743 },
        { unit => 'w', value => 604800 },
        { unit => 'd', value => 86400 },
        { unit => 'h', value => 3600 },
        { unit => 'm', value => 60 },
        { unit => 's', value => 1 },
    ];
    my %values = ('y' => 1, 'M' => 2, 'w' => 3, 'd' => 4, 'h' => 5, 'm' => 6, 's' => 7);
    my $sign = '';
    if ($data < 0) {
        $sign = '-';
        $data = abs($data);
    }
    
    foreach (@$periods) {
        next if (defined($options{start}) && $values{$_->{unit}} < $values{$options{start}});
        my $count = int($data / $_->{value});

        next if ($count == 0);
        $str .= $str_append . $count . $_->{unit};
        $data = $data % $_->{value};
        $str_append = ' ';
    }

    if ($str eq '') {
        $str = $data;
        $str .= $options{start} if (defined($options{start}));
    }

    if (defined($options{save_value}) && $options{save_value} ne '') {
        my $var_save_value = $self->parse_special_variable(chars => [split //, $options{save_value}], start => 0);
        if ($var_save_value->{type} !~ /^(?:0|4)$/) {
            $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in save_value attribute");
            $self->{output}->option_exit();
        }
        $self->set_special_variable_value(value => $sign . $str, %$var_save_value);
    }
}

sub exec_func_date2epoch {
    my ($self, %options) = @_;

    if (!defined($self->{module_datetime_loaded})) {
        centreon::plugins::misc::mymodule_load(
            module => 'DateTime',
            error_msg => "Cannot load module 'DateTime'."
        );
        $self->{module_datetime_loaded} = 1;
    }

    #{
    #   "type": "date2epoch",
    #   "src": "%(dateTest2)",
    #   "format_custom": "(\\d+)-(\\d+)-(\\d+)",
    #   "year": 1,
    #   "month": 2,
    #   "day": 3,
    #   "timezone": "Europe/Paris",
    #   "save_epoch": "%(plopDateEpoch)",
    #   "save_diff1": "%(plopDateDiff1)",
    #   "save_diff2": "%(plopDateDiff2)"
    #}
    if (!defined($options{src}) || $options{src} eq '') {
        $self->{output}->add_option_msg(short_msg => "$self->{current_section} please set src attribute");
        $self->{output}->option_exit();
    }
    my $result = $self->parse_special_variable(chars => [split //, $options{src}], start => 0);
    if ($result->{type} !~ /^(?:0|1|4)$/) {
        $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in src attribute");
        $self->{output}->option_exit();
    }
    my $data = $self->get_special_variable_value(%$result);

    my $tz = {};
    $tz->{time_zone} = $options{timezone} if (defined($options{timezone}) && $options{timezone} ne '');
    my $dt;
    if (defined($options{format_custom}) && $options{format_custom} ne '') {
        my @matches = ($data =~ /$options{format_custom}/);
        my $date = {};
        foreach (('year', 'month', 'day', 'hour', 'minute', 'second')) {
            $date->{$_} = $matches[ $options{$_} -1 ]
                if (defined($options{$_}) && $options{$_} =~ /^\d+$/ && defined($matches[ $options{$_} -1 ]));
        }

        foreach (('year', 'month', 'day')) {
            if (!defined($date->{$_})) {
                $self->{output}->add_option_msg(short_msg => "$self->{current_section} cannot find $_ attribute");
                $self->{output}->option_exit();
            }
        }
        $dt = DateTime->new(%$date, %$tz);
    } else {
        $self->{output}->add_option_msg(short_msg => "$self->{current_section} please set format_custom attribute");
        $self->{output}->option_exit();
    }

    my $results = {
        epoch => $dt->epoch(),
        diff1 => time() - $dt->epoch(),
        diff2 => $dt->epoch() - time()
    };
    foreach (keys %$results) {
        my $attr = '%(' . $result->{label} . ucfirst($_) . ')';
        $attr = $options{'save_' . $_}
            if (defined($options{'save_' . $_}) && $options{'save_' . $_} ne '');
        my $var_save_value = $self->parse_special_variable(chars => [split //, $attr], start => 0);
        if ($var_save_value->{type} !~ /^(?:0|4)$/) {
            $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in save_$_ attribute");
            $self->{output}->option_exit();
        }
        $self->set_special_variable_value(value => $results->{$_}, %$var_save_value);
    }
}

sub exec_func_epoch2date {
    my ($self, %options) = @_;

    if (!defined($self->{module_datetime_loaded})) {
        centreon::plugins::misc::mymodule_load(
            module => 'DateTime',
            error_msg => "Cannot load module 'DateTime'."
        );
        $self->{module_datetime_loaded} = 1;
    }

    #{
    #   "type": "epoch2date",
    #   "src": "%(dateTestEpoch)",
    #   "format": "%a %b %e %H:%M:%S %Y",
    #   "timezone": "Asia/Tokyo",
    #   "locale": "fr",
    #   "save": "%(dateTestReformat)"
    #}
    if (!defined($options{src}) || $options{src} eq '') {
        $self->{output}->add_option_msg(short_msg => "$self->{current_section} please set src attribute");
        $self->{output}->option_exit();
    }
    my $result = $self->parse_special_variable(chars => [split //, $options{src}], start => 0);
    if ($result->{type} !~ /^(?:0|4)$/) {
        $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in src attribute");
        $self->{output}->option_exit();
    }
    my $data = $self->get_special_variable_value(%$result);

    my $extras = {};
    $extras->{time_zone} = $options{timezone} if (defined($options{timezone}) && $options{timezone} ne '');
    $extras->{locale} = $options{locale} if (defined($options{locale}) && $options{locale} ne '');
    my $dt = DateTime->from_epoch(
        epoch => $data,
        %$extras
    );
    my $time_value = $dt->strftime($options{format});

    if (defined($options{save}) && $options{save} ne '') {
        my $var_save_value = $self->parse_special_variable(chars => [split //, $options{save}], start => 0);
        if ($var_save_value->{type} !~ /^(?:0|4)$/) {
            $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in save attribute");
            $self->{output}->option_exit();
        }
        $self->set_special_variable_value(value => $time_value, %$var_save_value);
    }
}

sub exec_func_count {
    my ($self, %options) = @_;

    #{
    #   "type": "count",
    #   "src": "%(http.tables.test)",
    #   "save": "%(testCount)"
    #}
    if (!defined($options{src}) || $options{src} eq '') {
        $self->{output}->add_option_msg(short_msg => "$self->{current_section} please set src attribute");
        $self->{output}->option_exit();
    }

    my $result = $self->parse_special_variable(chars => [split //, $options{src}], start => 0);
    if ($result->{type} !~ /^2$/) {
        $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in src attribute");
        $self->{output}->option_exit();
    }
    my $data = $self->get_special_variable_value(%$result);
    my $value = 0;
    if (defined($data)) {
        if (defined($options{filter}) && $options{filter} ne '') {
            my $count = 0;
            foreach my $instance (keys %$data) {
                my $values = $self->{expand};
                foreach my $label (keys %{$data->{$instance}}) {
                    $values->{'src.' . $label} = $data->{$instance}->{$label};
                }
                $count++ unless ($self->check_filter(filter => $options{filter}, values => $values));
            }
            $value = $count;
        } else {
            $value = scalar(keys %$data);
        }
    }

    if (defined($options{save}) && $options{save} ne '') {
        my $save = $self->parse_special_variable(chars => [split //, $options{save}], start => 0);
        if ($save->{type} !~ /^(?:0|4)$/) {
            $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in save attribute");
            $self->{output}->option_exit();
        }
        $self->set_special_variable_value(value => $value, %$save);
    }
}

sub exec_func_replace {
    my ($self, %options) = @_;

    #{
    #   "type": "replace",
    #   "src": "%(http.tables.test)",
    #   "expression": "s/name/name is/"
    #}
    if (!defined($options{src}) || $options{src} eq '') {
        $self->{output}->add_option_msg(short_msg => "$self->{current_section} please set src attribute");
        $self->{output}->option_exit();
    }
    if (!defined($options{expression}) || $options{expression} eq '') {
        $self->{output}->add_option_msg(short_msg => "$self->{current_section} please set expression attribute");
        $self->{output}->option_exit();
    }

    my $result = $self->parse_special_variable(chars => [split //, $options{src}], start => 0);
    if ($result->{type} !~ /^(?:0|4)$/) {
        $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in src attribute");
        $self->{output}->option_exit();
    }
    my $data = $self->get_special_variable_value(%$result);

    if (defined($data)) {
        my $expression = $self->substitute_string(value => $options{expression});
        our $assign_var = $data;
        $self->{safe_func}->reval("\$assign_var =~ $expression", 1);
        if ($@) {
            die 'Unsafe code evaluation: ' . $@;
        }
        $self->set_special_variable_value(value => $assign_var, %$result);
    }
}

sub exec_func_assign {
    my ($self, %options) = @_;

    #{
    #   "type": "assign",
    #   "save": "%(http.tables.test)",
    #   "expression": "'%(http.tables.test)' . 'toto'"
    #}
    if (!defined($options{save}) || $options{save} eq '') {
        $self->{output}->add_option_msg(short_msg => "$self->{current_section} please set save attribute");
        $self->{output}->option_exit();
    }
    if (!defined($options{expression}) || $options{expression} eq '') {
        $self->{output}->add_option_msg(short_msg => "$self->{current_section} please set expression attribute");
        $self->{output}->option_exit();
    }

    my $result = $self->parse_special_variable(chars => [split //, $options{save}], start => 0);
    if ($result->{type} !~ /^(?:0|4)$/) {
        $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in src attribute");
        $self->{output}->option_exit();
    }

    my $expression = $self->substitute_string(value => $options{expression});
    our $assign_var;
    $self->{safe_func}->reval("\$assign_var = $expression", 1);
    if ($@) {
        die 'Unsafe code evaluation: ' . $@;
    }
    $self->set_special_variable_value(value => $assign_var, %$result);
}

sub exec_func_capture {
    my ($self, %options) = @_;

    #{
    #    "type": "capture",
    #    "src": "%(snmp.leefs.content)",
    #    "pattern": "(?msi)Vertical BER Analysis.*?Bit Error Rate: (\S+)",
    #    "groups": [
    #        { "offset": 1, "save": "%(bitErrorRate)" }
    #    ]
    #}
    if (!defined($options{src}) || $options{src} eq '') {
        $self->{output}->add_option_msg(short_msg => "$self->{current_section} please set src attribute");
        $self->{output}->option_exit();
    }
    if (!defined($options{pattern}) || $options{pattern} eq '') {
        $self->{output}->add_option_msg(short_msg => "$self->{current_section} please set pattern attribute");
        $self->{output}->option_exit();
    }
    if (!defined($options{groups}) || ref($options{groups}) ne 'ARRAY') {
        $self->{output}->add_option_msg(short_msg => "$self->{current_section} please set groups attribute");
        $self->{output}->option_exit();
    }

    my $result = $self->parse_special_variable(chars => [split //, $options{src}], start => 0);
    if ($result->{type} !~ /^(?:0|4)$/) {
        $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in src attribute");
        $self->{output}->option_exit();
    } 
    my $data = $self->get_special_variable_value(%$result);

    my @matches = ($data =~ /$options{pattern}/);

    foreach (@{$options{groups}}) {
        next if ($_->{offset} !~ /^[0-9]+/);

        my $value = '';
        if (defined($matches[ $_->{offset} ])) {
            $value = $matches[ $_->{offset} ];
        }

        my $save = $self->parse_special_variable(chars => [split //, $_->{save}], start => 0);
        if ($save->{type} !~ /^(?:0|4)$/) {
            $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in save attribute");
            $self->{output}->option_exit();
        }

        $self->set_special_variable_value(value => $value, %$save);
    }
}

sub exec_func_scientific2number {
    my ($self, %options) = @_;

    #{
    #    "type": "scientific2number",
    #    "src": "%(bitErrorRate)",
    #    "save": "%(bitErrorRate)",
    #}
    if (!defined($options{src}) || $options{src} eq '') {
        $self->{output}->add_option_msg(short_msg => "$self->{current_section} please set src attribute");
        $self->{output}->option_exit();
    }
    my $result = $self->parse_special_variable(chars => [split //, $options{src}], start => 0);
    if ($result->{type} !~ /^(?:0|4)$/) {
        $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in src attribute");
        $self->{output}->option_exit();
    } 
    my $data = $self->get_special_variable_value(%$result);

    $data = centreon::plugins::misc::expand_exponential(value => $data);

    if (defined($options{save}) && $options{save} ne '') {
        my $save = $self->parse_special_variable(chars => [split //, $options{save}], start => 0);
        if ($save->{type} !~ /^(?:0|4)$/) {
            $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in save attribute");
            $self->{output}->option_exit();
        }
        $self->set_special_variable_value(value => $data, %$save);
    }
}

sub set_functions {
    my ($self, %options) = @_;

    return if (!defined($options{functions}));
    my $i = -1;
    foreach (@{$options{functions}}) {
        $i++;
        $self->{current_section} = '[' . $options{section} . ' > ' . $i . ']';
        next if (defined($_->{position}) && $options{position} ne $_->{position});
        next if (!defined($_->{position}) && !(defined($options{default}) && $options{default} == 1));

        next if (!defined($_->{type}));

        if ($_->{type} eq 'map') {
            $self->exec_func_map(%$_);
        } elsif ($_->{type} eq 'scale') {
            $self->exec_func_scale(%$_);
        } elsif ($_->{type} eq 'second2human') {
            $self->exec_func_second2human(%$_);
        } elsif (lc($_->{type}) eq 'date2epoch') {
            $self->exec_func_date2epoch(%$_);
        } elsif (lc($_->{type}) eq 'epoch2date') {
            $self->exec_func_epoch2date(%$_);
        } elsif (lc($_->{type}) eq 'count') {
            $self->exec_func_count(%$_);
        } elsif (lc($_->{type}) eq 'replace') {
            $self->exec_func_replace(%$_);
        } elsif (lc($_->{type}) eq 'assign') {
            $self->exec_func_assign(%$_);
        } elsif (lc($_->{type}) eq 'capture') {
            $self->exec_func_capture(%$_);
        } elsif (lc($_->{type}) eq 'scientific2number') {
            $self->exec_func_scientific2number(%$_);
        }
    }
}

sub prepare_variables {
    my ($self, %options) = @_;

    return undef if (!defined($options{value}));

    while ($options{value} =~ /%\(([a-zA-Z0-9\.\-]+?)\)/g) {
        next if ($1 =~ /^http\./);
        $options{value} =~ s/%\(($1)\)/\$expand->{'$1'}/g;
    }

    my $expression = $self->substitute_string(value => $options{value});
    return $expression;
}

sub check_filter {
    my ($self, %options) = @_;

    return 0 if (!defined($options{filter}) || $options{filter} eq '');
    our $expand = $options{values};
    $options{filter} =~ s/%\(([a-zA-Z0-9\._:\-]+?)\)/\$expand->{'$1'}/g;
    my $result = $self->{safe}->reval("$options{filter}");
    if ($@) {
        $self->{output}->add_option_msg(short_msg => 'Unsafe code evaluation: ' . $@);
        $self->{output}->option_exit();
    }
    return 0 if ($result);

    return 1;
}

sub check_filter2 {
    my ($self, %options) = @_;

    return 0 if (!defined($options{filter}) || $options{filter} eq '');
    our $expand = $options{values};
    $options{filter} =~ s/%\(([a-zA-Z0-9\._:\-]+?)\)/\$expand->{'$1'}/g;
    my $result = $self->{safe}->reval("$options{filter}");
    if ($@) {
        $self->{output}->add_option_msg(short_msg => 'Unsafe code evaluation: ' . $@);
        $self->{output}->option_exit();
    }
    return 1 if ($result);

    return 0;
}

sub check_filter_option {
    my ($self, %options) = @_;
    foreach (keys %{$self->{option_results}->{filter_selection}}) {

        if(!defined($self->{expand}->{$_}) && grep {/^src\./} keys(%{$self->{expand}}) ne '') {
            $self->{output}->add_option_msg(long_msg => "Wrong filter-selection - Available attributes for filtering: " . join(", ", grep {/^src\./} keys(%{$self->{expand}})), debug => 1);
        }

        return 1 if (
            defined($self->{expand}->{$_}) && $self->{option_results}->{filter_selection}->{$_} ne '' &&
            $self->{expand}->{$_} !~ /$self->{option_results}->{filter_selection}->{$_}/
        );
    }

    return 0;
}

sub prepare_perfdatas {
    my ($self, %options) = @_;

    return undef if (!defined($options{perfdatas}));
    my $perfdatas = [];
    foreach (@{$options{perfdatas}}) {
        next if (!defined($_->{nlabel}) || $_->{nlabel} eq '');
        next if (!defined($_->{value}) || $_->{value} eq '');
        my $perf = {};
        $perf->{nlabel} = $self->substitute_string(value => $_->{nlabel});
        $perf->{value} = $self->substitute_string(value => $_->{value});
        foreach my $label (('warning', 'critical', 'min', 'max', 'unit')) {
            next if (!defined($_->{$label}));
            $perf->{$label} = $self->substitute_string(value => $_->{$label});
        }
        if (defined($_->{instances})) {
            $perf->{instances} = [];
            foreach my $instance (@{$_->{instances}}) {
                push @{$perf->{instances}}, $self->substitute_string(value => $instance);
            }
        }
        push @$perfdatas, $perf;
    }

    return $perfdatas;
}

sub prepare_formatting {
    my ($self, %options) = @_;

    return undef if (!defined($options{formatting}));
    my $format = {};
    $format->{printf_msg} = $options{formatting}->{printf_msg};
    $format->{display_ok} = $options{formatting}->{display_ok};
    if (defined($options{formatting}->{printf_var})) {
        $format->{printf_var} = [];
        foreach my $var (@{$options{formatting}->{printf_var}}) {
            push @{$format->{printf_var}}, $self->substitute_string(value => $var);
        }
    }

    return $format
}

sub add_selection {
    my ($self, %options) = @_;

    return if (!defined($self->{config}->{selection}));

    my $i = -1;
    foreach (@{$self->{config}->{selection}}) {
        $i++;
        my $config = {};
        $self->{expand} = $self->set_constants();
        $self->set_builtin();
        $self->set_local_variables();
        $self->{expand}->{name} = $_->{name} if (defined($_->{name}));
        $self->set_functions(section => "selection > $i > functions", functions => $_->{functions}, position => 'before_expand');
        $self->set_expand_table(section => "selection > $i > expand_table", expand => $_->{expand_table});
        $self->set_expand(section => "selection > $i > expand", expand => $_->{expand});
        $self->set_functions(section => "selection > $i > functions", functions => $_->{functions}, position => 'after_expand', default => 1);
        next if ($self->check_filter(filter => $_->{filter}, values => $self->{expand}));
        next if ($self->check_filter_option());
        $config->{unknown} = $self->prepare_variables(section => "selection > $i > unknown", value => $_->{unknown});
        $config->{warning} = $self->prepare_variables(section => "selection > $i > warning", value => $_->{warning});
        $config->{critical} = $self->prepare_variables(section => "selection > $i > critical", value => $_->{critical});
        $config->{perfdatas} = $self->prepare_perfdatas(section => "selection > $i > perfdatas", perfdatas => $_->{perfdatas});
        $config->{formatting} = $self->prepare_formatting(section => "selection > $i > formatting", formatting => $_->{formatting});
        $config->{formatting_unknown} = $self->prepare_formatting(section => "selection > $i > formatting_unknown", formatting => $_->{formatting_unknown});
        $config->{formatting_warning} = $self->prepare_formatting(section => "selection > $i > formatting_warning", formatting => $_->{formatting_warning});
        $config->{formatting_critical} = $self->prepare_formatting(section => "selection > $i > formatting_critical", formatting => $_->{formatting_critical});
        $self->{selections}->{'s' . $i} = { expand => $self->{expand}, config => $config };

        if ($self->check_filter2(filter => $_->{exit}, values => $self->{expand})) {
            $self->{exit_selection} = 1;
            return ;
        }
    }
}

sub add_selection_loop {
    my ($self, %options) = @_;

    return if (!defined($self->{config}->{selection_loop}));

    return if (defined($self->{exit_selection}) && $self->{exit_selection} == 1);

    my $i = -1;
    foreach (@{$self->{config}->{selection_loop}}) {
        $i++;

        next if (!defined($_->{source}) || $_->{source} eq '');
        $self->{current_section} = '[selection_loop > ' . $i . ' > source]';

        my $result = $self->parse_special_variable(chars => [split //, $_->{source}], start => 0);
        if ($result->{type} != 2) {
            $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed");
            $self->{output}->option_exit();
        }

        next if (!defined($self->{http_collected}->{tables}->{ $result->{table} }));

        foreach my $instance (keys %{$self->{http_collected}->{tables}->{ $result->{table} }}) {
            $self->{expand} = $self->set_constants();
            $self->set_builtin();
            $self->set_local_variables();
            $self->{expand}->{ $result->{table} . '.instance' } = $instance;

            foreach my $label (keys %{$self->{http_collected}->{tables}->{ $result->{table} }->{$instance}}) {
                $self->{expand}->{ $result->{table} . '.' . $label } =
                    $self->{http_collected}->{tables}->{ $result->{table} }->{$instance}->{$label};
            }

            my $config = {};
            $self->{expand}->{name} = $_->{name} if (defined($_->{name}));
            $self->set_functions(section => "selection_loop > $i > functions", functions => $_->{functions}, position => 'before_expand');
            $self->set_expand_table(section => "selection_loop > $i > expand_table", expand => $_->{expand_table});
            $self->set_expand(section => "selection_loop > $i > expand", expand => $_->{expand});
            $self->set_functions(section => "selection_loop > $i > functions", functions => $_->{functions}, position => 'after_expand', default => 1);
            next if ($self->check_filter(filter => $_->{filter}, values => $self->{expand}));
            next if ($self->check_filter_option());
            $config->{unknown} = $self->prepare_variables(section => "selection_loop > $i > unknown", value => $_->{unknown});
            $config->{warning} = $self->prepare_variables(section => "selection_loop > $i > warning", value => $_->{warning});
            $config->{critical} = $self->prepare_variables(section => "selection_loop > $i > critical", value => $_->{critical});
            $config->{perfdatas} = $self->prepare_perfdatas(section => "selection_loop > $i > perfdatas", perfdatas => $_->{perfdatas});
            $config->{formatting} = $self->prepare_formatting(section => "selection_loop > $i > formatting", formatting => $_->{formatting});
            $config->{formatting_unknown} = $self->prepare_formatting(section => "selection_loop > $i > formatting_unknown", formatting => $_->{formatting_unknown});
            $config->{formatting_warning} = $self->prepare_formatting(section => "selection_loop > $i > formatting_warning", formatting => $_->{formatting_warning});
            $config->{formatting_critical} = $self->prepare_formatting(section => "selection_loop > $i > formatting_critical", formatting => $_->{formatting_critical});
            $self->{selections}->{'s' . $i . '-' . $instance} = { expand => $self->{expand}, config => $config };

            if ($self->check_filter2(filter => $_->{exit}, values => $self->{expand})) {
                $self->{exit_selection} = 1;
                return ;
            }
        }
    }
}

sub set_formatting {
    my ($self, %options) = @_;

    return if (!defined($self->{config}->{formatting}));
    if (defined($self->{config}->{formatting}->{custom_message_global})) {
        $self->{maps_counters_type}->[0]->{message_multiple} = $self->{config}->{formatting}->{custom_message_global};
    }
    if (defined($self->{config}->{formatting}->{separator})) {
        $self->{maps_counters_type}->[0]->{message_separator} = $self->{config}->{formatting}->{separator};
    }
}


sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['name']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->read_config();
    $self->create_constants();
    $self->collect_http();

    $self->{selections} = {};
    $self->add_selection();
    $self->add_selection_loop();
    foreach (values %{$self->{selections}}) {
        my $entry = {};
        foreach my $label (keys %{$_->{expand}}) {
            next if ($label =~ /^(?:constants|builtin)\./);
            my $name = $label;
            $name =~ s/\./_/g;
            $entry->{$name} = defined($_->{expand}->{$label}) ? $_->{expand}->{$label} : '';
        }
        $self->{output}->add_disco_entry(%$entry);
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->read_config();
    $self->create_constants();
    $self->collect_http();

    $self->{selections} = {};
    $self->add_selection();
    $self->add_selection_loop();
    $self->set_formatting();
}

1;

__END__

=head1 MODE

Collect and compute HTTP data.

=over 8

=item B<--config>

config used (required).
Can be a file or json content.

=item B<--filter-selection>

Filter selections.
Example: --filter-selection='name=test'

=item B<--constant>

Add a constant.
Example: --constant='warning=30' --constant='critical=45'

=back

=cut
