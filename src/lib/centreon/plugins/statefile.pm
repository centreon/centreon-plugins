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

package centreon::plugins::statefile;

use strict;
use warnings;
use Data::Dumper;
use centreon::plugins::misc;

my $default_dir = '/var/lib/centreon/centplugins';
if ($^O eq 'MSWin32') {
    $default_dir = 'C:/Windows/Temp';
}

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (defined($options{options})) {
        $options{options}->add_options(arguments => {
            'memcached:s'          => { name => 'memcached' },
            'redis-server:s'       => { name => 'redis_server' },
            'redis-attribute:s%'   => { name => 'redis_attribute' },
            'redis-db:s'           => { name => 'redis_db' },
            'memexpiration:s'      => { name => 'memexpiration', default => 86400 },
            'statefile-dir:s'      => { name => 'statefile_dir', default => $default_dir },
            'statefile-suffix:s'   => { name => 'statefile_suffix', default => '' },
            'statefile-concat-cwd' => { name => 'statefile_concat_cwd' },
            'statefile-storable'   => { name => 'statefile_storable' }, # legacy
            'failback-file'        => { name => 'failback_file' },
            'statefile-format:s'   => { name => 'statefile_format' },
            'statefile-key:s'      => { name => 'statefile_key' },
            'statefile-cipher:s'   => { name => 'statefile_cipher' }
        });
        $options{options}->add_help(package => __PACKAGE__, sections => 'RETENTION OPTIONS', once => 1);
    }

    $self->{error} = 0;
    $self->{output} = $options{output};
    $self->{datas} = {};
    $self->{storable} = 0;
    $self->{memcached_ok} = 0;
    $self->{memcached} = undef;

    $self->{statefile_dir} = undef;
    $self->{statefile_suffix} = undef;

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    if (defined($options{option_results}) && defined($options{option_results}->{memcached})) {
        centreon::plugins::misc::mymodule_load(
            output => $self->{output},
            module => 'Memcached::libmemcached',
            error_msg => "Cannot load module 'Memcached::libmemcached'."
        );
        $self->{memcached} = Memcached::libmemcached->new();
        Memcached::libmemcached::memcached_server_add($self->{memcached}, $options{option_results}->{memcached});
    }

    # Check redis
    if (defined($options{option_results}->{redis_server})) {
        $self->{redis_attributes} = '';
        if (defined($options{option_results}->{redis_attribute})) {
            foreach (keys %{$options{option_results}->{redis_attribute}}) {
                $self->{redis_attributes} .= "$_ => " . $options{option_results}->{redis_attribute}->{$_} . ', ';
            }
        }

        centreon::plugins::misc::mymodule_load(
            output => $self->{output},
            module => 'Redis',
            error_msg => "Cannot load module 'Redis'."
        );
        eval {
            $options{option_results}->{redis_server} .= ':6379' if ($options{option_results}->{redis_server} !~ /:\d+$/);
            $self->{redis_cnx} = Redis->new(
                server => $options{option_results}->{redis_server}, 
                eval $self->{redis_attributes}
            );
            if (defined($self->{redis_cnx}) && 
                defined($options{option_results}->{redis_db}) &&
                $options{option_results}->{redis_db} ne ''
                ) {
                $self->{redis_cnx}->select($options{option_results}->{redis_db});
            }
        };
        if (!defined($self->{redis_cnx}) && !defined($options{option_results}->{failback_file})) {
            $self->{output}->add_option_msg(short_msg => "redis connection issue: $@");
            $self->{output}->option_exit();
        }
    }

    $self->{statefile_format} = 'json';
    if (defined($options{option_results}->{statefile_format}) && $options{option_results}->{statefile_format} ne '' && 
        $options{option_results}->{statefile_format} =~ /^(?:dumper|json|storable)$/) {
        $self->{statefile_format} = $options{option_results}->{statefile_format};
    } elsif (defined($options{default_format}) && $options{default_format} =~ /^(?:dumper|json|storable)$/) {
        $self->{statefile_format} = $options{default_format};
    }

    if (defined($options{option_results}->{statefile_storable})) {
        $self->{statefile_format} = 'storable';
    }

    if ($self->{statefile_format} eq 'dumper') {
        centreon::plugins::misc::mymodule_load(
            output => $self->{output}, module => 'Safe', 
            no_quit => 1
        );
        $self->{safe} = Safe->new();
        $self->{safe}->share('$datas');
    } elsif ($self->{statefile_format} eq 'storable') {
        centreon::plugins::misc::mymodule_load(
            output => $self->{output},
            module => 'Storable',
            error_msg => "Cannot load module 'Storable'."
        );
    } elsif ($self->{statefile_format} eq 'json') {
        centreon::plugins::misc::mymodule_load(
            output => $self->{output},
            module => 'JSON::XS',
            error_msg => "Cannot load module 'JSON::XS'."
        );
    }

    $self->{statefile_cipher} = defined($options{option_results}->{statefile_cipher}) && $options{option_results}->{statefile_cipher} ne '' ?    
        $options{option_results}->{statefile_cipher} : 'AES';
    $self->{statefile_key} = defined($options{option_results}->{statefile_key}) && $options{option_results}->{statefile_key} ne '' ?    
        $options{option_results}->{statefile_key} : '';

    if ($self->{statefile_key} ne '') {
        centreon::plugins::misc::mymodule_load(
            output => $self->{output},
            module => 'Crypt::Mode::CBC',
            error_msg => "Cannot load module 'Crypt::Mode::CBC'."
        );
        centreon::plugins::misc::mymodule_load(
            output => $self->{output},
            module => 'Crypt::PRNG',
            error_msg => "Cannot load module 'Crypt::PRNG'."
        );
        centreon::plugins::misc::mymodule_load(
            output => $self->{output},
            module => 'MIME::Base64',
            error_msg => "Cannot load module 'MIME::Base64'."
        );
    }

    $self->{statefile_dir} = $options{option_results}->{statefile_dir};
    if (defined($self->{statefile_dir})
            && $self->{statefile_dir} ne $default_dir
            && defined($options{option_results}->{statefile_concat_cwd})
    ) {
        centreon::plugins::misc::mymodule_load(
            output => $self->{output},
            module => 'Cwd',
            error_msg => "Cannot load module 'Cwd'."
        );
        $self->{statefile_dir} = Cwd::cwd() . '/' . $self->{statefile_dir};
    }

    $self->{$_} = $options{option_results}->{$_} foreach qw/statefile_suffix memexpiration/;
}

