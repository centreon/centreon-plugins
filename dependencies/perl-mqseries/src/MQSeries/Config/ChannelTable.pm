#
# $Id: ChannelTable.pm,v 36.5 2012/09/26 16:15:10 jettisu Exp $
#
# (c) 2001-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#

package MQSeries::Config::ChannelTable;

use strict;
use Carp;

our $VERSION = '1.34';

our (@MQCDFields, %Outgoing, %Incoming, %SystemDefClntconn, %StrucLength);

@MQCDFields =
  (
   #    Name                    Method          Length  Version Need
   [qw( ChannelName             String          20      3       1       )],
   [qw( Version                 Number          4       3       1       )],
   [qw( ChannelType             Number          4       3       1       )],
   [qw( TransportType           Number          4       3       1       )],
   [qw( ChannelDesc             String          64      3       1       )],
   [qw( QMgrName                String          48      3       1       )],
   [qw( XmitQName               String          48      3       0       )],
   [qw( ShortConnectionName     String          20      3       0       )],
   [qw( MCAName                 String          20      3       0       )],
   [qw( ModeName                String          8       3       1       )],
   [qw( TpName                  String          64      3       1       )],
   [qw( BatchSize               Number          4       3       0       )],
   [qw( DiscInterval            Number          4       3       0       )],
   [qw( ShortRetryCount         Number          4       3       0       )],
   [qw( ShortRetryInterval      Number          4       3       0       )],
   [qw( LongRetryCount          Number          4       3       0       )],
   [qw( LongRetryInterval       Number          4       3       0       )],
   [qw( SecurityExit            String          128     3       1       )],
   [qw( MsgExit                 String          128     3       1       )],
   [qw( SendExit                String          128     3       1       )],
   [qw( ReceiveExit             String          128     3       1       )],
   [qw( SeqNumberWrap           Number          4       3       0       )],
   [qw( MaxMsgLength            Number          4       3       1       )],
   [qw( PutAuthority            Number          4       3       0       )],
   [qw( DataConversion          Number          4       3       0       )],
   [qw( SecurityUserData        String          32      3       1       )],
   [qw( MsgUserData             String          32      3       1       )],
   [qw( SendUserData            String          32      3       1       )],
   [qw( ReceiveUserData         String          32      3       1       )],
   [qw( UserIdentifier          String          12      3       1       )],
   [qw( Password                String          12      3       1       )],
   [qw( MCAUserIdentifier       String          12      3       0       )],
   [qw( MCAType                 Number          4       3       0       )],
   [qw( ConnectionName          String          264     3       1       )],
   [qw( RemoteUserIdentifier    String          12      3       0       )],
   [qw( RemotePassword          String          12      3       0       )],
   [qw( MsgRetryExit            String          128     3       0       )],
   [qw( MsgRetryUserData        String          32      3       0       )],
   [qw( MsgRetryCount           Number          4       3       0       )],
   [qw( MsgRetryInterval        Number          4       3       0       )],

   [qw( HeartbeatInterval       Number          4       4       1       )],
   [qw( BatchInterval           Number          4       4       0       )],
   [qw( NonPersistentMsgSpeed   Number          4       4       0       )],
   [qw( StrucLength             Number          4       4       0       )],
   [qw( ExitNameLength          Number          4       4       0       )],
   [qw( ExitDataLength          Number          4       4       0       )],
   [qw( MsgExitsDefined         Number          4       4       0       )],
   [qw( SendExitsDefined        Number          4       4       0       )],
   [qw( ReceiveExitsDefined     Number          4       4       0       )],
   [qw( MsgExitPtr              Number          4       4       0       )],
   [qw( MsgUserDataPtr          Number          4       4       0       )],
   [qw( SendExitPtr             Number          4       4       0       )],
   [qw( SendUserDataPtr         Number          4       4       0       )],
   [qw( ReceiveExitPtr          Number          4       4       0       )],
   [qw( ReceiveUserDataPtr      Number          4       4       0       )],

   [qw( ClusterPtr              Number          4       6       0       )],
   [qw( ClustersDefined         Number          4       6       0       )],
   [qw( NetworkPriority         Number          4       6       0       )],
   [qw( LongMCAUserIdLength     Number          4       6       0       )],
   [qw( LongRemoteUserIdLength  Number          4       6       0       )],
   [qw( LongMCAUserIdPtr        Number          4       6       0       )],
   [qw( LongRemoteUserIdPtr     Number          4       6       0       )],
   [qw( MCASecurityId           Byte            40      6       0       )],
   [qw( RemoteSecurityId        Byte            40      6       0       )],

   [qw( SSLCipherSpec           String          32      7       1       )],
   [qw( SSLPeerNamePtr          Number          4       7       0       )],
   [qw( SSLPeerNameLength       Number          4       7       0       )],
   [qw( SSLClientAuth           Number          4       7       1       )],
   [qw( KeepAliveInterval       Number          4       7       1       )],
   [qw( LocalAddress            String          48      7       1       )],
   [qw( BatchHeartbeat          Number          4       7       0       )],
  );

