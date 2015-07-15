package Paws::EMR::StepExecutionStatusDetail {
  use Moose;
  has CreationDateTime => (is => 'ro', isa => 'Str', required => 1);
  has EndDateTime => (is => 'ro', isa => 'Str');
  has LastStateChangeReason => (is => 'ro', isa => 'Str');
  has StartDateTime => (is => 'ro', isa => 'Str');
  has State => (is => 'ro', isa => 'Str', required => 1);
}
1;
