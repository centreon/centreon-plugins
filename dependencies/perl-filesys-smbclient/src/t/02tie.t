#!/usr/bin/perl -w

use Test::More;
use Filesys::SmbClient;
use strict;
#use diagnostics;
use File::Copy;
use POSIX;
use Config;

if( !$Config{'PERL_API_REVISION'} or !$Config{'PERL_VERSION'} or 
    ($Config{'PERL_API_REVISION'} != 5  or $Config{PERL_VERSION}<6)) {
  plan skip_all =>
    'tie filehandle for Filesys::SmbClient didn\'t work before Perl 5.6';
}
else {
  plan tests => 25;
}

require Filesys::SmbClient;

my $buffer = "A test of write call\n";
my $buffer2 = "buffer of 1234\n";

SKIP: {
  skip "No server defined for test at perl Makefile.PL", 25 if (!-e ".c");
  my $ok = 0;
  my (%param,$server);
  if (open(F,".c")) {
    my $l = <F>; chomp($l); 
    my @l = split(/\t/, $l);
    %param = 
      (
       username  => $l[3],
       password  => $l[4],
       workgroup => $l[2],
       debug     =>  0
      );
    $server = "smb://$l[0]/$l[1]";
  }
  my $smb = new Filesys::SmbClient(%param);

  # Create a directory
  ok($smb->mkdir("$server/toto"),"Create directory")
    or diag("With $!");

  # Create a file with open / tie
  local *FD;
  tie(*FD, 'Filesys::SmbClient',">$server/toto/tata", 0755, %param);
  ok(fileno(FD), "tie & open");

  # PRINT
  print FD $buffer;
  # PRINTF
  printf FD "%s",$buffer2;
  # PRINT IN LIST CONTEXT
  print FD "6","\n";
  # SYSWRITE
  my $lg = syswrite(FD,"6\n");
  is($lg,2,"TIE: return of syswrite");
  close(FD);
  $lg = syswrite(FD,"6\n");
  is($lg,undef,"TIE: return of syswrite on a closed filehandle");
  untie(*FD);

  # Read a file with open/tie
  my $f;
  tie(*FD,'Filesys::SmbClient',"$server/toto/tata", 0755, %param);

  # TIEHANDLE
  ok(fileno(FD),"TIE: tie & open a file") or diag("With $!");

  # try to copy file with File::Copy
  copy(\*FD, "/tmp/toto");
  ok(-e "/tmp/toto", "copy a filehandle with File::Copy");
  # SEEK
  seek(FD,0,SEEK_SET);

  # READLINE
  is(scalar<FD>,$buffer, "TIE: Read one ligne of a file");
  is(scalar<FD>,$buffer2, "TIE: Read another ligne of a file");

  # GETC
  is(getc(FD),6,"TIE: getc of a file");
  is(getc(FD),"\n","TIE: getc of a file");
  is(getc(FD),6,"TIE: getc of a file");
  is(getc(FD),"\n","TIE: getc of a file");

  # SEEK
  my $rr = seek(FD,0,SEEK_SET);
  is(getc(FD),"A","TIE: seek SEEK_SET a file");
  undef $rr;

  # READ
  $lg = read(FD,$rr,4);
  is($lg, 4,"TIE: Return of read");
  is($rr, " tes", "TIE: buffer read");

  # SEEK_CUR
  $rr = seek(FD,2,SEEK_CUR);
  is(getc(FD),"o","TIE: Seek SEEK_CUR a file open");

  # SEEK_END
  $rr = seek(FD,0,SEEK_END);
  is(getc(FD), undef, "TIE: Seek SEEK_END a file open");

  # sysread at end of file
  $lg = sysread(FD, $rr, 5);
  is($lg, 0, "TIE: sysread return 0 at end of file");
  close(FD);

  # seek closed file
  is(seek(FD,0,SEEK_SET),-1,"TIE: seek return undef on closed file");

  # read closed file
  is(read(FD,$rr,4), undef, "TIE: read return undef on closed file");

  # sysread closed file
  is(sysread(FD,$rr,4), undef, "TIE: sysread return undef on closed file");

  # Read a file with opentie in list context
  undef $f;
  open(FD,"$server/toto/tata");
  my @l2 = <FD>;
  close(FD);
  is(join('',@l2),$buffer.$buffer2."6\n"x2,
     "TIE: Read a file in list context");

  # Unlink a file
  ok($smb->unlink("$server/toto/tata"),"Unlink file")
    or diag("With $!");
  untie(*FD);

  # Opentie a non existant file
  tie(*FD,'Filesys::SmbClient',"$server/toto/tataa", 0755, %param);
  ok(!fileno(FD), "TIE: open a non-existent file");

  # Erase this directory
  ok($smb->rmdir("$server/toto/"),"Rm directory") or diag("With $!");
}