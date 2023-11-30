package KeePass::Keys::Password;

use strict;
use warnings;
use KeePass::constants qw(:all);
use Crypt::Digest::SHA256;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    return $self;
}

sub set_password {
    my ($self, %options) = @_;

    $self->{m_key} = Crypt::Digest::SHA256::sha256($options{password});
}

sub raw_key {
    my ($self, %options) = @_;

    return $self->{m_key};
}

1;