#
# There's only one key that is mapped, really.  But, based on what we
# learned when doing the PCF commands, we'll keep the same concept
# here, in the event that we have to start mapping new fields added by
# IBM in the future.
#
%Outgoing =
  (

   TransportType =>
   {
    DECnet                      => 5,
    LU62                        => 1,
    NetBIOS                     => 3,
    SPX                         => 4,
    TCP                         => 2,
    UDP                         => 6,
   },

   #
   # This is somewhat contrived.  In this code, only one value makes
   # sense, and we don't even make it an option....
   #
   ChannelType =>
   {
    Clntconn                    => 6,
   },

  );

%Incoming =
  (

   TransportType =>
   {
    1                           => 'LU62',
    2                           => 'TCP',
    3                           => 'NetBIOS',
    4                           => 'SPX',
    5                           => 'DECnet',
    6                           => 'UDP',
   },

   ChannelType =>
   {
    6                           => 'Clntconn',
   },

  );

#
# We only need to specify the non-null numbers and non-empty
# (i.e. non-space) strings.  Everything else will get a reasonable
# default.
#
%SystemDefClntconn =
  (
   Version                      => 6,
   ChannelName                  => 'SYSTEM.DEF.CLNTCONN',
   ChannelType                  => 'Clntconn',
   TransportType                => 'TCP',
   MaxMsgLength                 => 4194304,
   MCAType                      => 1,
   HeartbeatInterval            => 300,
   StrucLength                  => 1648,
   ExitNameLength               => 128,
   ExitDataLength               => 32,
   SSLClientAuth                => 0,
   KeepAliveInterval            => 'AUTO',
  );

%StrucLength =
  (
   4                            => 1540,
   6                            => 1648,
   7                            => 1748,
  );


