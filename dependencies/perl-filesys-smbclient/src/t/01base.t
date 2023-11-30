#!/usr/bin/perl -w

use Test::More;
use Filesys::SmbClient;
use strict;
use diagnostics;

plan tests=>19;

my $loaded = 1;
ok($loaded,"Load module");

my $buffer = "A test of write call\n";
my $buffer2 = "buffer of 1234\n";

SKIP: {
  skip "No server defined for test at perl Makefile.PL", 18 if (!-e ".c");
if (-e ".c") {
  use POSIX;
  my $ok = 0;
  open(F,".c") || die "Can't read .c\n";
  my $l = <F>; chomp($l); 
  my @l = split(/\t/, $l);
  my %param = 
    (
     username  => $l[3],
     password  => $l[4],
     workgroup => $l[2],
     debug     =>  0,
#     flags     => SMBCCTX_FLAG_NO_AUTO_ANONYMOUS_LOGON
    );
  my $smb = new Filesys::SmbClient(%param);
  my $server = "smb://$l[0]/$l[1]";

  # Create a directory
  ok($smb->mkdir("$server/toto",'0666'),"Create directory")
    or diag("With $!");

  # Create a existent directory
  ok(!$smb->mkdir("$server/toto",'0666'),"Create existent directory");

  # Write a file
  my $fd = $smb->open(">$server/toto/test",0666);
  if ($fd) {
    $ok = 1 if ($smb->write($fd,$buffer));
  }
  $smb->close($fd);
  ok($ok,"Create file");
  $ok=0;

  # Rename a file
  ok($smb->rename("$server/toto/test","$server/toto/tata"),"Rename file")
    or diag("With $!");

  # Stat a file
  my @tab = $smb->stat("$server/toto/tata");
  ok($#tab != 0,"Stat file ") or diag("With $!");

  # Stat a non-existent file
  @tab = $smb->stat("smb://jupidsdsdster/soft/lala");
  ok($#tab == 0,"Stat non-existent file") or diag("With $!");

  # Read a file
  my $buf;
  $fd = $smb->open("$server/toto/tata",'0666');
  while (my $l= $smb->read($fd,50)) {$buf.=$l; }
  if (!$buf) { ok(0, "Read file"); }
  else {
    ok(length($buf) == length($buffer),"Read file")
      or diag("read ",length($buf)," bytes)");
  }
  $smb->close($fd);

  # Directory
  # Read a directory
  $fd = $smb->opendir("$server/toto"); 
  my @a;
  if ($fd) {	
    foreach my $n ($smb->readdir($fd)) {push(@a,$n);}
    $ok = 1 if ($#a==2);
    $smb->close($fd);
  }
  ok($ok,"Read short directory"); $ok=0;

  # Read long info on a directory
  undef @a;
  $fd = $smb->opendir("$server/toto");
  if ($fd) {	
    while (my $f = $smb->readdir_struct($fd)) { push(@a,$f); }
    $ok = 1 if ($#a==2);
    $smb->close($fd);
  }
  ok($ok,"Read long directory");

  # Unlink a file
  ok($smb->unlink("$server/toto/tata"),"Unlink file")
    or diag("With $!");

  # Unlink a non-existent file
  ok(!$smb->unlink("$server/toto/tatarr"),"Unlink non-existent file");

  ok($smb->mkdir("$server/toto/tate",'0666'),"Create directory")
    or diag("With $!");

  ok($smb->mkdir("$server/toto/tate/titi",'0666'),"Create directory")
    or diag("With $!");

  ok($smb->rmdir_recurse("$server/toto/tate",'0666'),
     "Rmdir entire directory") or diag("With $!");

  # Erase this directory
  ok($smb->rmdir("$server/toto/"),"Rm directory") or diag("With $!");

  # Erase non-existent directory
  ok(!$smb->rmdir("$server/totoarr/"),"Rm non-existent directory");

  # Rename a non-existent file
  ok(!$smb->rename("$server/toto/testrr","$server/toto/tata"),
     "Rename non-existent file");

  print "There is a .c file in this directory with info about your params \n",
        "for you SMB server test. Think to remove it if you have finish \n",
	  "with test.\n\n";

  ok( $smb->shutdown(0), "shutdown");
}
}