sub error {
    my ($self) = shift;

    if (@_) {
        $self->{error} = $_[0];
    }
    return $self->{error};
}

sub get_key {
    my ($self, %options) = @_;

    my $key = $options{key};

    {
        use bytes;

        my $size = length($key);
        my $minsize = Crypt::Cipher->min_keysize($options{cipher});
        if ($minsize > $size) {
            $key .= "0" x ($minsize - $size);
        }
    }

    return $key;
}

sub decrypt {
    my ($self, %options) = @_;

    return (1, $options{data}) if (!defined($options{data}->{encrypted}));

    my $plaintext;
    eval {
        my $cipher = Crypt::Mode::CBC->new($options{data}->{cipher}, 1);
        $plaintext = $cipher->decrypt(
            MIME::Base64::decode_base64($options{data}->{ciphertext}),
            $self->get_key(key => $self->{statefile_key}, cipher => $options{data}->{cipher}),
            pack('H*', $options{data}->{iv})
        );
    };

    if ($@) {
        return 0;
    }

    return $self->deserialize(data => $plaintext, nocipher => 1);
}

sub deserialize {
    my ($self, %options) = @_;

    my $deserialized = '';
    if ($self->{statefile_format} eq 'dumper') {
        our $datas;
        $self->{safe}->reval($options{data}, 1);
        return 0 if ($@);

        $deserialized = $datas;
    } elsif ($self->{statefile_format} eq 'storable') {
        eval {
            $deserialized = Storable::thaw($options{data});
        };
        return 0 if ($@);
    } elsif ($self->{statefile_format} eq 'json') {
        eval {
            $deserialized = JSON::XS->new->decode($options{data});
        };
        return 0 if ($@);
    }

    return 0 if (!defined($deserialized) || ref($deserialized) ne 'HASH');

    my $rv = 1;
    if ($self->{statefile_key} ne '' && !defined($options{nocipher})) {
        ($rv, $deserialized) = $self->decrypt(data => $deserialized);
    }

    return ($rv, $deserialized);
}

