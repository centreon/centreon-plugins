#
# MQSeries::Message::IIH - IMS Bridge Message
#
# (c) 2002-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#
# $Id: IIH.pm,v 33.11 2012/09/26 16:15:16 jettisu Exp $
#

package MQSeries::Message::IIH;

use strict;
use Carp;

use MQSeries::Message;

our $VERSION = '1.34';
our @ISA = qw(MQSeries::Message);

#
# This describes the IIH structure.  We do this in perl to avoid XS
# code...
#
my @IIH_Struct =
  (
   #    Name                    Method          Length  Default
   [ qw(StrucId                 String          4       IIH     ) ],
   [ qw(Version                 Number          4       1       ) ],
   [ qw(StrucLength             Number          4       84      ) ],
   [ qw(Encoding                Number          4       0       ) ],
   [ qw(CodedCharSetId          Number          4       0       ) ],
   [ qw(Format                  String          8       MQIMSVS ) ],
   [ qw(Flags                   Number          4       0       ) ],
   [ qw(LTermOverride           String          8               ) ],
   [ qw(MFSMapName              String          8       ) ],
   [ qw(ReplyToFormat           String          8       MQFMT_IMS_VAR_STRING) ],
   [ qw(Authenticator           String          8       ) ],
   [ qw(TranInstanceId          Byte            16      ) ],
   [ qw(TranState               String          1       ) ],
   [ qw(CommitMode              String          1       ) ],
   [ qw(SecurityScope           String          1       C) ],
   [ qw(Reserved                String          1       ) ],
  );


#
# Constructor for an IIH message
#
# Hash with named parameters:
# - Data (in a non-standard format)
# - MsgDesc
# - Header
# - Carp
#
sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my %MsgDesc =
      (
       Format   => MQSeries::MQFMT_IMS,
      );

    my $carp = $args{Carp} || \&carp;
    die "Invalid 'Carp' parameter: not a code ref"
      unless (ref $carp eq 'CODE');

    #
    # Merge MsgDesc supplied by user (if any) with our pre-defined
    # one that sets the bridge header format.
    #
    # NOTE: This is blatant guesswork, as no sample header
    #       has been supplied.
    #
    if (exists $args{MsgDesc}) {
        unless (ref $args{MsgDesc} eq "HASH") {
            $carp->("Invalid argument: 'MsgDesc' must be a HASH reference.\n");
            return;
        }
        foreach my $key (keys %{ $args{MsgDesc} }) {
            $MsgDesc{$key} = $args{MsgDesc}->{$key};
        }
    }

    $args{MsgDesc} = \%MsgDesc;
    my $this = MQSeries::Message->new(%args) || return;

    #
    # Deal with optional 'Header' parameter
    #
    $this->{Header} = $args{Header} || {};
    return bless $this, $class;
}


#
# Return header field / header hash reference
#
# One optional parameter: field name
#
sub Header {
    my ($this, $field) = @_;

    if (defined $field) {
        return $this->{Header}{$field}; # May be undef
    }
    return $this->{Header};
}


#
# Conversion routine on get: decode IIH into Header and Data
#
sub GetConvert {
    my ($this, $buffer) = @_;
    $this->_setEndianess();
    $this->{Buffer} = $buffer;

    my $offset = 0;

    foreach my $field (@IIH_Struct) {
        my ($key, $method, $length, $dft) = @$field;
        $method = "_read$method";
        if ($offset + $length > length($buffer)) {
            $this->{Carp}->("IIH field [$key] would read beyond buffer, stopping\n");
            $offset = length($buffer);
            last;
        }

        my $value = $this->$method($buffer, $offset, $length);
        print "Read key [$key] value [$value]\n";
        $this->{Header}{$key} = $value;
        $offset += $length;
    }

    #
    # The IIH data is returned as an array-ref of strings.
    #
    my $retval = [];
    while ($offset < length($buffer)) {
        #print STDERR "XXX: Offset [$offset]\n";
        my $datalen = $this->_readShort($buffer, $offset, 2);
        #print STDERR"XXX: Have data length [$datalen]\n";

        push @$retval, substr($buffer, $offset + 4, $datalen - 4);
        $offset += $datalen;
        #print STDERR "Have TR [$entry->{Transaction}] Body [$entry->{Body}]\n";
    }
    return $retval;
}


