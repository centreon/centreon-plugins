#
# Authors : Nicolas CLEMENTZ nicolas.clementz@gmail.com
# 

package centreon::common::airespace::snmp::mode::userbyssid;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;
use Data::Dumper;


sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '0.2';
    $options{options}->add_options(arguments =>
                                { 
                                  "filter-ssid:s"     => { name => 'filter_ssid' },
                                  "warning:s" => { name => 'Warning' },
                                  "critical:s" => { name => 'Critical' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{Warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{Warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{Critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{Critical} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
   
    my $oid_ssid_id 	= '.1.3.6.1.4.1.14179.2.1.1.1.1';
    my $oid_ssid_name 	= '.1.3.6.1.4.1.14179.2.1.1.1.2';
    my $oid_nb_users 	= '.1.3.6.1.4.1.14179.2.1.1.1.38';

    my $ssid_id ;
    my $totaluser = 0;
    my $nb_users;
    my $ssid_name;
    my $perf_data = {};

    $self->{results} = $self->{snmp}->get_multiple_table(oids => [
		{oid =>$oid_ssid_id},
		{oid =>$oid_ssid_name},
		{oid =>$oid_nb_users}
    ]);

    foreach my $oid (keys %{$self->{results} ->{$oid_ssid_id}}){
       # Get ssid name, id and nb users 
       $ssid_id = $self->{results} ->{$oid_ssid_id}->{$oid};
       $nb_users = $self->{results} ->{$oid_nb_users}->{$oid_nb_users . ".$ssid_id"};
       $ssid_name = $self->{results} ->{$oid_ssid_name}->{$oid_ssid_name . ".$ssid_id"};
		
       # SSID filter
       if (defined($self->{option_results}->{filter_ssid}) && $self->{option_results}->{filter_ssid} ne '' &&
                           $ssid_name !~ /$self->{option_results}->{filter_ssid}/) {
          $self->{output}->output_add(long_msg => "Skipping  '" . $ssid_name . "': no matching filter.");           
          next;
       }else{
           $perf_data->{$ssid_name} = $nb_users;
       }
    }

    foreach my $ssid_name (keys %{$perf_data}){
       $self->{output}->perfdata_add(
          label => $ssid_name , 
          value => $perf_data->{$ssid_name} ,
          warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
          critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'));
       $totaluser =  $perf_data->{$ssid_name} + $totaluser;
    }
    my $exit = $self->{perfdata}->threshold_check( value => $totaluser , threshold => [ { label => 'critical' , exit_litteral => 'critical'}  , { label => 'warning' , exit_litteral => 'warning'}]);	

    $self->{output}->output_add(severity => $exit , short_msg => 'Total user : ' . $totaluser );

    $self->{output}->display();
    $self->{output}->exit();
}


1;

__END__

=head1 MODE

Check users connected by BSSID.

=over 8

=item B<--warning>

Threshold warning.


=item B<--critical>

Threshold critical.

=item B<--filter-ssid>

Filter by SSID (can be a regexp).

=back

=cut
