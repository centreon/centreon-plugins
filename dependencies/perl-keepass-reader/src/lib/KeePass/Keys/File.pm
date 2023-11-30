package KeePass::Keys::File;

use strict;
use warnings;
use KeePass::constants qw(:all);

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    return $self;
}

sub slurp {
    my ($self, %options) = @_;

    my ($fh, $size);
    if (!open($fh, '<', $options{file})) {
        return (1, "Could not open $options{file}: $!");
    }
    if (!($size = -s $options{file})) {
        return (1, "File $options{file} appears to be empty");
    }
    binmode $fh;
    read($fh, my $buffer, $size);
    close $fh;
    if (length($buffer) != $size) {
        $self->error(message => "Could not read entire file contents of $options{file}");
        return undef;
    }

    return (0, undef, $buffer);
}

sub set_keyfile {
    my ($self, %options) = @_;

    my ($ret, $message, $buffer) = $self->slurp(file => $options{keyfile});
    if ($ret == 0) {
        $self->{m_key} = Crypt::Digest::SHA256::sha256($buffer);
    }
    return ($ret, $message);
}

sub raw_key {
    my ($self, %options) = @_;

    return $self->{m_key};
}

1;
