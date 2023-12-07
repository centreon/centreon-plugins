package Filesys::SmbClient;
 
# module Filesys::SmbClient : provide function to access Samba filesystem
# with libsmclient.so
# Copyright 2000-2012 A.Barbet alian@cpan.org.  All rights reserved.

# $Log: SmbClient.pm,v $
# Revision 4.0 compatible samba4 only 
#
# Revision 3.2 2012/12/04 14:49:32  alian
#
# release 3.2: implements connection close with smbc_free_context (acca@cpan.org)
#
# release 3.1: fix for rt#12221 rt#18757 rt#13173 and bug in configure
#
# Revision 3.0  2005/03/04 16:15:00  alian
# 3.0  2005/03/05 alian
#  - Update to samba3 API and use SMBCTXX
#  - Add set_flag method for samba 3.0.11
#  - Update smb2www-2.cgi to browse workgroup with smb://
#  - Return 0 not undef at end of file with read/READLINE
#   (tks to jonathan.segal at genizon.com for report).
#  - Fix whence bug in seek method (not used before)
#  - Add some tests for read and seek patched in this version
#
# Revision 1.5  2003/11/09 18:28:01  alian
# Add Copyright section
#
# See file CHANGES for others update

use strict;
use constant SMBC_WORKGROUP  => 1;
use constant SMBC_SERVER => 2;
use constant SMBC_FILE_SHARE => 3;
use constant SMBC_PRINTER_SHARE => 4;
use constant SMBC_COMMS_SHARE => 5;
use constant SMBC_IPC_SHARE =>6;
use constant SMBC_DIR => 7;
use constant SMBC_FILE => 8;
use constant SMBC_LINK => 9;
use constant MAX_LENGTH_LINE => 4096;

use vars qw($AUTOLOAD $VERSION @ISA @EXPORT);
require Exporter;
require DynaLoader;
require AutoLoader;
use POSIX 'SEEK_SET';

use Tie::Handle;
my $DEBUG = 0;

@ISA = qw(Exporter DynaLoader Tie::Handle);
@EXPORT = qw(SMBC_DIR SMBC_WORKGROUP SMBC_SERVER SMBC_FILE_SHARE
	     SMBC_PRINTER_SHARE SMBC_COMMS_SHARE SMBC_IPC_SHARE SMBC_FILE
	     SMBC_LINK _write _open _close _read _lseek);
$VERSION = ('$Revision: 4.0 $ ' =~ /(\d+\.\d+)/)[0];

bootstrap Filesys::SmbClient $VERSION;

my %commandes =
  (
   "close"            => \&_close,
   "closedir"         => \&_closedir,
   "fstat"            => \&_fstat,
   "opendir"          => \&_opendir,
   "print_file"       => \&_print_file,
   "stat"             => \&_stat,
   "rename"           => \&_rename,
   "rmdir"            => \&_rmdir,
   "unlink"           => \&_unlink,
   "unlink_print_job" => \&_unlink_print_job,
  );

#------------------------------------------------------------------------------
# AUTOLOAD
#------------------------------------------------------------------------------
sub AUTOLOAD  {
  my $self =shift;
  my $attr = $AUTOLOAD;
  $attr =~ s/.*:://;
  return unless $attr =~ /[^A-Z]/;
  die "Method undef ->$attr()\n" unless defined($commandes{$attr});
  return $commandes{$attr}->($self->{context}, @_);
}

#------------------------------------------------------------------------------
# TIEHANDLE
#------------------------------------------------------------------------------
sub TIEHANDLE {
  require 5.005_64;
  my ($class,$fn,$mode,@args) = @_;
  $mode = '0666' if (!$mode);
  my $self = new($class, @args);
  print "Filesys::SmbClient TIEHANDLE\n" if ($DEBUG);
  if ($fn) {
    $self->{FD} = _open($self->{context}, $fn, $mode) or return undef; }
  return $self;
}

