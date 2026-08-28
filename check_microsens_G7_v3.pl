#!/usr/bin/env perl
use strict;
use warnings;
use Net::SNMP;
use Getopt::Long;

Getopt::Long::Configure("bundling");

# --- OIDs spécifiques Microsens G7 ---
my %OID = (
  hostname              => '1.3.6.1.4.1.3181.10.7.1.1.22.5.0',
  uptime                => '1.3.6.1.4.1.3181.10.7.1.1.30.101.0',
  # Temp sensors
  temp_system           => '1.3.6.1.4.1.3181.10.7.1.1.30.104.0',
  temp_switch           => '1.3.6.1.4.1.3181.10.7.1.1.30.105.0',
  temp_1gphy            => '1.3.6.1.4.1.3181.10.7.1.1.30.106.0',
  temp_5gphy            => '1.3.6.1.4.1.3181.10.7.1.1.30.107.0',
  # Ports
  port_status_linkup    => '1.3.6.1.4.1.3181.10.7.1.1.81.102.1.2',
  port_status_linkstate => '1.3.6.1.4.1.3181.10.7.1.1.81.102.1.4',
  # PoE
  poe_total             => '1.3.6.1.4.1.3181.10.7.1.1.33.100.0',
  poe_perport_power     => '1.3.6.1.4.1.3181.10.7.1.1.33.101.1.6',
  # G.8032 Ring status
  g8032_ring_status     => '1.3.6.1.4.1.3181.10.7.1.2.43.7.1.2',
  # Firmware / infos système
  firmware_version      => '1.3.6.1.4.1.3181.10.7.1.1.30.109.1.0',
  serial_number         => '1.3.6.1.4.1.3181.10.7.1.1.32.2.0',
  mac_address           => '1.3.6.1.4.1.3181.10.7.1.1.30.102.0',
  cpu_usage             => '1.3.6.1.4.1.3181.10.7.1.1.30.4.0',
  mem_usage             => '1.3.6.1.4.1.3181.10.7.1.1.30.108.0',
  dns1              => '1.3.6.1.4.1.3181.10.7.1.1.22.100.5.0',
  dns2              => '1.3.6.1.4.1.3181.10.7.1.1.22.100.6.0',
  ntp1              => '1.3.6.1.4.1.3181.10.7.1.3.73.4.0',
  ntp2              => '1.3.6.1.4.1.3181.10.7.1.3.73.5.0',
  tacacs1           => '1.3.6.1.4.1.3181.10.7.1.3.76.1.6.0',
  tacacs2           => '1.3.6.1.4.1.3181.10.7.1.3.76.1.7.0',
  auth_mode         => '1.3.6.1.4.1.3181.10.7.1.3.76.1.1.0',
);

# Mapping linkstate
my %port_state = (
    0 => 'linkDown',
    1 => 'blocking',
    2 => 'learning',
    3 => 'forwarding',
    4 => 'unauthVlan',
);

# --- CLI ---
my ($host,$community,$version,$port,$timeout,$mode,$warn,$crit,$help);
my ($username,$authproto,$authpass,$privproto,$privpass);
my $debug=0;
$community='public'; $version='2c'; $port=161; $timeout=5;

GetOptions(
  "H|host=s"       => \$host,
  "C|community=s"  => \$community,
  "v|version=s"    => \$version,
  "p|port=i"       => \$port,
  "t|timeout=i"    => \$timeout,
  "m|mode=s"       => \$mode,
  "w|warning=s"    => \$warn,
  "c|critical=s"   => \$crit,
  "u|username=s"   => \$username,
  "authproto=s"    => \$authproto,
  "authpass=s"     => \$authpass,
  "privproto=s"    => \$privproto,
  "privpass=s"     => \$privpass,
  "debug!"         => \$debug,
  "h|help"         => \$help,
) or usage();

usage() if $help || !$host || !$mode;

# --- SNMP Session ---
my ($session,$error);
if ($version =~ /^3$/i) {
  my %params = (
    -hostname  => $host,
    -version   => '3',
    -port      => $port,
    -timeout   => $timeout,
    -username  => $username,
  );
  if ($authproto && $authpass) {
    $params{-authprotocol} = uc($authproto);
    $params{-authpassword} = $authpass;
  }
  if ($privproto && $privpass) {
    $params{-privprotocol} = uc($privproto);
    $params{-privpassword} = $privpass;
  }
  ($session,$error) = Net::SNMP->session(%params);
} else {
  ($session,$error) = Net::SNMP->session(
    -hostname  => $host,
    -community => $community,
    -version   => $version,
    -port      => $port,
    -timeout   => $timeout,
  );
}
if (!defined $session) { print "UNKNOWN - SNMP session error: $error\n"; exit 3; }