sub slurp {
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

sub read {
    my ($self, %options) = @_;
    $self->{statefile_suffix} = defined($options{statefile_suffix}) ? $options{statefile_suffix} : $self->{statefile_suffix};
    $self->{statefile_dir} = defined($options{statefile_dir}) ? $options{statefile_dir} : $self->{statefile_dir};
    $self->{statefile} = defined($options{statefile}) ? $options{statefile} . $self->{statefile_suffix} : $self->{statefile};
    $self->{no_quit} = defined($options{no_quit}) && $options{no_quit} == 1 ? 1 : 0;

    my ($data, $rv);

    if (defined($self->{memcached})) {
        # if "SUCCESS" or "NOT FOUND" is ok. Other with use the file
        my $val = Memcached::libmemcached::memcached_get($self->{memcached}, $self->{statefile_dir} . '/' . $self->{statefile});
        if (defined($self->{memcached}->errstr) && $self->{memcached}->errstr =~ /^SUCCESS|NOT FOUND$/i) {
            $self->{memcached_ok} = 1;
            if (defined($val)) {
                ($rv, $data) = $self->deserialize(data => $val);
                $self->{datas} = defined($data) ? $data : {};
                return $rv;
            }

            return 0;
        }
    }

    if (defined($self->{redis_cnx})) {
        my $val = $self->{redis_cnx}->get($self->{statefile_dir} . "/" . $self->{statefile});
        if (defined($val)) {
            ($rv, $data) = $self->deserialize(data => $val);
            $self->{datas} = defined($data) ? $data : {};
            return $rv;
        }

        return 0;
    }

    if (! -e $self->{statefile_dir} . '/' . $self->{statefile}) {
        if (! -w $self->{statefile_dir} || ! -x $self->{statefile_dir}) {
            $self->error(1);
            $self->{output}->add_option_msg(short_msg =>  "Cannot write statefile '" . $self->{statefile_dir} . "/" . $self->{statefile} . "'. Need write/exec permissions on directory.");
            if ($self->{no_quit} == 0) {
                $self->{output}->option_exit();
            }
        }
        return 0;
    } elsif (! -w $self->{statefile_dir} . '/' . $self->{statefile}) {
        $self->error(1);
        $self->{output}->add_option_msg(short_msg => "Cannot write statefile '" . $self->{statefile_dir} . "/" . $self->{statefile} . "'. Need write permissions on file.");
        if ($self->{no_quit} == 0) {
            $self->{output}->option_exit();
        }
        return 1;
    } elsif (! -s $self->{statefile_dir} . '/' . $self->{statefile}) {
        # Empty file. Not a problem. Maybe plugin not manage not values
        return 0;
    }

    $data = $self->slurp(file => $self->{statefile_dir} . '/' . $self->{statefile});
    ($rv, $data) = $self->deserialize(data => $data);
    $self->{datas} = defined($data) ? $data : {};

    return $rv;
}

sub get_string_content {
    my ($self, %options) = @_;

    return Data::Dumper::Dumper($self->{datas});
}

sub get {
    my ($self, %options) = @_;

    if (defined($self->{datas}->{ $options{name} })) {
        return $self->{datas}->{ $options{name} };
    }
    return undef;
}

sub encrypt {
    my ($self, %options) = @_;

    my $data = {
        encrypted => 1,
        cipher => $self->{statefile_cipher},
        iv => Crypt::PRNG::random_bytes_hex(16)
    };

    eval {
        my $cipher = Crypt::Mode::CBC->new($self->{statefile_cipher}, 1);
        $data->{ciphertext} = MIME::Base64::encode_base64(
            $cipher->encrypt(
                $options{data},
                $self->get_key(key => $self->{statefile_key}, cipher => $self->{statefile_cipher}),
                pack('H*', $data->{iv})
            ),
            ''
        );
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "cipher encrypt error: $@");
        $self->{output}->option_exit();
    }

    return $self->serialize(data => $data, nocipher => 1);
}

sub serialize {
    my ($self, %options) = @_;

    my $serialized = '';
    if ($self->{statefile_format} eq 'dumper') {
        $serialized = Data::Dumper->Dump([$options{data}], ['datas']);
    } elsif ($self->{statefile_format} eq 'storable') {
        $serialized = Storable::freeze($options{data});
    } elsif ($self->{statefile_format} eq 'json') {
        eval {
            $serialized = JSON::XS->new->encode($options{data});
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg =>  "Cannot serialize statefile '" . $self->{statefile_dir} . "/" . $self->{statefile} . "'");
            $self->{output}->option_exit();
        }
    }

    if ($self->{statefile_key} ne '' && !defined($options{nocipher})) {
        $serialized = $self->encrypt(data => $serialized);
    }

    return $serialized;
}

