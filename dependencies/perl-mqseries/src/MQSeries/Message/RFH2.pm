#
# MQSeries::Message::RFH2 - RFH2 Message
#
# (c) 2004-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#
# $Id: RFH2.pm,v 33.12 2012/09/26 16:15:17 jettisu Exp $
#

package MQSeries::Message::RFH2;

use strict;
use Carp;

use MQSeries::Message;

our $VERSION = '1.34';
our @ISA = qw(MQSeries::Message);

#
# This describes the RFH2 structure.  We do this in perl to avoid XS
# code...
#
my @RFH_Struct =
  (
   #    Name                    Method          Length  Default
   [ qw(StrucId                 String          4       RFH     ) ],
   [ qw(Version                 Number          4       2       ) ],
   [ qw(StrucLength             Number          4       36      ) ],
   [ qw(Encoding                Number          4),     MQSeries::MQENC_NATIVE ],
   [ qw(CodedCharSetId          Number          4       -2      ) ],
   [ qw(Format                  String          8),     MQSeries::MQFMT_NONE  ],
   [ qw(Flags                   Number          4       0       ) ],
   [ qw(NameValueCCSID          Number          4       1208    ) ],
);


#
# Constructor for an RFH2 message
#
# Hash with named parameters:
# - Data (in a non-standard format)
# - Header
# - Carp
#
sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;

    my $carp = $args{Carp} || \&carp;
    die "Invalid 'Carp' parameter: not a code ref"
        unless (ref $carp eq 'CODE');

    # this is important, otherwise MQ does not recognize this as a message with RFH2 header
    $args{MsgDesc}{Format} = MQSeries::MQFMT_RF_HEADER_2;

    my $this = MQSeries::Message->new(%args) || return;

    #
    # Deal with optional 'Header' parameter
    #
    if ( defined $args{Header}{NameValueData} ) {
        $args{Header}{NameValueData} = [ $args{Header}{NameValueData} ] unless ref($args{Header}{NameValueData});
    } else  {
        $args{Header}{NameValueData} = [];
    }  

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
# add a NameValueData field to the header
# or return the the NameValueData field
#   in Array context all fields are returned
#   iN scalar context only the first one
#
sub NameValueData {
   my ( $this, $valuedata ) = @_;
   
   if ( defined $valuedata ) {
       die "NameValueData must be a scalar" if ref($valuedata);
       push @{$this->{Header}{NameValueData}}, $valuedata;
   }
   return wantarray ? @{$this->{Header}{NameValueData}} : $this->{Header}{NameValueData}[0];
}   

#
# Conversion routine on get: decode RFH into Header and Data
#
sub GetConvert {
    my ($this, $buffer) = @_;
    $this->_setEndianess();
    $this->{Buffer} = $buffer;

    my $offset = 0;

    foreach my $field (@RFH_Struct) {
        my ($key, $method, $length, $dft) = @$field;
        $method = "_read$method";
        if ($offset + $length > length($buffer)) {
            $this->{Carp}->("RFH field [$key] would read beyond buffer, stopping\n");
            $offset = length($buffer);
            last;
        }

        my $value = $this->$method($buffer, $offset, $length);
        #print "Read key [$key] value [$value]\n";
        $this->{Header}{$key} = $value;
        $offset += $length;
    }

    # get the length of the header structure including NameValueData fields
    my $strucLength = $this->{Header}{StrucLength};

    while ( $offset < $strucLength ) {
      #
      # The RFH data is returned as a data length plus a string.
      # multiple fields are possible
      #
      my $datalen = $this->_readNumber($buffer, $offset, 4);
      $offset += 4;
      $this->NameValueData($this->_readString($buffer, $offset, $datalen));
      $offset += $datalen;
    }  

    # data is behind the RFH2 structure
    return substr($buffer,$strucLength);
}