sub readFile {
    my ($class, %args) = @_;
    my ($filename) = @args{qw(Filename)};

    if ( $args{Debug} ) {
        print "\nInside readFile method\n";
    }

    my $offset = 0;

    open(FILE, '<', $filename) ||
      confess "Unable to open $filename: $!\n";
    binmode(FILE);              # Required for Windows NT
    local $/ = undef;
    my $data = <FILE>;
    close(FILE) ||
      confess "Unable to close $filename: $!\n";

    #
    # OK, we've got the entire file in $data, so let's start stripping
    # it apart.
    #
    # First, get the 4 character prefix
    #
    $class->readString($data,$offset,4) eq "AMQR" ||
      confess("Invalid channel table file: $filename\n" .
              "Missing magic prefix 'AMQR'\n");

    $offset += 4;

    #
    # Now, we continue to yank channel definitions out of the file
    # until we hit a definition with a length of 0.
    #
    my $deflength = 0;
    my @clntconn = ();

    my $channelcount = 0;

    while ( $offset && ( $deflength = $class->readNumber($data,$offset,4) ) ) {

        $channelcount++;

        # Yank the entire channel definition
        my $chandef = substr($data,$offset,$deflength);

        if ( $args{Debug} ) {
            print "\nChannelCount = $channelcount\n";
            print "Absolute address of this record = $offset\n";
        }

        my $mqcd_length         = $class->readNumber($chandef,4,4);
        my $unknown             = $class->readNumber($chandef,8,4);
        my $next                = $class->readNumber($chandef,12,4);
        my $previous            = $class->readNumber($chandef,16,4);

        #
        # We go through all entries in the file skipping the one
        # that has a zero MQCD Length.
        #
        $offset += $deflength;

        if ( $args{Debug} ) {
            print "Definition length = $deflength\n";
            print "MQCD length = $mqcd_length\n";
            print "Unknown 3rd field = $unknown\n";
            print "Abs offset to next definition = $next\n";
            print "Abs offset to prev definition = $previous\n";
        }

        # If the MQCD Length is 0, then skip this entry
        next if $mqcd_length == 0;

        # Get the entire MQCD
        my $mqcd = substr($chandef,20,$mqcd_length);
        my $mqcd_offset = 0;

        my $clntconn = {};

        foreach my $field ( @MQCDFields ) {

            my ($key,$method,$length,$version,$need) = @$field;

            $method = "read$method";

            if ( ( not exists $clntconn->{Version} ) || ( $clntconn->{Version} >= $version ) ) {
                if ( $need ) {
                    if ( ref $Incoming{$key} eq 'HASH' ) {
                        my $value = $class->$method($mqcd,$mqcd_offset,$length);
                        if ( exists $Incoming{$key}->{$value} ) {
                            $clntconn->{$key} = $Incoming{$key}->{$value};
                        } else {
                            carp "Unable to translate $key value '$value'\n";
                            $clntconn->{$key} = $value;
                        }
                    } else {
                        $clntconn->{$key} = $class->$method($mqcd,$mqcd_offset,$length);
                    }
                }
                $mqcd_offset += $length;
            }

        }

        if ( $clntconn->{Version} >= 6 ) {

            my $mqcd_struct_length = $class->readNumber($mqcd,1492,4);  # MQCD StrucLength
            my $exit_strings_length = $class->readNumber($mqcd,$mqcd_struct_length+8,4);        # Undocumented
            $mqcd_offset = $mqcd_struct_length;
            $mqcd_offset += 68;
            $mqcd_offset += 64; # More 64 unknown spaces

            my @keys = qw(MsgExit MsgUserData SendExit SendUserData ReceiveExit ReceiveUserData);
            my @fields = split("\x01",substr($mqcd,$mqcd_offset,$exit_strings_length));
            $mqcd_offset += $exit_strings_length;

            for ( my $index = 0 ; $index < 6 ; $index++ ) {
                next unless defined $fields[$index];
                $clntconn->{$keys[$index]} = [split("\x02",$fields[$index])];
            }

            if ( $clntconn->{Version} >= 7 ) {
                #
                # KeepAliveInterval: 0xffffffff = 'AUTO'
                #
                if ($clntconn->{KeepAliveInterval} == 0xffffffff) {
                    $clntconn->{KeepAliveInterval} = $SystemDefClntconn{KeepAliveInterval};
                }

                my $SSLPeerNameLength = $class->readNumber($mqcd, 1684, 4);
                $clntconn->{SSLPeerName} = $class->readString($mqcd, $mqcd_offset, $SSLPeerNameLength);
                $mqcd_offset += $SSLPeerNameLength;
            }

        }

        push(@clntconn,$clntconn);

    }

    return @clntconn;
}


