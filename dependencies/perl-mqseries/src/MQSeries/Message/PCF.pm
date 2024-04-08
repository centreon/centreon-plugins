#
# $Id: PCF.pm,v 37.3 2012/09/26 16:10:12 jettisu Exp $
#
# (c) 1999-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#

package MQSeries::Message::PCF;

use strict;

use DynaLoader;
use Exporter;

use MQSeries::Message;

our $VERSION = '1.34';
our @ISA = qw(MQSeries::Message Exporter DynaLoader);
our @EXPORT_OK = qw( MQDecodePCF MQEncodePCF );

bootstrap MQSeries::Message::PCF;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %args = @_;

    my $self = MQSeries::Message->new(%args) || return;

    if ( $args{Header} ) {
        $self->{Header} = $args{Header};
    }

    if ( $args{Parameters} ) {
        $self->{Parameters} = $args{Parameters};
    }

    bless ($self, $class);
    return $self;
}


sub GetConvert {
    my $self = shift;
    ($self->{Buffer}) = @_;

    my ($header,$parameters);

    unless ( ($header,$parameters) = MQDecodePCF($self->{Buffer}) ) {
        $self->{Carp}->("Unable to decode PCF Header and Parameters\n");
        return;
    }

    ($self->{Header},$self->{Parameters}) = ($header,$parameters);

    return 1;
}


sub PutConvert {
    my $self = shift;
    my $buffer = "";

    if ( $buffer = MQEncodePCF($self->{Header},$self->{Parameters}) ) {
        return $buffer;
    } else {
        $self->{Carp}->("Unable to encode PCF Header and Parameters\n");
        return undef;
    }
}


sub Header {
    my $self = shift;

    unless (
            ref $self->{Header} eq 'HASH' and
            keys %{$self->{Header}}
           ) {
        return;
    }

    if ( $_[0] ) {
        return $self->{Header}->{$_[0]};
    } else {
        return $self->{Header};
    }
}


sub Parameters {
    my $self = shift;

    unless (
            ref $self->{Parameters} eq 'HASH' and
            keys %{$self->{Parameters}}
           ) {
        return;
    }

    if ( $_[0] ) {
        return $self->{Parameters}->{$_[0]};
    } else {
        return $self->{Parameters};
    }
}

1;

__END__

=head1 NAME

MQSeries::Message::PCF -- Generic OO and procedural interface to PCF (Programmable Command Format) messages.

=head1 SYNOPSIS

  #
  # Here's an example of creating a PCF Command (InquireQueue) to send
  # to the command server.  Note that this example is a bit contrived,
  # since you would normally use the higher level MQSeries::Command
  # object for this.
  #
  use MQSeries;
  use MQSeries::Message::PCF;

  #
  # The $header hash represents the MQCFH PCF Header.
  #
  $header =
  {
   Type         => MQCFT_COMMAND,
   Command      => MQCMD_INQUIRE_Q,
  };

  #
  # The $parameters array is an array of hash references, each of
  # which individually represents one of the PCF parameter structures
  # (MQCFIN, MQCFST, MQCFIL, or MQCFSL).
  #
  $parameters =
  [

   # QName is a string (MQCFST)
   {
    Parameter   => MQCA_Q_NAME,
    String      => "FOO.*",
   },

   # QType is an integer (MQCFIN)
   {
    Parameter   => MQIA_Q_TYPE,
    Value       => MQQT_LOCAL,
   },

   # QAttrs in an integer list (MQCFIL)
   {
    Parameter   => MQIACF_Q_ATTRS,
    Values      =>
    [
     MQCA_Q_NAME,
     MQIA_Q_TYPE,
     MQCA_Q_DESC,
     MQIA_MAX_Q_DEPTH,
     MQIA_MAX_MSG_LENGTH,
    ],
   },

   # Although not shown in this example, string lists (MQCFSL) have a
   # structure similar to the integer lists.

  ];

  my $message = MQSeries::Message::PCF->new
    (
     Header                     => $header,
     Parameters                 => $parameters,
    ) || die;

  #
  # The rest of the SYNOPSIS shows the procedural interface, which you
  # can use directly if you really want to, but the intent was for
  # MQEncodePCF and MQDecodePCF to be used as building blocks for OO
  # classes which further abstract the PCF data.  See the SEE ALSO
  # section for a list of modules which do exactly that.
  #
  use MQSeries;
  use MQSeries::Message::PCF qw(MQDecodePCF MQEncodePCF);

  my $msgdata = MQEncodePCF($header,$parameters);

  #
  # The reverse operation would be:
  #
  my ($header, $parameters) = MQDecodePCF($msgdata);

=head1 DESCRIPTION

This module is both an OO API to PCF messages, and a pair of
exportable procedures for encoding and decoding PCF messages.  The two
functions are imported by other classes which further parse and
abstract specific PCF formats.

Note that it the intention of the author to provide specific
implementations of each of the standard PCF formats used in the
MQSeries product, and the current release already includes support for:

  PCF Command Server messages           (MQSeries::Command)
  Performance Events                    (MQSeries::Message::Event)