#------------------------------------------------------------------------------
# OPEN
#------------------------------------------------------------------------------
sub OPEN {
  my ($class,$fn,$mode) = @_;
  $mode = '0666' if (!$mode);
  print "OPEN\n"  if ($DEBUG);
  $class->{FD} = _open($class->{context}, $fn, $mode) or return undef;
  $class;
}

#------------------------------------------------------------------------------
# FILENO
#------------------------------------------------------------------------------
sub FILENO {
  my $class = shift;
  return $class->{FD};
}

#------------------------------------------------------------------------------
# WRITE
#------------------------------------------------------------------------------
sub WRITE {
  my ($self,$buffer,$length,$offset) = @_;
  print "Filesys::SmbClient WRITE\n"  if ($DEBUG);
  $buffer = substr($buffer,0,$length) if ($length);
  SEEK($self,$offset, SEEK_SET) if ($offset);
  my $lg = _write($self->{context}, $self->{FD}, $buffer, $length);
  return ($lg == -1) ? undef : $lg;
}

#------------------------------------------------------------------------------
# SEEK
#------------------------------------------------------------------------------
sub SEEK {
  my ($self,$offset,$whence) = @_;
  print "Filesys::SmbClient SEEK\n"  if ($DEBUG);
  return _lseek($self->{context}, $self->{FD}, $offset, $whence);
}

#------------------------------------------------------------------------------
# READ
#------------------------------------------------------------------------------
sub READ {
  my $self = shift;
  print "Filesys::SmbClient READ\n" if ($DEBUG);
  my $buf = \$_[0];
  my $lg = ($_[1] ? $_[1] : MAX_LENGTH_LINE);
  # 
  defined($$buf = _read($self->{context}, $self->{FD}, $lg)) or return undef;
#  $$buf = _read($self->{context}, $self->{FD}, $lg) or return undef;
  return length($$buf);
}

#------------------------------------------------------------------------------
# READLINE
#------------------------------------------------------------------------------
sub READLINE {
  my $self = shift;
  print "Filesys::SmbClient READLINE\n" if ($DEBUG);
  # Check if we have \n on old string
  my $buf = $self->{_BUFFER};
  if ($buf && $buf=~m!^([^\n]*\n)(.*)$!ms) {
    print "Gave ->$1<- and take ->$2<-\n" if ($self->{params}->{debug});
    my $p = $1;
    $self->{_BUFFER} = $2;
    return wantarray() ? ($p,$self->READLINE) : $p;
  }
  # Read while we haven't \n or eof
  my $part;
  READ($self,$part,MAX_LENGTH_LINE);
  while ($part and $part!~m!\n!ms and $self->{_FD}) {
    $buf.=$part;
    $part = $self->read($self->{_FD}, @_);
  }
  $buf.= $part if ($part);
  # eof
  return (wantarray() ? "" : undef) if (!$buf);
  # Return first line and save rest in $self->{_BUFFER}
  if ($buf=~m!^([^\n]*\n)(.*)$!ms) {
    print "Give ->$1<- and take ->$2<-\n" if ($self->{params}->{debug});
    $self->{_BUFFER} = $2;
    return wantarray() ? ($1,$self->READLINE) : $1;
  }
  undef $self->{_BUFFER};
  return wantarray() ? ($buf,$self->READLINE) : $buf;
}

#------------------------------------------------------------------------------
# GETC
#------------------------------------------------------------------------------
sub GETC {
  my $self = shift;
  my $c;
  print "Filesys::SmbClient GETC\n" if ($DEBUG);
  if ($self->{_BUFFER}) {
    print "Filesys::SmbClient GETC using $self->{_BUFFER}\n" 
      if ($self->{params}->{debug});
    $c = substr($self->{_BUFFER},0,1);
    $self->{_BUFFER} = substr($self->{_BUFFER},1);
    return $c;
  }
  READ($self,$c,1) or return undef;
  return $c;
}