#
# The data (hash-reference or array-ref of hash-refes), plus an IMS
# Bridge Header, into an MQ message.
#
sub PutConvert {
    my ($this, $data) = @_;
    $this->_setEndianess();

    die "IIH data must be a hash-reference or ref to array of hash-references"
      unless (ref $data);
    $data = [ $data ] if (ref $data eq 'HASH');

    my $buffer = '';
    my $offset = 0;

    foreach my $field (@IIH_Struct) {
        my ($key, $method, $length, $dft) = @$field;
        $method = "_write$method";
        my $value = (defined $this->{Header}{$key} ?
                     $this->{Header}{$key} : $dft);
        substr($buffer, $offset, $length) = $this->$method($value, $length);
        $offset += $length;
    }

    #
    # For each data chunk, add LLZZ encoding of the data.
    #
    # FIXME: We maybe should perform 4-byte alignment for
    #        multiple chunks.
    #
    foreach my $entry (@$data) {
        foreach my $req (qw(Transaction Body)) {
            die "Missing field '$req' in IIH Data"
              unless (defined $entry->{$req});
        }
        my $datalen = 12 + length($entry->{Body});

        substr($buffer, $offset, 2) = $this->_writeShort($datalen);
        substr($buffer, $offset+2, 2) = $this->_writeShort(0);

        #
        # There should only be 1 space between IMS Tran code and the Data
        #
        my $tranIDLength = length($entry->{Transaction})+1;
        substr($buffer, $offset+4,$tranIDLength ) =
          $this->_writeString($entry->{Transaction}, $tranIDLength);
        $buffer .= $entry->{Body};
        $offset += $datalen;
    }

    return $buffer;
}


# ------------------------------------------------------------------------

#-
# The globals determine how to pack numbers (big/little endian)
#
my ($packShort, $packNumber);

sub _readString {
    my $class = shift;
    my ($data,$offset,$length) = @_;
    return unpack("A*", substr($data,$offset,$length));
}


sub _writeString {
    my $class = shift;
    my ($string,$length) = @_;
    return $string . ( " " x ( $length - length($string) ) );
}


sub _readNumber {
    my $class = shift;
    my ($data,$offset,$length) = @_;
    return unpack($packNumber, substr($data,$offset,$length));
}


sub _writeNumber {
    my $class = shift;
    my ($number) = @_;
    return pack($packNumber, $number);
}


sub _readShort {
    my $class = shift;
    my ($data,$offset,$length) = @_;
    return unpack($packShort, substr($data,$offset,$length));
}


sub _writeShort {
    my $class = shift;
    my ($number) = @_;
    return pack($packShort, $number);
}


sub _readByte {
    my $class = shift;
    my ($data,$offset,$length) = @_;
    return substr($data,$offset,$length);
}


sub _writeByte {
    my $class = shift;
    my ($string,$length) = @_;
    if ( length($string) < $length ) {
        $string .= "\0" x ( $length - length($string) );
    }
    return $string;
}


#
# This sub is used to determine if the platform we are running on is
# Big/Little endian.  If the client platform and server platform have
# different endian-ness, you can invoke it with:
#
# - 0: server is little-endian (Linux/Intel, Windows NT)
# - 1: server is big-endian (Solaris/SPARC)
#
sub _setEndianess {
    my ($big_endian) = @_;

    if (@_ == 1) {
        return if (defined $packShort);
        #
        # Implicit invocation - base on guess work
        #
        $big_endian = pack('N', 1) eq pack('L', 1);
        #print STDERR "Implicitly set format to " . ($big_endian ? "big" : "little") . " endian\n";
    }

    if ($big_endian) {
        $packShort = "n";
        $packNumber= "N";
    } else {
        $packShort = "v";
        $packNumber= "V";
    }
}

