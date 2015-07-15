
package Paws::CloudHSM::DescribeHapgResponse {
  use Moose;
  has HapgArn => (is => 'ro', isa => 'Str');
  has HapgSerial => (is => 'ro', isa => 'Str');
  has HsmsLastActionFailed => (is => 'ro', isa => 'ArrayRef[Str]');
  has HsmsPendingDeletion => (is => 'ro', isa => 'ArrayRef[Str]');
  has HsmsPendingRegistration => (is => 'ro', isa => 'ArrayRef[Str]');
  has Label => (is => 'ro', isa => 'Str');
  has LastModifiedTimestamp => (is => 'ro', isa => 'Str');
  has PartitionSerialList => (is => 'ro', isa => 'ArrayRef[Str]');
  has State => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::CloudHSM::DescribeHapgResponse

=head1 ATTRIBUTES

=head2 HapgArn => Str

  

The ARN of the high-availability partition group.









=head2 HapgSerial => Str

  

The serial number of the high-availability partition group.









=head2 HsmsLastActionFailed => ArrayRef[Str]

  
=head2 HsmsPendingDeletion => ArrayRef[Str]

  
=head2 HsmsPendingRegistration => ArrayRef[Str]

  
=head2 Label => Str

  

The label for the high-availability partition group.









=head2 LastModifiedTimestamp => Str

  

The date and time the high-availability partition group was last
modified.









=head2 PartitionSerialList => ArrayRef[Str]

  

The list of partition serial numbers that belong to the
high-availability partition group.









=head2 State => Str

  

The state of the high-availability partition group.











=cut

1;