sub writeFile {
    my ($class, %args) = @_;
    my ($filename, $fh, $clntconn,$version) =
      @args{qw(Filename FileHandle Clntconn Version)};

    #
    # We must make sure the version and length of the default channel
    # matches that of the file.
    #
    if (defined $version) {
        $SystemDefClntconn{'Version'} = $version;
    } else {
        $version = $SystemDefClntconn{'Version'};
    }
    $SystemDefClntconn{'StrucLength'} = $StrucLength{$version};

    #
    # Either Filename or FileHandle must be supplied, but not both
    #
    if (defined $filename == defined $fh) {
        confess "You must supply either 'Filename' or 'FileHandle'";
    }

    my $data = "AMQR";
    my $offset = length($data);

    if ( $args{Debug} ) {
        print "\nInside writeFile method\n";
    }

    $version == 3 || $version == 4 || $version == 6 || $version == 7 ||
      confess "Invalid Version '$version': only 3, 4, 6 and 7 are supported\n";

    #
    # We need to ensure that SYSTEM.DEF.CLNTCONN exists.
    #
    my $default = { %SystemDefClntconn, Version => $version };
    my @channel = ();

    foreach my $channel ( @$clntconn ) {
        next unless $channel->{ChannelName} =~ /^SYSTEM\.DEF\.CLNTCONN\s*$/;
        $default = { %SystemDefClntconn, %$channel };
        $default->{Version} = $version;
        $default->{StrucLength} = $StrucLength{$version};
        last;
    }

    push(@channel,$default);

    foreach my $channel ( @$clntconn ) {
        next if $channel->{ChannelName} =~ /^SYSTEM\.DEF\.CLNTCONN\s*$/;
        my $newchannel = { %$default, %$channel };
        $newchannel->{Version} = $version;
        $newchannel->{StrucLength} = $StrucLength{$version};
        push @channel, $newchannel;
    }

    #
    # The channels need to be in reverse alphabetical order,
    # or any MQ client processing the file will hang.
    #
    @channel = sort { $b->{ChannelName} cmp $a->{ChannelName} } @channel;

    {
        my $supportedkeys = { map { $_->[0] => 1 } @MQCDFields };
        # ssl hack -- SSLPeerNamePtr and SSLPeerNameLength are the
        # names of the fields in the channel table, but SSLPeerName is
        # what we work with internally
        delete($supportedkeys->{SSLPeerNamePtr});
        delete($supportedkeys->{SSLPeerNameLength});
        $supportedkeys->{SSLPeerName} = 1;
        my $invalid = 0;
        foreach my $channel ( @channel ) {
            foreach my $key ( keys %$channel ) {
                next if exists $supportedkeys->{$key};
                $invalid++;
                carp "Invalid Clntconn key '$key', (ChannelName = $channel->{ChannelName})\n";
            }
        }
        confess "Invalid keys in Clntconn list\n" if $invalid;
    }

    #
    # We're going to create an array of binary encoded MQCD
    # structures, and then go back and create the next/previous
    # pointers.  We've had various ways of doing the ordering for the
    # double-linked but at this time (July 2002) it seems that the
    # channel names need to be in alphabetical order - so we sort the
    # channels and then create a straight linked list.
    #
    # The two-pass structure is kep in case we need to change this
    # again.
    #
    my @mqcd = ();

    for ( my $index = 0 ; $index <= $#channel ; $index++ ) {

        my $channel = $channel[$index];
        $channel->{ShortConnectionName} ||=
          !defined $channel->{ConnectionName} ? "" :
          substr($channel->{ConnectionName},0,20);

        my $mqcd = "";

        $channel->{SSLPeerNameLength} = defined $channel->{SSLPeerName} ?
          length($channel->{SSLPeerName}) : 0;

        #
        # KeepAliveInterval: 'AUTO' = 0xffffffff
        #
        if (defined $channel->{KeepAliveInterval} &&
            lc($channel->{KeepAliveInterval}) eq lc($SystemDefClntconn{KeepAliveInterval})) {
            $channel->{KeepAliveInterval} = 0xffffffff;
        }

        #
        # First, create a serialized MQCD out of the $channel HASH
        #
        foreach my $field ( @MQCDFields ) {

            my ($key,$method,$length,$fieldvers) = @$field;

            $method = "write$method";

            next if $fieldvers > $version;

            #
            # XXX -- the exit keys need special case handling, since
            # in V6 files, they aren't used.
            #
            if ( $key =~ /^(Msg|Send|Receive)(Exit|User)(Data)?$/ ) {
                if ( $version >= 6 ) {
                    $mqcd .= "\0" x $length;
                } else {
                    $mqcd .= $class->$method($channel->{$key},$length);
                }
            } else {
                if ( ref $Outgoing{$key} eq 'HASH' ) {
                    if ( exists $Outgoing{$key}->{$channel->{$key}} ) {
                        $mqcd .= $class->$method($Outgoing{$key}->{$channel->{$key}},$length);
                    } else {
                        carp "Unable to translate $key value '$channel->{$key}'\n";
                        $mqcd .= $class->$method($channel->{$key},$length);
                    }
                } else {
                    $mqcd .= $class->$method($channel->{$key},$length);
                }
            }

        }

        if ( $version >= 6 ) {

            my $exitstring = "";

            foreach my $key ( qw(MsgExit        MsgUserData
                                 SendExit       SendUserData
                                 ReceiveExit    ReceiveUserData) ) {

                if ( $channel->{$key} ) {
                    my @names = ( ref $channel->{$key} eq "ARRAY" ?
                                  @{$channel->{$key}} :
                                  $channel->{$key} );
                    $exitstring .= join("\x02", @names);
                }

                $exitstring .= "\x01";

            }

            # I have no idea what these bytes are, but they are always null
            $mqcd .= "\0" x 8;
            $mqcd .= $class->writeNumber(length($exitstring));
            # something else we have no clue about....  welcome to reverse engineering
            $mqcd .= "\0" x 52;
            $mqcd .= $class->writeNumber(time);
            $mqcd .= " " x 64;  # More 64 unknown spaces
            $mqcd .= $exitstring;

            if ($version >= 7 && defined($channel->{SSLPeerNameLength})) {
                $mqcd .= $class->writeString($channel->{SSLPeerName},
                                             $channel->{SSLPeerNameLength});
            }

        } else {
            #
            # We've got the V6 data structure decoded, but we're not
            # entirely sure about V4.
            #
            # IBM tells us we need 8 zeroes, then 0x06, then 11 zeroes
            $mqcd .= "\0" x 8;
            $mqcd .= "\06";
            $mqcd .= "\0" x 11;
        }

        my $mqcd_length = length($mqcd);

        push(@mqcd,
             {
              MQCD              => $mqcd,
              Offset            => $offset,
             });

        $offset += $mqcd_length + 20;

    }

    #
    # Now we'll troll through the @mqcd array of hashes, and add the
    # next and previous pointers.
    #
    for ( my $index = 0 ; $index <= $#mqcd ; $index++ ) {
        my $next = 0;
        my $prev = 0;

        #
        # Two special cases and one noral one:
        # - First entry (NULL prev pointer)
        # - Last entry (NULL next pointer)
        # - Any other entry (two pointers)
        #
        $prev = $mqcd[$index-1]->{Offset} if $index > 0;
        $next = $mqcd[$index+1]->{Offset} if $index < $#mqcd;

        my $mqcd_length = length($mqcd[$index]->{MQCD});

        if ( $args{Debug} ) {
            print "Channel entry $index out of " . ($#mqcd+1) . " entries\n";
            print "MQCD Length = $mqcd_length\n";
        }

        #
        # Now, put the header with the previous and next pointers in
        # front of it, and then add it to the final $data
        #
        my $entry = $class->writeNumber( $mqcd_length + 20 );
        $entry .= $class->writeNumber($mqcd_length);
        $entry .= "\0" x 4;

        $entry .= $class->writeNumber( $next );
        $entry .= $class->writeNumber( $prev );

        if ( $args{Debug} ) {
            print "Offset to next definition = $next\n";
            print "Offset to prev definition = $prev\n";
        }

        $entry .= $mqcd[$index]->{MQCD};

        $data .= $entry;

    }

    # Trailing zero
    $data .= "\0" x 4;

    #
    # Write to file or file-handle?
    #
    if (defined $fh) {
        print $fh $data;
    } else {
        open(FILE, '>', $filename) ||
          confess "Unable to write to $filename: $!\n";
        binmode(FILE);          # Required for Windows NT
        print FILE $data;
        close(FILE) ||
          confess "Unable to close $filename: $!\n";
    }

    return 1;
}


sub readString {
    my $class = shift;
    my ($data,$offset,$length) = @_;
    return unpack("A*", substr($data,$offset,$length));
}


sub readNumber {
    my $class = shift;
    my ($data,$offset,$length) = @_;
    return unpack("N", reverse substr($data,$offset,$length));
}


sub writeString {
    my $class = shift;
    my ($string,$length) = @_;
    $string = "" if (!defined($string));
    return $string . ( " " x ( $length - length($string) ) );
}


sub writeNumber {
    my $class = shift;
    my ($number) = @_;
    $number = 0 if (!defined($number));
    return reverse pack("N",$number);
}


sub readByte {
    my $class = shift;
    my ($data,$offset,$length) = @_;
    return substr($data,$offset,$length);
}


sub writeByte {
    my $class = shift;
    my ($string,$length) = @_;
    $string = "" if (!defined($string));
    if ( length($string) < $length ) {
        $string .= "\0" x ( $length - length($string) );
    }
    return $string;
}

1;

__END__

=head1 NAME

MQSeries::Config::ChannelTable -- class for reading and writing channel table files of various versions.

=head1 SYNOPSIS

  use MQSeries::Config::ChannelTable;

  #
  # To read a channel table file...
  #
  my @clntconn = ();
  eval {
      @clntconn = MQSeries::Config::ChannelTable->readFile
        (
         Filename               => "/var/mqm/AMQCLCHL.TAB",
        );
  };
  if ( $@ ) {
      # Exception handling goes here...
  }

  #
  # To write a channel table file...
  #
  eval {
      MQSeries::Config::ChannelTable->writeFile
        (
         Filename               => "/some/new/path",
         Clntconn               => [ @clntconn ],
         Version                => 4,
        );
  };
  if ( $@ ) {
      # Exception handling goes here...
  }

=head1 DESCRIPTION

This class provides a pair of class methods for reading and writing
the MQSeries client channel table file, allowing these important
configuration files to be managed without interacting with a queue
manager.

Normally, the only way to create a channel table file is to define all
of the required CLNTCONN objects, via runmqsc (and an input script,
perhaps), or PCF commands, then to copy the file

  /var/mqm/qmgrs/QMgrName/@ipcc/AMQCLCHL.TAB

and distribute that to the necessary clients.  Generation of the
channel table can be very slow, especially if a large number of
entries are created.  What is much worse, however, is the complex
logic necessary to create a set of different channel table files.  If
this is done on one queue manager, some of the gross inefficiencies in
the channel table file may become an issue (see below).

This class makes it trivially easy to both read and write channel
table files, of either version 4 (MQSeries 5.0) or 6 (5.1 and 5.2), by
working directly with the (unfortunately undocumented) file format
directly.  You do not need a running queue manager at all.

IMPORTANT: Please understand that IBM does B<NOT> document the format
of the channel table file, and the author of this module has
repeatedly asked them to disclose it.  They have repeatedly refused.

Reverse engineering rules.... :-)