#
# Convert the data (XML-like string), plus an RFH2 Header, into an MQ
# message.
#
sub PutConvert {
    my ($this, $data) = @_;

    my $header = $this->{Header};

    die "RFH2 data must be string" if (ref $data);

    $this->_setEndianess();
    my $buffer = '';
    my $offset = 0;

    #
    # The length of the value string  must be a multiple of four; round up
    # if required.
    #
    my $strucLength = 0;
    foreach my $data ( @{$header->{NameValueData}} ) {
        die "RFH2 NameValueData must be an XML-like string" unless $data && ref($data) eq "";
        $strucLength += 4 * int((length($data) + 3)/ 4) + 4 ; # + 4 because of size of NameValueLength field
    }  

    #### structureLength is size of the structure + size of NameValueData fields
    foreach my $field ( @RFH_Struct ) {
       $strucLength += $field->[2];
    }

    $header->{StrucLength} = $strucLength;

    # 
    # create the structure
    #
    foreach my $field (@RFH_Struct) {
        my ($key, $method, $length, $dft) = @$field;
        $method = "_write$method";
        my $value = (defined $this->{Header}{$key} ?
                     $this->{Header}{$key} : $dft);
        substr($buffer, $offset, $length) = $this->$method($value, $length);
        $offset += $length;
    }

    #
    # The length of the value string  must be a multiple of four; round up
    # if required.
    #
    foreach my $data ( @{$header->{NameValueData}} ) {
        my $namevalue_length = 4 * int((length($data) + 3)/ 4);
        substr($buffer, $offset, 4) = $this->_writeNumber($namevalue_length);
        $offset += 4;

        substr($buffer, $offset, $namevalue_length) = $this->_writeString($data,$namevalue_length);
        $offset += $namevalue_length;
    }

    # Append the data to the end
    $buffer .= $data;

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
    my ($class,$big_endian) = @_;

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

MQSeries::Message::RFH2 -- Class to send/receive RFH2 messages

=head1 SYNOPSIS

  use MQSeries::Message::RFH2;

  #
  # Create an RFH2 message with default settings
  #
  my $msg = MQSeries::Message::RFH2->new('NameValueData' => '<foo>bar</foo>', 'Data' => 'message with mydata');


  #
  # Same while overriding the Flags and NameValue character set id
  #
  my $msg2 = MQSeries::Message::RFH2->
    new('Header' => { 'NameValueCCSID' => 1200, # UCS-2
                      'Flags'          => 1,
		      'NameValueData' => '<foo>bar</foo>',
                    },
        'Data'   => $ucs2_data);

  # append another NameValueData Field
  $msg2->NameValueData('<test>value</test>');

  # Same with an array as NameValueData
  my $msg3 = MQSeries::Message::RFH2->new('NameValueData' => ['<foo>bar</foo>','<test>value</test>'], 
                                          'Data' => 'message with mydata');

  #
  # Get RFH2 data
  #
  my $qmgr_obj = MQSeries::QueueManager->new(QueueManager => 'TEST.QM');
  my $queue = MQSeries::Queue->
    new(QueueManager => $qmgr_obj,
        Queue        => 'RFH2.DATA.QUEUE',
        Mode         => 'input');
  my $msg = MQSeries::Message::RFH2->new();
  $queue->Get(Message => $msg);
  my $data = $msg->Data();
  print "Have name-value data '$data'\n";

=head1 DESCRIPTION

This is a simple subclass of MQSeries::Message which supports sending
and retrieving RFH2 messages.  This class is experimental, as it was
based on the documentation and a few sample messages; feedback as to
how well it works is welcome.

An RFH2 message contains an RFH2 header, followed by a data string
with structured name-value data, in XML format.

NOTE: In MQ v7, you may receive what appear to be messages in RFH2
format, when you're really getting a message with message properties.
If you're upgrading MQ v7, make sure you rebuild the module to get MQ
v7 support; and make sure to set the queue PropertyControl attribute
properly.

=head1 METHODS

=head2 NameValueData

Add another string as NameValueData to the header or return the 
stored NameValueData strings

# add a string
$msg->NameValueData('<test>another value</test>');

# return the first NameValueData string
my $s = $msg->NameValueData();

# return all NameValueStrings
my @s = $msg->NameValueData();


=head2 PutConvert, GetConvert

Neither of these methods are called by the users application, but are
used internally by MQSeries::Queue::Put() and MQSeries::Queue::Get(),
as well as MQSeries::QueueManager::Put1().

PutConvert() encodes the data supplied by the programmer into RFH2 format.

GetConvert() decodes the RFH2 header data and name-value pairs.
transaction name and body.

=head1 _setEndianess

An RFH2 message contains a number of numerical fields that are encoded
based on the endian-ness of the queue manager.  In most cases, that is
the same endian-ness as the client (certainly if both run on the same
machine), and this module uses that as the default.

If you need to override the guess made by this module, then you can
invoke the C<_setEndianess> method with 0 if server is little-endian
(Linux/Intel, Windows NT) and 1 if server is big-endian
(Solaris/SPARC).

For example, if you run on a Linux/Intel machine, but need to create a
message for a queue manager running on Solaris:

  MQSeries::Message::RFH2->_setEndianess(1);
  my $message = MQSeries::Message::RFH2->
    new('Data' => '<foo>bar</foo>');

=head1 AUTHORS

Hildo Biersma, Tim Kimber, Peter Heuchert

=head1 SEE ALSO

MQSeries(3), MQSeries::QueueManager(3), MQSeries::Queue(3), MQSeries::Message(3)

=cut