# --- Dispatcher ---
if    ($mode eq 'ports')       { check_ports(); }
elsif ($mode eq 'uptime')      { check_uptime(); }
elsif ($mode eq 'temperature') { check_temperature(); }
elsif ($mode eq 'poe')         { check_poe(); }
elsif ($mode eq 'g8032')       { check_g8032(); }
elsif ($mode eq 'firmware')    { check_firmware(); }
elsif ($mode eq 'system')      { check_system(); }
elsif ($mode eq 'config')      { check_config(); }
else { print "UNKNOWN - Mode $mode not supported\n"; exit 3; }

$session->close();
exit 0;

# --- Usage ---
sub usage {
  print <<"USAGE";
Usage: $0 -H <host> -m <mode> [options]
Modes: uptime | temperature | ports | poe | g8032 | firmware | system
USAGE
  exit 3;
}

# --- Checks ---

sub check_ports {
    my $port_count = 7;
    my $table = $session->get_table(-baseoid => $OID{port_status_linkstate});
    my $table2 = $session->get_table(-baseoid => $OID{port_status_linkup});
    unless (defined $table && defined $table2) {
        print "UNKNOWN - Erreur SNMP : " . $session->error() . "\n";
        exit 3;
    }

    my %port_status;
    foreach my $port (1..$port_count) {
        my $oid_linkup   = "$OID{port_status_linkup}.$port";
        my $oid_linkstat = "$OID{port_status_linkstate}.$port";

        my $linkup_val    = $table2->{$oid_linkup};
        my $linkstate_val = $table->{$oid_linkstat};

        my $linkup    = defined $linkup_val    ? ($linkup_val == 1 ? "up" : "down") : "unknown";
        my $linkstate = defined $linkstate_val ? ($port_state{$linkstate_val} // "unknown") : "unknown";

        $port_status{$port} = "$linkup/$linkstate";
    }

    print "OK - Statut des ports | ";
    foreach my $port (1..$port_count) {
        print "port_${port}=\"$port_status{$port}\" ";
    }
    print "\n";
    exit 0;
}

sub check_uptime {
  my $resp = $session->get_request($OID{uptime});
  if (!defined $resp) {
    print "UNKNOWN - ".$session->error()."\n";
    exit 3;
  }
  my $val = $resp->{$OID{uptime}};
  $val =~ s/^\s+|\s+$//g;

  my $sec;
  if ($val =~ /^\d+$/) {
    $sec = int($val/100);
  }
  elsif ($val =~ /\((\d+)\)/) {
    $sec = int($1/100);
  }
  elsif ($val =~ /(?:(\d+)\s+days?,\s*)?(\d+):(\d+):(\d+)/) {
    my ($d,$h,$m,$s) = ($1||0,$2,$3,$4);
    $sec = $d*86400 + $h*3600 + $m*60 + $s;
  }
  elsif ($val =~ /(\d+)\s+minutes?,\s*(\d+)\.(\d+)/) {
    my ($m,$s) = ($1,$2);
    $sec = $m*60 + $s;
  }
  elsif ($val =~ /(\d+)\s+hours?,\s*(\d+):(\d+)\.(\d+)/) {
    my ($h,$m,$s) = ($1,$2,$3);
    $sec = $h*3600 + $m*60 + $s;
  }
  else {
    print "UNKNOWN - unexpected uptime format: '$val'\n";
    exit 3;
  }

  my $days  = int($sec/86400);
  my $hours = int(($sec%86400)/3600);
  my $mins  = int(($sec%3600)/60);

  print "OK - Uptime ${days}d ${hours}h ${mins}m | uptime=${sec}s\n";
  exit 0;
}

sub check_temperature {
  my $resp = $session->get_request($OID{temp_system});
  if (!defined $resp) { print "UNKNOWN - ".$session->error()."\n"; exit 3; }
  my $temp = int($resp->{$OID{temp_system}});
  my ($code,$state)=(0,"OK");
  if (defined $crit && $temp >= $crit) {($code,$state)=(2,"CRITICAL");}
  elsif (defined $warn && $temp >= $warn) {($code,$state)=(1,"WARNING");}
  print "$state - Température $temp C | temp=$temp;$warn;$crit\n";
  exit $code;
}

sub check_poe {
  my $resp = $session->get_request($OID{poe_total});
  if (!defined $resp) { print "UNKNOWN - ".$session->error()."\n"; exit 3; }
  my $total = $resp->{$OID{poe_total}};
  my $table = $session->get_table($OID{poe_perport_power});
  my $perf="total=$total "; my $out="Total=$total W; ";
  for my $oid (keys %$table) {
    if ($oid =~ /\.(\d+)$/) {
      my $idx=$1; my $val=$table->{$oid};
      $perf.="poe$idx=$val ";
      $out.="P$idx=${val}W ";
    }
  }
  my ($code,$state)=(0,"OK");
  if (defined $crit && $total >= $crit) {($code,$state)=(2,"CRITICAL");}
  elsif (defined $warn && $total >= $warn) {($code,$state)=(1,"WARNING");}
  print "$state - $out | $perf\n";
  exit $code;
}

sub check_firmware {
  my $resp = $session->get_request($OID{firmware_version});
  if (!defined $resp) { print "UNKNOWN - ".$session->error()."\n"; exit 3; }
  my $version = $resp->{$OID{firmware_version}};
  print "OK - Firmware version: $version | firmware=\"$version\"\n";
  exit 0;
}

sub check_config {
    my @wanted = qw(dns1 dns2 ntp1 ntp2 tacacs1 tacacs2 auth_mode);
    my @oids;
    my %key_by_oid;
    for my $k (@wanted) {
        next unless defined $OID{$k} && $OID{$k} ne '';
        push @oids, $OID{$k};
        $key_by_oid{$OID{$k}} = $k;
    }

    unless (@oids) {
        print "UNKNOWN - aucun OID configuré pour check_config\n";
        exit 3;
    }

    my $resp = $session->get_request(-varbindlist => \@oids);
    unless (defined $resp) {
        print "UNKNOWN - ".$session->error()."\n";
        exit 3;
    }

    my %res;
    for my $oid (@oids) {
        my $k = $key_by_oid{$oid};
        $res{$k} = $resp->{$oid} // '';
    }

    # --- logique de vérification ---
    my ($code,$state,$msg) = (0,"OK","Config correcte");

    # DNS
    my $dns_missing = 0;
    $dns_missing++ unless $res{dns1};
    $dns_missing++ unless $res{dns2};
    if ($dns_missing == 1) { ($code,$state,$msg) = (1,"WARNING","Un seul DNS configuré"); }
    elsif ($dns_missing == 2) { ($code,$state,$msg) = (2,"CRITICAL","Aucun DNS configuré"); }

    # NTP
    unless ($res{ntp1} || $res{ntp2}) {
        ($code,$state,$msg) = (1,"WARNING","Aucun serveur NTP configuré") if $code < 1;
    }

    # TACACS
    my $tacacs_missing = 0;
    $tacacs_missing++ unless $res{tacacs1};
    $tacacs_missing++ unless $res{tacacs2};
    if ($tacacs_missing == 2) { ($code,$state,$msg) = (2,"CRITICAL","Aucun serveur TACACS configuré"); }
    elsif ($tacacs_missing == 1 && $code < 2) { ($code,$state,$msg) = (1,"WARNING","Un seul serveur TACACS configuré"); }

    print "$state - $msg | dns1=\"$res{dns1}\" dns2=\"$res{dns2}\" ntp1=\"$res{ntp1}\" ntp2=\"$res{ntp2}\" tacacs1=\"$res{tacacs1}\" tacacs2=\"$res{tacacs2}\" auth_mode=\"$res{auth_mode}\"\n";
    exit $code;
}

sub check_system {
    my $resp = $session->get_request(
        -varbindlist => [
            $OID{hostname},
            $OID{serial_number},
            $OID{mac_address},
            $OID{cpu_usage},
            $OID{mem_usage},
            $OID{temp_system}
        ]
    );

    unless (defined $resp) {
        print "UNKNOWN - ".$session->error()."\n";
        exit 3;
    }

    my $host   = $resp->{$OID{hostname}}       // "";
    my $serial = $resp->{$OID{serial_number}}  // "";
    my $mac    = $resp->{$OID{mac_address}}    // "";
    my $cpu    = $resp->{$OID{cpu_usage}}      // 0;
    my $mem    = $resp->{$OID{mem_usage}}      // 0;
    my $temp   = $resp->{$OID{temp_system}}    // 0;

    print "OK - Host=$host Serial=$serial MAC=$mac CPU=${cpu}% MEM=${mem}% TEMP=${temp}C ".
          "| cpu=$cpu mem=$mem temp=$temp\n";
    exit 0;
}

sub check_g8032 {
    my $base = $OID{g8032_ring_status};
    my $oid1 = $base.".1";
    my $resp = $session->get_request(-varbindlist => [$oid1]);

    my $val;
    if (defined $resp && exists $resp->{$oid1}) {
        $val = $resp->{$oid1};
    } else {
        my $table = $session->get_table(-baseoid => $base);
        if (!defined $table) {
            print "UNKNOWN - ".$session->error()."\n";
            exit 3;
        }
        my ($first_oid) = sort keys %$table;
        $val = $table->{$first_oid};
    }

    my $numeric = int($val);
    my ($code,$state,$label);

    if ($numeric == 1 || $numeric == 3) {
        ($code,$state,$label) = (0,"OK","ok");
    }
    elsif ($numeric == 2 || $numeric == 4) {
        ($code,$state,$label) = (1,"WARNING","warning");
    }
    elsif ($numeric == 5) {
        ($code,$state,$label) = (2,"CRITICAL","critical");
    }
    else {
        ($code,$state,$label) = (3,"UNKNOWN","value=$numeric");
    }

    print "$state - Ring1=$label | ring1=$numeric\n";
    exit $code;
}