#------------------------------------------------------------------------------
# CLOSE
#------------------------------------------------------------------------------
sub CLOSE {
  my $self = shift;
  print "Filesys::SmbClient CLOSE\n" if ($DEBUG);
  _close($self->{context}, $self->{FD});
}

#------------------------------------------------------------------------------
# UNTIE
#------------------------------------------------------------------------------
sub UNTIE {
  require 5.005_64;
  my $self=shift;
  print "Filesys::SmbClient UNTIE\n" if ($DEBUG);
  CLOSE($self);
  undef($self->{_BUFFER});
}

#------------------------------------------------------------------------------
# new
#------------------------------------------------------------------------------
sub new   {
  my $class = shift;
  my $self = {};
  my @l; 
  bless $self, $class;
  my %vars;
  if (@_) {
    %vars =@_;
    if (!$vars{'workgroup'}) { $vars{'workgroup'}=""; }
    if (!$vars{'username'})  { $vars{'username'}=""; }
    if (!$vars{'password'})  { $vars{'password'}=""; }
    if (!$vars{'debug'})     { $vars{'debug'}=0; }
    push(@l, $vars{'username'});
    push(@l, $vars{'password'});
    push(@l, $vars{'workgroup'});
    push(@l, $vars{'debug'});
    print "Filesys::SmbClient new>",join(" ", @l),"\n" if $vars{'debug'};
    $self->{params}= \%vars;
  }
  else { @l =("","","",0); }

  $self->{context} = _init(@l);
  if ($vars{'useKerberos'}) { _setOptionUseKerberos($self->{context}, $vars{'useKerberos'}); };
  if ($vars{'noAutoAnonymousLogin'}) { _setOptionNoAutoAnonymousLogin($self->{context}, $vars{'noAutoAnonymousLogin'}); };
  if ($vars{'fallbackAfterKerberos'}) { _setOptionFallbackAfterKerberos($self->{context}, $vars{'fallbackAfterKerberos'}); };
  if ($vars{'timeout'} && $vars{'timeout'} =~ /^[0-9]+$/) { _setTimeout($self->{context}, $vars{'timeout'}); };
  if ($vars{'port'} && $vars{'port'} =~ /^[0-9]+$/) { _setPort($self->{context}, $vars{'port'}); };
  return $self;
}

#------------------------------------------------------------------------------
# readdir_struct
#------------------------------------------------------------------------------
sub readdir_struct  {
  my $self=shift;
  if (wantarray()) {
    my @tab;
    while (my @l  = _readdir($self->{context}, $_[0])) { push(@tab,\@l); }
    return @tab;
  } else {
    my @l = _readdir($self->{context}, $_[0]);
    return \@l if (@l);
  }
}

#------------------------------------------------------------------------------
# readdir
#------------------------------------------------------------------------------
sub readdir {
  my $self=shift;
  if (wantarray()) {
    my @tab;
    while (my @l  = _readdir($self->{context}, $_[0])) { push(@tab,$l[1]);}
    return @tab;
  } else {
    my @l =_readdir($self->{context}, $_[0]);
    return $l[1];
  }
}

#------------------------------------------------------------------------------
# open
#------------------------------------------------------------------------------
sub open  {
  my ($self,$file,$perms)=@_;
  $perms = '0666' if (!$perms);
  $self->{_FD} = _open($self->{context}, $file, $perms);
  print "Filesys::SmbClient open <$self->{_FD}>\n" 
    if ($self->{params}->{debug});
  return $self->{_FD};
}

#------------------------------------------------------------------------------
# seek
#------------------------------------------------------------------------------
sub seek {
  my ($self,$fd,$offset,$whence) = @_;
  return -1 if ($fd == -1);
  print "Filesys::SmbClient seek\n" if ($self->{params}->{debug});
  $whence = SEEK_SET if (!$whence);
  warn "Whence diff from SEEK_SET not implemented in smb"
    if ($whence ne SEEK_SET);
  return _lseek($self->{context}, $fd, $offset, SEEK_SET);
}