sub write {
    my ($self, %options) = @_;

    my $serialized = $self->serialize(data => $options{data});
    if ($self->{memcached_ok} == 1) {
        Memcached::libmemcached::memcached_set(
            $self->{memcached},
            $self->{statefile_dir} . '/' . $self->{statefile}, 
            $serialized,
            $self->{memexpiration}
        );
        if (defined($self->{memcached}->errstr) && $self->{memcached}->errstr =~ /^SUCCESS$/i) {
            return ;
        }
    }
    if (defined($self->{redis_cnx})) {
        return if (defined($self->{redis_cnx}->set(
            $self->{statefile_dir} . '/' . $self->{statefile},
            $serialized,
            'EX', $self->{memexpiration}))
        );
    }
    open FILE, '>', $self->{statefile_dir} . '/' . $self->{statefile};
    print FILE $serialized;
    close FILE;
}

1;


=head1 NAME

centreon::plugins::statefile - A module for managing state files with various storage backends.

=head1 SYNOPSIS

    use centreon::plugins::statefile;

    my $statefile = centreon::plugins::statefile->new(
        output => $output,
        options => $options
    );

    $statefile->check_options(option_results => $option_results);
    $statefile->read(statefile => 'my_statefile');
    my $data = $statefile->get(name => 'some_key');
    $statefile->write(data => { some_key => 'some_value' });

=head1 DESCRIPTION

The `centreon::plugins::statefile` module provides methods to manage state files (files storing the data to keep from an
execution to the next one), supporting various storage backends such as local files, Memcached, and Redis. It also supports encryption and different serialization formats.

=head1 METHODS

=head2 new

    my $statefile = centreon::plugins::statefile->new(%options);

Creates a new `centreon::plugins::statefile` object.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<output> - An C<centreon::plugins::output> object to log error messages.

=item * C<options> - A C<centreon::plugins::options> object to add command-line options.

=back

=back

=head2 check_options

    $statefile->check_options(%options);

Checks and processes the provided options.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<option_results> - A hash of option results.

=back

=back

=head2 read

    $statefile->read(%options);

Reads the state file.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<statefile> - The name of the state file to read.

=item * C<statefile_suffix> - An optional suffix for the state file name.

=item * C<statefile_dir> - An optional directory for the state file.

=item * C<no_quit> - An optional flag to prevent the program from exiting on error.

=back

=back

=head2 write

    $statefile->write(%options);

Writes data to the state file.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<data> - A hash reference containing the data to write.

=back

=back

=head2 get

    my $value = $statefile->get(%options);

Retrieves a value from the state file data.

=over 4

=item * C<%options> - A hash of options. The following keys are supported:

=over 8

=item * C<name> - The key name of the value to retrieve.

=back

=back

=head2 get_string_content

    my $string = $statefile->get_string_content();

Returns the state file data as a string.

=head2 error

    my $error = $statefile->error();

Gets or sets the error state.

=over 4

=item * C<$error> - An optional error value to set.

=back

=head1 EXAMPLES

=head2 Creating a Statefile Object

    use centreon::plugins::statefile;

    my $statefile = centreon::plugins::statefile->new(
        output => $output,
        options => $options
    );

=head2 Checking Options

    $statefile->check_options(option_results => $option_results);

=head2 Reading a Statefile

    $statefile->read(statefile => 'my_statefile');

=head2 Writing to a Statefile

    $statefile->write(data => { some_key => 'some_value' });

=head2 Retrieving a Value

    my $value = $statefile->get(name => 'some_key');

=head2 Getting Statefile Data as a String

    my $string = $statefile->get_string_content();

=head1 AUTHOR

Centreon

=head1 LICENSE

Licensed under the Apache License, Version 2.0.

=cut

=head1 RETENTION OPTIONS

=over 8

=item B<--memcached>

Memcached server to use (only one server).

=item B<--redis-server>

Redis server to use (only one server). Syntax: address[:port]

=item B<--redis-attribute>

Set Redis Options (--redis-attribute="cnx_timeout=5").

=item B<--redis-db>

Set Redis database index.

=item B<--failback-file>

Fall back on a local file if Redis connection fails.

=item B<--memexpiration>

Time to keep data in seconds (default: 86400).

=item B<--statefile-dir>

Define the cache directory (default: '/var/lib/centreon/centplugins').

=item B<--statefile-suffix>

Define a suffix to customize the statefile name (default: '').

=item B<--statefile-concat-cwd>

If used with the '--statefile-dir' option, the latter's value will be used as
a sub-directory of the current working directory.
Useful on Windows when the plugin is compiled, as the file system and permissions are different from Linux.

=item B<--statefile-format>

Define the format used to store the cache. Available formats: 'dumper', 'storable', 'json' (default).

=item B<--statefile-key>

Define the key to encrypt/decrypt the cache.

=item B<--statefile-cipher>

Define the cipher algorithm to encrypt the cache (default: 'AES').

=back

=head1 DESCRIPTION

B<statefile>.

=cut
