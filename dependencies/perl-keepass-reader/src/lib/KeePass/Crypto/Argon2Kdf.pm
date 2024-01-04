package KeePass::Crypto::Argon2Kdf;

use strict;
use warnings;
use POSIX;
use KeePass::constants qw(:all);
use Crypt::Argon2;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    $self->{type} = KeePass2_Kdf_Argon2Id;
    if ($options{type} eq KeePass2_Kdf_Argon2D) {
        $self->{type} = KeePass2_Kdf_Argon2D;
    }
    $self->{m_version} = 0x13;
    $self->{m_memory} = 1 << 16;
    $self->{m_parallelism} = 4;
    $self->{m_rounds} = 10;

    return $self;
}

sub seed {
    my ($self, %options) = @_;

    return $self->{m_seed};
}

sub process_parameters {
    my ($self, %options) = @_;

    $self->{m_seed} = $options{params}->{&KdfParam_Argon2_Salt};
    if (!defined($self->{m_seed}) || length($self->{m_seed}) < Kdf_Min_Seed_Size || length($self->{m_seed}) > Kdf_Max_Seed_Size) {
        return 1;
    }

    $self->{m_version} = $options{params}->{&KdfParam_Argon2_Version};
    if (!defined($self->{m_version}) || $self->{m_version} < 0x10 || $self->{m_version} > 0x13) {
        return 1;
    }

    $self->{m_parallelism} = $options{params}->{&KdfParam_Argon2_Parallelism};
    if (!defined($self->{m_parallelism}) || $self->{m_parallelism} < 1 || $self->{m_parallelism} > (1 << 24)) {
        return 1;
    }

    $self->{m_memory} = $options{params}->{&KdfParam_Argon2_Memory};
    return 1 if (!defined($self->{m_memory}));
    $self->{m_memory} /= 1024; # KB
    if ($self->{m_memory} < 8 || $self->{m_memory} > (1 << 32)) {
        return 1;
    }

    $self->{m_rounds} = $options{params}->{&KdfParam_Argon2_Iterations};
    if (!defined($self->{m_rounds}) || $self->{m_rounds} < 1 || $self->{m_rounds} > POSIX::INT_MAX) {
        return 1;
    }
    
    return 0;
}

sub transform {
    my ($self, %options) = @_;

    my $transform_key;
    if ($self->{type} eq KeePass2_Kdf_Argon2D) {
        $transform_key = Crypt::Argon2::argon2d_raw(
            $options{raw_key},
            $self->{m_seed},
            $self->{m_rounds},
            $self->{m_memory} . 'k',
            $self->{m_parallelism},
            32
        );
    } else {
        $transform_key = Crypt::Argon2::argon2i_raw(
            $options{raw_key},
            $self->{m_seed},
            $self->{m_rounds},
            $self->{m_memory} . 'k',
            $self->{m_parallelism},
            32
        );
    }

    return $transform_key;
}

1;