#------------------------------------------------------------------------------
# write
#------------------------------------------------------------------------------
sub write  {
  my $self = shift;
  my $fd = shift;
  print "Filesys::SmbClient write ".$self.' '.$fd.' '.join(" ",@_)."\n"
    if ($self->{params}->{debug});
  my $buffer = join("",@_);
  return _write($self->{context}, $fd, $buffer, length($buffer));
}

#------------------------------------------------------------------------------
# read
#------------------------------------------------------------------------------
sub read  {
  my ($self,$fd,$lg)=@_;
  $lg = MAX_LENGTH_LINE if (!$lg);
  return _read($self->{context}, $fd, $lg);
}

#------------------------------------------------------------------------------
# mkdir
#------------------------------------------------------------------------------
sub mkdir  {
  my ($self,$dir,$mode)=@_;
  $mode = '0755' if (!$mode);
  return _mkdir($self->{context}, $dir, $mode);
}

#------------------------------------------------------------------------------
# rmdir_recurse
#------------------------------------------------------------------------------
sub rmdir_recurse  {
  my $self=shift;
  my $url = shift;
  my $fd = $self->opendir($url) || return undef;
  my @f = $self->readdir_struct($fd);
  $self->closedir($fd);
  foreach my $v (@f) {
    next if ($v->[1] eq '.' or $v->[1] eq '..');
    my $u = $url."/".$v->[1];
    if ($v->[0] == SMBC_FILE) { $self->unlink($u); }
    elsif ($v->[0] == SMBC_DIR) { $self->rmdir_recurse($u); }
  }
  return $self->rmdir($url);
}

#------------------------------------------------------------------------------
# shutdown
#------------------------------------------------------------------------------
sub shutdown  {
  my ($self, $flag)=@_;
  return _shutdown($self->{context}, $flag);
}

1;

__END__

#------------------------------------------------------------------------------

=pod

=head1 NAME

Filesys::SmbClient - Interface for access Samba filesystem with libsmclient.so

=head1 SYNOPSIS

  use POSIX;
  use Filesys::SmbClient;
  
  my $smb = new Filesys::SmbClient(username  => "alian",
				   password  => "speed",
				   workgroup => "alian",
				   debug     => 10);
  
  # Read a file
  my $fd = $smb->open("smb://jupiter/doc/general.css", '0666');
  while (defined(my $l= $smb->read($fd,50))) {print $l; }
  $smb->close(fd);
  
  # ...

See section EXAMPLE for others scripts.

=head1 DESCRIPTION

Provide interface to access routine defined in libsmbclient.so provided with
Samba.

Since 3.0 release of this package, you need a least samba-3.0.2.
For prior release of Samba, use Filesys::SmbClient version 1.x.

For old and 2.x release, this library is available on Samba source, but is not
build by default.
Do "make bin/libsmbclient.so" in sources directory of Samba to build 
this libraries. Then copy source/include/libsmbclient.h to
/usr/local/samba/include and source/bin/libsmbclient.so to
/usr/local/samba/lib before install this module.

If you want to use filehandle with this module, you need Perl 5.6 or later.

When a path is used, his scheme is :

  smb://server/share/rep/doc

=head1 VERSION

$Revision: 3.2 $

=head1 FONCTIONS

=over

=item new %hash

Init connection
Hash can have this keys:

=over

=item *

username

=item *

password

=item *

workgroup

=item *

debug

=back

Return instance of Filesys::SmbClient on succes, die with error else.

Example:

  my $smb = new Filesys::SmbClient(username  => "alian",
				   password  => "speed", 
				   workgroup => "alian",
				   debug     => 10);

=back

=head2 Tie Filesys::SmbClient filehandle