1;


__END__

=head1 NAME

MQSeries::Message::IIH -- Class to send/receive IMS Bridge Header (IIH) messages

=head1 SYNOPSIS

  use MQSeries::Message::IIH;

  #
  # Create a message to be put on a queue going to IMS
  #
  my $message = MQSeries::Message::IIH->
    new(Header => { Authenticator => 'foobar',
                    CommitMode    => MQSeries::MQICM_COMMIT_THEN_SEND,
                    TranState     => MQSeries::MQITS_IN_CONVERSATION,
                  },
        Data   => { Transaction => 'ISIC7000',
                    Body        => '   Blah Blah Blah   ',
                  },
        );

  #
  # Get a message from an IMS queue
  #
  my $qmgr_obj = MQSeries::QueueManager->new(QueueManager => 'TEST.QM');
  my $queue = MQSeries::Queue->
    new(QueueManager => $qmgr_obj,
        Queue        => 'IMS.DATA.QUEUE',
        Mode         => 'input');
  my $msg = MQSeries::Message::IIH->new();
  $queue->Get(Message => $msg);
  my $data = $msg->Data(); # Array-reference

=head1 DESCRIPTION

This is a simple subclass of MQSeries::Message which supports sending
and retrieving IMS Bridge Header (IIH) messages.  This class is
experimental, as it was based on the documentation and a few sample
messages; feedback as to how well it works is welcome.

An IMS Bridge Header message contains an IIH header, followed by one
more data chunks with IMS transaction data.  For requests, each chunk
has a transaction name and a body; for replies, each chunk is free
form.

=head1 METHODS

=head2 PutConvert

This method is not called by the user's application, but used
internally by MQSeries::Queue::Put() and
MQSeries::QueueManager::Put1().

PutConvert() encodes the data supplied by the programmer into a series
of chunks as required by IMS.

The data can come in two forms:

=over 4

=item *

A hash-reference with a C<Transaction> and C<Body>, as shown in the
example above.  This is the common case.

=item *

A reference to an array with hash-references, each in the same format
as before.  I am not sure whether anyone would actually use this...

=back

=head2 GetConvert

This method is not called by the user's application, but used
internally by MQSeries::Queue::Get().

GetConvert() decodes IMS data into a series of chunks, returned
as an array-reference containing strings.

=head1 _setEndianess

An IMS message contains a number of numerical fields that are encoded
based on the endian-ness of the queue manager.  In most cases, that is
the same endian-ness as the client (certainly if both run on the same
machine), and this module uses that as the default.

If you need to override the guess made by this module, then you can
invoke the C<_setEndianess> method with 0 if server is little-endian
(Linux/Intel, Windows NT) and 1 if server is big-endian
(Solaris/SPARC).

For example, if you run on a Linux/Intel machine, but need to create a
message for a queue manager running on Solaris:

  MQSeries::Message::IIH->_setEndianess(1);
  my $message = MQSeries::Message::IIH->
    new(Header => { Authenticator => 'foobar',
                    CommitMode    => MQSeries::MQICM_COMMIT_THEN_SEND,
                    TranState     => MQSeries::MQITS_IN_CONVERSATION,
                  },
        Data   => { Transaction => 'ISIC7000',
                    Body        => '   Blah Blah Blah   ',
                  },
        );

=head1 AUTHORS

Hildo Biersma, Jeff Dunn, Javier Ripoll Villagómez

=head1 SEE ALSO

MQSeries(3), MQSeries::QueueManager(3), MQSeries::Queue(3), MQSeries::Message(3)

=cut