=head1 METHODS

Note that all of these methods are class methods, not object methods.
Furthermore, both of these methods raise fatal exceptions (via
Carp::confess) if errors are encountered, so the developer will have
to trap those exceptions via eval(), as shown in the SYNOPSIS.

=head2 readFile

This method takes a HASH of key/value pairs as an argument, with the
following keys:

  Key           Value
  ===           =====
  Filename      String (pathname to channel table file)
  Debug         Number

The return value is a list of HASHes, each of which represents a
single CLNTCONN entry in the file.  See below for the CLNTCONN
key/value documentation.

=over

=item Filename

This must be an existing file, and it must be a valid version 4 or 6
channel table file.  If the file can not be parsed successfully, then
a fatal exception is raised.

=item Debug

Setting this will cause this method to spew a lot of debugging data,
of interest to noone other than the author.  See the code if you care.

=back

=head2 writeFile

This method takes a HASH of key/value pairs as an argument, with the
following keys:

  Key           Value
  ===           =====
  Filename      String (pathname to channel table file)
  Clntconn      ARRAY of HASHes (see below)
  Version       Number (4 or 6)
  Debug         Number

The return value will be true if the file could be written
successfully, and if not, a fatal exception is raised.

=over

=item Filename

This is the pathname to which to write the new file, which will be
overwritten if it exists, mercilessly.  Either this parameter, or
the 'FileHandle' parameter, must be supplied.