This didn't work before 5.005_64. Why, I don't know.
When you have tied a filehandle with Filesys::SmbClient,
you can call classic methods for filehandle:
print, printf, seek, syswrite, getc, open, close, read.
See perldoc for usage.

Example:

  local *FD;
  tie(*FD, 'Filesys::SmbClient');
  open(FD,"smb://jupiter/doc/test")
    or print "Can't open file:", $!, "\n";
  while(<FD>) { print $_; }
  close(FD);

or

  local *FD;
  tie(*FD, 'Filesys::SmbClient');
  open(FD,">smb://jupiter/doc/test")
    or print "Can't create file:", $!, "\n";
  print FD "Samba test","\n";
  printf FD "%s", "And that work !\n";
  close(FD);


=head2 Directory

=over

=item mkdir FILENAME, MODE

Create directory $fname with permissions set to $mode.
Return 1 on success, else 0 is return and errno and $! is set.

Example:

  $smb->mkdir("smb://jupiter/doc/toto",'0666') 
    or print "Error mkdir: ", $!, "\n";

=item rmdir FILENAME

Erase directory $fname. Return 1 on success, else 0 is return
and errno and $! is set. ($fname must be empty, else see 
rmdir_recurse).

Example:

  $smb->rmdir("smb://jupiter/doc/toto")
    or print "Error rmdir: ", $!, "\n";

=item rmdir_recurse FILENAME

Erase directory $fname. Return 1 on success, else 0 is return
and errno and $! is set. Il $fname is not empty, all files and
dir will be deleted.

Example:

  $smb->rmdir_recurse("smb://jupiter/doc/toto")
    or print "Error rmdir_recurse: ", $!, "\n";

=item opendir FILENAME

Open directory $fname. Return file descriptor on succes, else 0 is
return and $! is set.

=item readdir FILEHANDLE

Read a directory. In a list context, return the full content of
the directory $fd, else return next element. Each elem is
a name of a directory or files.

Return undef at end of directory.

Example:

  my $fd = $smb->opendir("smb://jupiter/doc");
  foreach my $n ($smb->readdir($fd)) {print $n,"\n";}
  close($fd);

=item readdir_struct FILEHANDLE

Read a directory. In a list context, return the full content of
the directory FILEHANDLE, else return next element. Each element
is a ref to an array with type, name and comment. Type can be :

=over

=item SMBC_WORKGROUP

=item SMBC_SERVER

=item SMBC_FILE_SHARE

=item SMBC_PRINTER_SHARE

=item SMBC_COMMS_SHARE

=item SMBC_IPC_SHARE

=item SMBC_DIR

=item SMBC_FILE

=item SMBC_LINK

=back

Return undef at end of directory.

Example:

  my $fd = $smb->opendir("smb://jupiter/doc");
  while (my $f = $smb->readdir_struct($fd)) {
    if ($f->[0] == SMBC_DIR) {print "Directory ",$f->[1],"\n";}
    elsif ($f->[0] == SMBC_FILE) {print "File ",$f->[1],"\n";}
    # ...
  }
  close($fd);

=item closedir FILEHANDLE

Close directory $fd.

=back

=head2 Files

=over

=item stat FILENAME

Stat a file FILENAME. Return a list with info on success,
else an empty list is return and $! is set.

List is made with:

=over

=item *

device

=item *

inode

=item *

protection

=item *

number of hard links

=item *

user ID of owner

=item *

group ID of owner

=item *

device type (if inode device)

=item *

total size, in bytes

=item *

blocksize for filesystem I/O

=item *

number of blocks allocated

=item *

time of last access

=item *

time of last modification

=item *

time of last change

=back

