
package Paws::CodeDeploy::ListApplicationRevisions {
  use Moose;
  has applicationName => (is => 'ro', isa => 'Str', required => 1);
  has deployed => (is => 'ro', isa => 'Str');
  has nextToken => (is => 'ro', isa => 'Str');
  has s3Bucket => (is => 'ro', isa => 'Str');
  has s3KeyPrefix => (is => 'ro', isa => 'Str');
  has sortBy => (is => 'ro', isa => 'Str');
  has sortOrder => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListApplicationRevisions');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CodeDeploy::ListApplicationRevisionsOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CodeDeploy::ListApplicationRevisions - Arguments for method ListApplicationRevisions on Paws::CodeDeploy

=head1 DESCRIPTION

This class represents the parameters used for calling the method ListApplicationRevisions on the 
AWS CodeDeploy service. Use the attributes of this class
as arguments to method ListApplicationRevisions.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ListApplicationRevisions.

As an example:

  $service_obj->ListApplicationRevisions(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> applicationName => Str

  

The name of an existing AWS CodeDeploy application associated with the
applicable IAM user or AWS account.










=head2 deployed => Str

  

Whether to list revisions based on whether the revision is the target
revision of an deployment group:

=over

=item * include: List revisions that are target revisions of a
deployment group.

=item * exclude: Do not list revisions that are target revisions of a
deployment group.

=item * ignore: List all revisions, regardless of whether they are
target revisions of a deployment group.

=back










=head2 nextToken => Str

  

An identifier that was returned from the previous list application
revisions call, which can be used to return the next set of
applications in the list.










=head2 s3Bucket => Str

  

A specific Amazon S3 bucket name to limit the search for revisions.

If set to null, then all of the user's buckets will be searched.










=head2 s3KeyPrefix => Str

  

A specific key prefix for the set of Amazon S3 objects to limit the
search for revisions.










=head2 sortBy => Str

  

The column name to sort the list results by:

=over

=item * registerTime: Sort the list results by when the revisions were
registered with AWS CodeDeploy.

=item * firstUsedTime: Sort the list results by when the revisions were
first used by in a deployment.

=item * lastUsedTime: Sort the list results by when the revisions were
last used in a deployment.

=back

If not specified or set to null, the results will be returned in an
arbitrary order.










=head2 sortOrder => Str

  

The order to sort the list results by:

=over

=item * ascending: Sort the list of results in ascending order.

=item * descending: Sort the list of results in descending order.

=back

If not specified, the results will be sorted in ascending order.

If set to null, the results will be sorted in an arbitrary order.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ListApplicationRevisions in L<Paws::CodeDeploy>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