=item FileHandle

Instead of 'Filename', a previously opened file handle may be
supplied.  This can for example be used to print to STDOUT in a CGI
program delivering channel table files from the web.  On Windows, the
caller is responsible to call C<binmode> on the filehandle.

=item Clntconn

This is an ARRAY of HASHes, each of which represents a single Clntconn
definition.  See the next section for details of which key/value pairs
are supported for the Clntconn definitions.

Note that this must be a complete list of all of the definitions you
want to be written to the file.  Also note that while the
SYSTEM.DEF.CLNTCONN is supposed to be first, this code is forgiving,
and will sort it first for you.

=item Version

This specifies the version of the file to generate.

Version 4 is the version generated by an MQSeries 5.0 queue manager,
and it can be read on 5.0 and later clients.

Version 6 is the version generated by an MQSeries 5.1 or 5.2 queue
manager, and it can obviously be read by clients of the same release
or better, however, it can also be read by 5.0 clients, in most cases.

The exception would appear to be when any of the following CLNTCONN
fields are specified:

  MsgExit
  MsgUserData
  SendExit
  SendUserData
  ReceiveExit
  ReceiveUserData

The reason is that the representation of these attributes hsa changed
between these versions.  In the 5.0 file, only a single exit can be
specified for these attributes, but in 5.1 and later, they can be a
list.

It is likely that a 5.0 client will not be able to "see" these
attribute values, if the file is generated using the version 6 format.
The author does not use any of these exits for client channels, and
has not tested this, so as usual, YMMV (your mileage may vary, for the
acronym impaired).

=back

=head1 Clntconn HASH Specification

Each Clntconn entry in the channel table, as passed back to the caller
of readFile, or as passed into writeFile by the application, is
represented by a HASH reference of key/value pairs which are a subset
of those support by the MQCD structure.  Only the keys which are
relevant to clntconn channels are used.

Note that these key/value pairs are also identical to those used by
the MQSeries::Command channel commands, such as CreateChannel,
InquireChannel, etc. and thus the same data structures can be used for
both interfaces.

The valid key/value pairs for this HASH are:

  Key                   Value (Max Length of strings)
  ===                   =====
  ChannelName           String (20)
  Version               Numeric
  ChannelType           "Clntconn"
  TransportType         String (see below)
  ChannelDesc           String (64)
  QMgrName              String (48)
  ModeName              String (8)
  TpName                String (64)
  SecurityExit          String (128)
  MsgExit               String (128)
  SendExit              String (128)
  ReceiveExit           String (128)
  MaxMsgLength          Number
  SecurityUserData      String (32)
  MsgUserData           String (32)
  SendUserData          String (32)
  ReceiveUserData       String (32)
  UserIdentifier        String (12)
  Password              String (12)
  ConnectionName        String (264)

