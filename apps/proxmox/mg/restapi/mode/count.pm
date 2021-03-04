package apps::proxmox::mg::restapi::mode::count;

use base qw(centreon::plugins::mode);

use List::Util qw(max);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
      'warning:s'           => { name => 'warning' },
      'critical:s'          => { name => 'critical' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
     $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
     $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
}

sub manage_selection {
  my ($self, %options) = @_;
  $self->{counts} = $options{custom}->api_recent_count();
}

sub run {
  my ($self, %options) = @_;
  $self->manage_selection(%options);
  foreach my $count_id (max(keys %{$self->{counts}})) {
      my $exit ='';
      if ($self->{counts}->{$count_id}->{Count_out} <= $self->{counts}->{$count_id}->{Count_in}){
        $exit = $self->{perfdata}->threshold_check(value => $self->{counts}->{$count_id}->{Count_in}, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
      }elsif ($self->{counts}->{$count_id}->{Count_out} > $self->{counts}->{$count_id}->{Count_in}){
        $exit = $self->{perfdata}->threshold_check(value => $self->{counts}->{$count_id}->{Count_out}, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
      }

      $self->{output}->output_add(
          severity => $exit,
          short_msg =>
              "[count_in = '" . $self->{counts}->{$count_id}->{Count_in} . "']".
              "[count_out = '" . $self->{counts}->{$count_id}->{Count_out} . "']"
      );
      $self->{output}->perfdata_add(
          label =>'mail_in',
          value =>$self->{counts}->{$count_id}->{Count_in},
          unit  => 'B',
          warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
          critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
          min   => 0
      );
      $self->{output}->perfdata_add(
          label =>'mail_out',
          value =>$self->{counts}->{$count_id}->{Count_out},
          unit  => 'B',
          warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
          critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
          min   => 0
      );
  }

  $self->{output}->display( force_long_output => 1);
  $self->{output}->exit();
}

1;

__END__

=head1 MODE

=over 8

=item B<--warning>

=item B<--critical>

=back

=cut
