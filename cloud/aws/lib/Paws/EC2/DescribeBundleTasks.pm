
package Paws::EC2::DescribeBundleTasks {
  use Moose;
  has BundleIds => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'BundleId' );
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has Filters => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Filter]', traits => ['NameInRequest'], request_name => 'Filter' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeBundleTasks');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::DescribeBundleTasksResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeBundleTasks - Arguments for method DescribeBundleTasks on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeBundleTasks on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method DescribeBundleTasks.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeBundleTasks.

As an example:

  $service_obj->DescribeBundleTasks(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 BundleIds => ArrayRef[Str]

  

One or more bundle task IDs.

Default: Describes all your bundle tasks.










=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 Filters => ArrayRef[Paws::EC2::Filter]

  

One or more filters.

=over

=item *

C<bundle-id> - The ID of the bundle task.

=item *

C<error-code> - If the task failed, the error code returned.

=item *

C<error-message> - If the task failed, the error message returned.

=item *

C<instance-id> - The ID of the instance.

=item *

C<progress> - The level of task completion, as a percentage (for
example, 20%).

=item *

C<s3-bucket> - The Amazon S3 bucket to store the AMI.

=item *

C<s3-prefix> - The beginning of the AMI name.

=item *

C<start-time> - The time the task started (for example,
2013-09-15T17:15:20.000Z).

=item *

C<state> - The state of the task (C<pending> | C<waiting-for-shutdown>
| C<bundling> | C<storing> | C<cancelling> | C<complete> | C<failed>).

=item *

C<update-time> - The time of the most recent update for the task.

=back












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeBundleTasks in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

