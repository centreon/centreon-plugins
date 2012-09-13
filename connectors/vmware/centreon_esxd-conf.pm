our $port = 5700;
our $service_url = "https://srvi-vcenter.merethis.net/sdk";
our $username = "xxxxx";
our $password = 'xxxxx';
our $TIMEOUT_VSPHERE = 60;
our $TIMEOUT = 60;
our $TIMEOUT_KILL = 30;
our $REFRESH_KEEPER_SESSION = 15;
# Log Mode: 0 = stdout, 1 = file, 2 = syslog
our $log_mode = 1;
# # Criticity: 0 = nothing, 1 = critical, 2 = all
our $log_crit = 1;
# Specify if $log_mode = 2 and CPAN Module Unix::Syslog is installed
our $log_facility;
#our $log_facility = LOG_DAEMON;
our $LOG = "/tmp/centreon_esxd.log";

1;