The specific use of each of these fields is documented in the IBM
"MQSeries Programmable System Management" documentation, and the other
partner docs.  All of the string and number values are fairly obvious,
with the following important exceptions:

=over

=item ChannelType

There is only one supported value for this attribute: "Clntconn".  As
a result, this is entirely optional, and need not be specified when
creating files with writeFile.  This key is returned by readFile for
completeness, but its use is optional.

=item Version

This field is returned by readFile(), however, it need not be
specified for each individual channel passed to writeFile, since the
version is itself an argument to writeFile().  It must be either 4 or
6, since those are the only formats supported by this version of this
module.

Since all of the entries in a single file must be the same, specifying
this on a per-channel basis is meaningless.  They must all be the same
anyway, so you only have to specify this once (as an argument to
writeFile).

=item TransportType

Rather than specify the specific binary value of the TransportType via
a macro, the following keys can be given as strings:

    Key                         Macro
    ===                         =====
    DECnet                      MQXPT_DECNET
    LU62                        MQXPT_LU62
    NetBIOS                     MQXPT_NETBIOS
    SPX                         MQXPT_SPX
    TCP                         MQXPT_TCP
    UDP                         MQXPT_UDP

Likewise, when a channel table file is read using readFile, it will
map the integer value found in the MQCD structure to the appropriate
string above.

=back

=head1 Secrets of AMQCLCHL.TAB

=head2 Inefficiencies

The primary inefficiency of this format is its size.  When this file
is managed by the queue manager (which is your only choice without
using this perl module), it grows and never shrinks.  When channels
are deleted, the linked list pointers are modified so that the deleted
entry is merely skipped, but it is not removed from the file.

When new entries are added, a deleted entry will be searched for and
reused if found.  If not, a new entry will be added to the end of the
file.  The size problem occurs if you ever create a very large channel
table file, since that will effectively extend the file size
permanently.

In addition, each entry is a complete MQCD structure, even though most
of the fields of the MQCD are not relevant for CLNTCONN channels.  The
total size of the MQCD, version 4, is 1540 bytes, of which only 1148
bytes are used for fields that are relevant to a CLNTCONN channel
definitions.  Most of that space is taken up by the various string
fields which are always fully padded with blanks.

In the version 6 format, add an additional 108 bytes of irrelevant
structure padding, and then, if message, send and/or receive exits are
used, consider the 480 bytes of fixed space in the MQCD to be wasted,
since IBM supports lists of those values in the V6 file format, and
they are tacked onto the end of the MQCD structure.  That consumes a
variable amount of space, since those values do not appear to be
padded.

=head2 File format

Many thanks to Mark Unger, who reverse engineered the file format.
Most of this section is plagiarized from the notes he made, however,
he worked for me at the time (December 2000), so I own them ;-)

The channel table is basically a doubly linked list of MQCDs.  A few
extra strings follow the MQCD as version 6 of the MQCD allows for
variable length strings to contain the list of send/receive/message
exits.  (NOTE: Message exits are not really supported for CLNTCONNs,
but the channel table file supports them as lists anyway.  IBM has yet
to explain this to me).

The channel table is an array of structures that have absolute offsets
and relative lengths in some of the fields of each structure.  All
longwords are in netword byte order (big endian).

If we think of the file as a structure it would be a 4 character magic
identifier followed by an array of channel definitions
(forward/backward links plus MQCD plus extra strings).

The forward/backwards links are used to traverse the channel
definitions during an MQCONN or DISPLAY CHL(*).  The file may contain
deleted channel definitions since the entire file is not rewritten
just to delete/add/modify a channel definition.

To traverse all channel definitions including deleted ones, for
instance when adding/modifying a channel definition, the forward link
would not be used and the file would just be read as an array of
channel definitions with some of them marked as deleted.  When adding
or modifying a channel, runmqsc will delete the channel by setting the
length of the serialized MQCD (offset 4 in the ChannelDef) to zero.

There does not appear to be a free list for the deleted channels so
runmqsc must just traverse the file as an array of channels to find
deleted channels that it will attempt to reclaim for the modified or
new channel definition.  If a deleted channel definition is not large
enough to contain the new or modified channel definition then it will
just append a new channel definition to the end of the file.

The channels are sorted in lexicographic order, with a backwards
pointer chain.  The entries in the file are therefore in reverse
order.  Getting the order wrong will cause your MQSeries client
library to hang, so you must take care not to modify the sort
algorithm.  There is one default entry in the file,
SYSTEM.DEF.CLNTCONN, which is initialized from is
MQCD_CLIENT_CONN_DEFAULT (in cmqxc.h).  Initial value of fields in any
added channels comes from SYSTEM.DEF.CLNTCONN of course.