If you are reading this documentation with the intention of using it
for any of the above standard MQSeries messages, please see the docs
for those modules instead.

This module optionally exports the core PCF parsing procedures used by
all of the above (MQEncodePCF and MQDecodePCF), and the OO API is
provided for completeness (and because, well, it was trivial).

=head1 METHODS

The MQSeries::Message::PCF class is a subclass of MQSeries::Message,
so all of the methods of the latter class are also available.

=head2 new

The arguments to the MQSeries::Message::PCF constructor are passed
directly to the MQSeries::Message constructor, upon which this object
is based.  There are two additional keys supported by this class as
well: "Header" and "Parameters"

=over 4

=item Header

The value of this key is a HASH reference, representing the MQCFH PCF
header structure.  See below for specific details.

=item Parameters

The value of this key is an ARRAY reference of HASH references.  Each
HASH reference represents one of the PCF parameters structures MQCFIN,
MQCFST, MQCFIL, or MQCFSL.  See below for details.

=back

=head1 PROCEDURES

Both of these procedures must be explicitly imported by the caller,
and they are provided as building blocks for higher level abstractions
of the PCF message format.  All of the previously mentioned OO classes
in the MQSeries heirarchy which implement PCF formats use these
procedures in this way.

=head2 MQEncodePCF

This takes a pair of HASH references, for the PCF Header and
Parameters (format discussed below) and returns a string which is the
binary encoding of data into a set of C structures, suitable for use
as the message body for an MQSeries message of the appropriate PCF
format type.

  my $msgdata = MQEncodePCF($header,$parameters);

This routine returns the undefined value if an error is encountered
while encoding the data.

=head2 MQDecodePCF

This takes a string, which is assumed to be the body of a PCF message,
and returns a pair of HASH references, each representing the PCF
Header and Parameters data structures (formats discussed below).

  my ($header,$parameters) = MQDecodePCF($msgdata);

This routine returns an empty array if an error is encountered
while decoding the data.

=head1 Header and Parameter Data Structures

=head2 PCF Header (MQCFH)

This is a HASH reference which represents the MQCFH PCF header
structure.  See the MQCFH documentation for the details of the keys
which can be given in this hash, and the specific PCF implementation
documentation for the possible values which can be given, since they
vary from one usage to another.

Note that the "ParameterCount" key need not be specified, as the
MQEncodePCF() subroutine will calculate this automatically, by simply
counting the entries in the Parameters ARRAY.

Also, the "StrucLength", and "Version" keys are handled automatically,
and need not be given.

When this HASH is returned, all of the structures fields are returned
as keys in the HASH, although in most cases, you can ignore most of
them.

=head2 PCF Parameters (MQCFIN, MQCFST, MQCFIL, or MQCFSL)

This is an ARRAY reference or HASH references.  Each individual HASH
reference represents one of the PCF parameters structures, and each is
discussed individually.

In all cases, the "Type" and "StrucLength" keys can be omitted, since
the "Type" is derived from the other keys present (if there is a
"Value" key, its a MQCFIN, a "String" key, its a MQCFST, etc).  In
fact, both of these keys will be entirely ignored.

The "Parameter" values depend entirely on the specific usage of the
PCF format, with one set of possible values used for PCF command
server messages and another for performance events.  See the
respective documentation for each of these formats for more
information.

=over 4

=item Integer Parameter (MQCFIN)

This is a HASH reference with the following input keys:

  Parameter
  Value

The "Value" must be a numeric value, or an error will be
raised.

When returned, it has the following output keys:

  Parameter
  Value
  Type (always == MQCFT_INTEGER)

=item String Parameter (MQCFST)

This is a HASH reference with the following input keys (optional keys
denoted by *):

  Parameter
  String
  CodedCharSetId*

The "String" must have a string value, or an error will be raised.

When returned, is has the following output keys:

  Parameter
  String
  CodedCharSetId
  Type (always == MQCFT_STRING)

=item Integer List Parameter (MQCFIL)

This is a HASH reference with the following input keys:

  Parameter
  Values

The "Values" must be an ARRAY reference of numeric values, or an error
will be raised.  Note that the documented "Count" MQCFIL key may be
omitted, since it is automatically calculated as the length of the
ARRAY.

When returned, it has the following output keys:

  Parameter
  Values
  Type (always == MQCFT_INTEGER_LIST)

=item String List Parameter (MQCFSL)

This is a HASH reference with the following input keys (optional keys
denoted by *):

  Parameter
  Strings
  CodedCharSetId*

The "Strings" must be an ARRAY reference of string values, or an error
will be raised.Note that the documented "Count" MQCFSL key may be
omitted, since it is automatically calculated as the length of the
ARRAY.

When returned, it has the following output keys:

  Parameter
  Strings
  CodedCharSetId
  Type (always == MQCFT_STRING_LIST)

=back

=head1 SEE ALSO

  MQSeries::Message::Event(3),
  MQSeries::Command::Request(3),
  MQSeries::Command::Response(3),

=cut
