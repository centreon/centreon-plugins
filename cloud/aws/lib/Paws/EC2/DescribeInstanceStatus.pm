
package Paws::EC2::DescribeInstanceStatus {
  use Moose;
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has Filters => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Filter]', traits => ['NameInRequest'], request_name => 'Filter' );
  has IncludeAllInstances => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'includeAllInstances' );
  has InstanceIds => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'InstanceId' );
  has MaxResults => (is => 'ro', isa => 'Int');
  has NextToken => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeInstanceStatus');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::DescribeInstanceStatusResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeInstanceStatus - Arguments for method DescribeInstanceStatus on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeInstanceStatus on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method DescribeInstanceStatus.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeInstanceStatus.

As an example:

  $service_obj->DescribeInstanceStatus(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 Filters => ArrayRef[Paws::EC2::Filter]

  

One or more filters.

=over

=item *

C<availability-zone> - The Availability Zone of the instance.

=item *

C<event.code> - The code for the scheduled event (C<instance-reboot> |
C<system-reboot> | C<system-maintenance> | C<instance-retirement> |
C<instance-stop>).

=item *

C<event.description> - A description of the event.

=item *

C<event.not-after> - The latest end time for the scheduled event (for
example, C<2014-09-15T17:15:20.000Z>).

=item *

C<event.not-before> - The earliest start time for the scheduled event
(for example, C<2014-09-15T17:15:20.000Z>).

=item *

C<instance-state-code> - The code for the instance state, as a 16-bit
unsigned integer. The high byte is an opaque internal value and should
be ignored. The low byte is set based on the state represented. The
valid values are 0 (pending), 16 (running), 32 (shutting-down), 48
(terminated), 64 (stopping), and 80 (stopped).

=item *

C<instance-state-name> - The state of the instance (C<pending> |
C<running> | C<shutting-down> | C<terminated> | C<stopping> |
C<stopped>).

=item *

C<instance-status.reachability> - Filters on instance status where the
name is C<reachability> (C<passed> | C<failed> | C<initializing> |
C<insufficient-data>).

=item *

C<instance-status.status> - The status of the instance (C<ok> |
C<impaired> | C<initializing> | C<insufficient-data> |
C<not-applicable>).

=item *

C<system-status.reachability> - Filters on system status where the name
is C<reachability> (C<passed> | C<failed> | C<initializing> |
C<insufficient-data>).

=item *

C<system-status.status> - The system status of the instance (C<ok> |
C<impaired> | C<initializing> | C<insufficient-data> |
C<not-applicable>).

=back










=head2 IncludeAllInstances => Bool

  

When C<true>, includes the health status for all instances. When
C<false>, includes the health status for running instances only.

Default: C<false>










=head2 InstanceIds => ArrayRef[Str]

  

One or more instance IDs.

Default: Describes all your instances.

Constraints: Maximum 100 explicitly specified instance IDs.










=head2 MaxResults => Int

  

The maximum number of results to return for the request in a single
page. The remaining results of the initial request can be seen by
sending another request with the returned C<NextToken> value. This
value can be between 5 and 1000; if C<MaxResults> is given a value
larger than 1000, only 1000 results are returned. You cannot specify
this parameter and the instance IDs parameter in the same request.










=head2 NextToken => Str

  

The token to retrieve the next page of results.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeInstanceStatus in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