Syntax chart:

  Offset        Type            Value           Description
  ======        ====            =====           ===========

  File:

  0             MQCHAR4         "AMQR"          Magic identifier
  4             ChannelDefList                  Channel definition list

  ChannelDefList:
  [ChannelDef ...]              0               0 terminates list of channel definitions
                                                as the first field of ChannelDef is length
                                                of the ChannelDef

  ChannelDef:
  0             MQLONG          length          length of complete channel definition
  4             MQLONG          length          length of serialized MQCD
                                                (0 if channel definition has been deleted)
  8             MQLONG          0               (appears to be unused)
  12            MQLONG          offset          forward link to next channel definition
                                                (0 if last channel definition in doubly-linked list)
  16            MQLONG          offset          backward link to previous channel definition
                                                (0 if first channel definition in doubly-linked list)
  20            SerializedMQCD                  MQCD with some additional strings fields appended

  SerializedMQCD:
  0             MQCD                            MQCD structure is defined in cmqxc.h
  sizeof(MQCD)  MQLONG          0
  +4            MQLONG          0
  +8            MQLONG          length          length of MQCDExitStrings
  +12           MQBYTE52        0
  +64           MQLONG          timestamp       alteration date/time
  +68           MQCHAR64        ' ' x 64        unknown spaces
  +132          MQCDExitStrings                 exit names and data lists

  MQCDExitStrings:
  [MsgExit 02]... 01
  [MsgUserData 02]... 01
  [SendExit 02]... 01
  [SendUserData 02]... 01
  [ReceiveExit 02]... 01
  [ReceiveUserData 02]... 01

Each exit name and user data in an exit or user data list are
terminated by byte 02.  Each list is terminated by byte 01.

=head2 Notes on MQCD

For version 6 of the MQCD, the 128 byte MsgExit, SendExit, ReceiveExit
fields are not used as well as the 32 byte MsgUserData, SendUserData,
and ReceiveUserData fields.  Those fields are only used if the MQCD is
less than version 6.  This is because version 6 for MQSeries 5.1
supports a list of exits for each of these and other fields are used
to contain this list.  The fields that were added to support these
lists are MsgExitPtr, MsgUserDataPtr, SendExitPtr, SendUserDataPtr,
ReceiveExitPtr, ReceiveUserDataPtr.  But since these are pointer
fields the value of them is zero in the MQCD and the strings are
appended to the channel definition after the MQCD.  The value of
SendExitsDefined, ...  are also zero and irrelevant even though send
exits may be defined for the channel.

The IBM documentation is not entirely clear on the use of the MsgExit
for CLNTCONN channels.  For example, the usage description of the
MsgExit attribute for channels in the "MQSeries Programmable Systems
Management" document suggests that MsgExits are B<not> supported for
CLNTCONNs, yet they are treated specially in the channel table file
itself.  However, see below...

UserIdentifier and Password fields contains data in ciphered form
provided but not opened by IBM.

=head2 IBM on channel table file format

Paul Clarke of IBM was kind enough to comment on the channel table
file format on the MQSeries mailing list (Friday, August 15, 2003 9:47
AM).  His comments are reproduced below:

  It is still true that the file does not perform garbage collection
  although it does defragment. So, you're right the file will never
  shrink. This has not, until now been viewed as an important
  requirement. Channel definitions have been treated as relatively
  static. If you change an attribute the file will only grow if you
  increase the size of channel entry ie. add another channel
  exit. Since you should always be storing your channel definitions as
  an MQSC script file (or generate them with Perl) then it is a simple
  matter to delete the file and regenerate if you believe it is bigger
  than necessary.

  As far as MsgExits is concerned, it is true that Msg Exits are not
  used in a CLNTCONN/SVRCONN connection and not invoked by either of
  these channel type. The reason is that a MsgExit takes a pointer to
  the MQXQH structure which is not involved at all in a
  CLNTCONN/SVRCONN connection. We did debate having an API exit in the
  client channels which would be passed pointers to the various
  structures involved in whatever API call was being issued. However,
  this was superceded by the API crossing exit which does a similar
  thing but for all connections both local and client. The cause of
  the confusion is that the channel table is the same format as the
  channel file. In other words, although I've never used it, I suspect
  you could use the MSDW Perl module to create a normal channel file
  full of sender and receiver channels. In this case you clearly would
  want to be able to add MsgExits.

=head1 AUTHORS

  Phil Moore
  Hildo Biersma
  Mike Surikov

=cut