Example:

  my @tab = $smb->stat("smb://jupiter/doc/tata");
  if ($#tab == 0) { print "Erreur in stat:", $!, "\n"; }
  else {
    for (10..12) {$tab[$_] = localtime($tab[$_]);}
    print join("\n",@tab);
  }

=item fstat FILEHANDLE

Like stat, but on a file handle

=item rename OLDNAME,NEWNAME

Changes the name of a file; an existing file NEWNAME will be clobbered.
Returns true for success, false otherwise, with $! set.

Example:

  $smb->rename("smb://jupiter/doc/toto","smb://jupiter/doc/tata")
    or print "Can't rename file:", $!, "\n";

=item unlink FILENAME

Unlink FILENAME. Return 1 on success, else 0 is return
and errno and $! is set.

Example:

  $smb->unlink("smb://jupiter/doc/test") 
    or print "Can't unlink file:", $!, "\n";


=item open FILENAME

=item open FILENAME, MODE

Open file $fname with perm $mode. Return file descriptor
on success, else 0 is return and $! is set.

Example:

  my $fd = $smb->open("smb://jupiter/doc/test", 0666) 
    or print "Can't read file:", $!, "\n";
  
  my $fd = $smb->open(">smb://jupiter/doc/test", 0666) 
    or print "Can't create file:", $!, "\n";
  
  my $fd = $smb->open(">>smb://jupiter/doc/test", 0666) 
    or print "Can't append to file:", $!, "\n";

=item read FILEHANDLE

=item read FILEHANDLE, LENGTH

Read $count bytes of data on file descriptor $fd. It lenght is not set,
4096 bytes will be read.

Return buffer read on success, undef at end of file,
-1 is return on error and $! is set.

FILEHANDLE must be open with open of this module.

=item write FILEHANDLE, $buf

=item write FILEHANDLE, @buf

Write $buf or @buf on file descriptor $fd.
Return number of bytes wrote, else -1 is return and errno and $! is set.

Example:

  my $fd = $smb->open(">smb://jupiter/doc/test", 0666) 
    or print "Can't create file:", $!, "\n";
  $smb->write($fd, "A test of write call") 
    or print $!,"\n";
  $smb->close($fd);

FILEHANDLE must be open with open of this module.

=item seek FILEHANDLE, POS

Sets FILEHANDLE's position, just like the "fseek"
call of "stdio".  FILEHANDLE may be an expression
whose value gives the name of the filehandle.  The
values for WHENCE is always SEEK_SET beacause others
didn't work on libsmbclient.so

FILEHANDLE must be open with open of this module.

=item close FILEHANDLE

Close file FILEHANDLE. Return 0 on success, else -1 is return and
errno and $! is set.

=back

=item shutdown flag

A wrapper around `libsmbclient's `smbc_free_context'.

Close open files, release Samba connection, delete context,
aquired during open_* calls.

Example:

    $smb->shutdown(0); # Gracefully close connection
    $sbm->shutdown(1); # Forcibly close files and connection

NOTE:
    shutdown(1) may cause complaints about talloc memory
    leaks, if there are currently no open files.

=head2 Print method

=over

=item unlink_print_job PRINTER_URL, IDJOB

Remove job number IDJOB on printer PRINTER_URL

=item print_file DOCUMENT_URL, PRINTER_URL

Print file DOCUMENT_URL on PRINTER_URL

=back

=head1 TODO

=over 

=item *

chown

=item *

chmod

=item *

open_print_job

=item *

telldir

=item *

lseekdir

=back

=head1 EXAMPLE

This module come with some scripts:

=over

=item t/*.t

Just for check that this module is ok :-)

=item smb2www-2.cgi

A CGI interface with these features:

=over

=item *

browse workgroup ,share, dir

=item *

read file

=item *

upload file

=item *

create directory

=item *

unlink file, directory

=back

=back

=head1 COPYRIGHT

The Filesys-SmbClient module is Copyright (c) 1999-2003 Alain BARBET, France,
alian at cpan.org. All rights reserved.

You may distribute under the terms of either the GNU General
Public License or the Artistic License, as specified
in the Perl README file.

=cut