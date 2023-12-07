package KeePass::Crypto::Aes2Kdf;

use strict;
use warnings;
use POSIX;
use KeePass::constants qw(:all);
use Crypt::Mode::ECB;
use Crypt::Digest::SHA256;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    return $self;
}

sub seed {
    my ($self, %options) = @_;

    return $self->{m_seed};
}

sub process_parameters {
    my ($self, %options) = @_;

    $self->{m_seed} = $options{params}->{&KdfParam_Aes_Seed};
    if (!defined($self->{m_seed}) || length($self->{m_seed}) < Kdf_Min_Seed_Size || length($self->{m_seed}) > Kdf_Max_Seed_Size) {
        return 1;
    }

    $self->{m_rounds} = $options{params}->{&KdfParam_Aes_Rounds};
    if (!defined($self->{m_rounds}) || $self->{m_rounds} < 1 || $self->{m_rounds} > POSIX::INT_MAX) {
        return 1;
    }

    return 0;
}

sub transform {
    my ($self, %options) = @_;

    # Should use Argon2
    my $cbc = Crypt::Mode::ECB->new('AES');
    my $transform_key = $options{raw_key};
    for (my $i = 0; $i < $self->{m_rounds}; $i++) {
        $transform_key = $cbc->encrypt($transform_key, $self->{m_seed});
    }

    return Crypt::Digest::SHA256::sha256($transform_key);
}

1;
