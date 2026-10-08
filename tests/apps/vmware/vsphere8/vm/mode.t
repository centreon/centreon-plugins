use strict;
use warnings;
use Test2::V0;
use FindBin;
use lib "$FindBin::RealBin/../../../../../src";
use apps::vmware::vsphere8::vm::mode;

# In-memory replacement of centreon::plugins::statefile: one hash entry per statefile name
{
    package MockCache;
    sub new { bless { files => {} }, shift }
    sub read {
        my ($self, %options) = @_;
        $self->{current} = $options{statefile};
        return exists($self->{files}->{$self->{current}}) ? 1 : 0;
    }
    sub get {
        my ($self, %options) = @_;
        return $self->{files}->{$self->{current}}->{$options{name}};
    }
    sub write {
        my ($self, %options) = @_;
        $self->{files}->{$self->{current}} = { %{$options{data}} };
    }
}

# Replacement of the custom mode: answers /vcenter/vm?names=... with the VMs of its vCenter
{
    package MockCustom;
    sub new {
        my ($class, %options) = @_;
        return bless { hostname => $options{hostname}, port => 443, vms => $options{vms}, calls => 0 }, $class;
    }
    sub request_api {
        my ($self, %options) = @_;
        $self->{calls}++;
        my ($name) = $options{get_param}->[0] =~ /^names=(.*)$/;
        return [ grep { $_->{name} eq $name } @{$self->{vms}} ];
    }
}

{
    package MockOutput;
    sub new { bless {}, shift }
    sub add_option_msg { }
    sub option_exit { die "option_exit\n" }
}

# a fresh mode object, as built for one plugin run
sub new_mode {
    my (%options) = @_;

    return bless {
        cache                => $options{cache},
        output               => MockOutput->new(),
        vm_name              => $options{vm_name},
        vm_id_cache_duration => $options{duration} // 3600
    }, 'apps::vmware::vsphere8::vm::mode';
}

my $vcenter_a = MockCustom->new(hostname => 'vcenter-a', vms => [ { name => 'web-01', vm => 'vm-100' } ]);
my $vcenter_b = MockCustom->new(hostname => 'vcenter-b', vms => [ { name => 'web-01', vm => 'vm-200' } ]);

subtest 'the ID is looked up once, then read from the cache' => sub {
    my $cache = MockCache->new();
    $vcenter_a->{calls} = 0;

    is(new_mode(cache => $cache, vm_name => 'web-01')->get_vm_id(custom => $vcenter_a), 'vm-100', 'ID found through the API');
    is(new_mode(cache => $cache, vm_name => 'web-01')->get_vm_id(custom => $vcenter_a), 'vm-100', 'ID found in the cache');
    is($vcenter_a->{calls}, 1, 'the API is queried only once');
};

subtest 'the same VM name on two vCenters does not share a cache entry' => sub {
    my $cache = MockCache->new();

    is(new_mode(cache => $cache, vm_name => 'web-01')->get_vm_id(custom => $vcenter_a), 'vm-100', 'ID on vCenter A');
    is(new_mode(cache => $cache, vm_name => 'web-01')->get_vm_id(custom => $vcenter_b), 'vm-200', 'ID on vCenter B, not the one cached for A');
    is(scalar(keys %{$cache->{files}}), 2, 'one statefile per vCenter');
};

subtest 'an expired ID is looked up again' => sub {
    my $cache = MockCache->new();
    $vcenter_a->{calls} = 0;

    new_mode(cache => $cache, vm_name => 'web-01')->get_vm_id(custom => $vcenter_a);
    # the VM has been re-registered since, under a new ID
    $_->{updated} -= 7200 foreach (values %{$cache->{files}});
    local $vcenter_a->{vms} = [ { name => 'web-01', vm => 'vm-101' } ];

    is(new_mode(cache => $cache, vm_name => 'web-01')->get_vm_id(custom => $vcenter_a), 'vm-101', 'new ID found once the cache has expired');
    is($vcenter_a->{calls}, 2, 'the API is queried again');
    is(new_mode(cache => $cache, vm_name => 'web-01')->get_vm_id(custom => $vcenter_a), 'vm-101', 'the new ID is cached');
    is($vcenter_a->{calls}, 2, 'and read from the cache afterwards');
};

subtest 'a duration of 0 disables the cache' => sub {
    my $cache = MockCache->new();
    $vcenter_a->{calls} = 0;

    new_mode(cache => $cache, vm_name => 'web-01', duration => 0)->get_vm_id(custom => $vcenter_a) for (1 .. 2);
    is($vcenter_a->{calls}, 2, 'the API is queried at every run');
};

subtest 'an unknown VM is not cached' => sub {
    my $cache = MockCache->new();

    is(new_mode(cache => $cache, vm_name => 'db-01')->get_vm_id(custom => $vcenter_a), undef, 'no ID for an unknown VM');
    is(scalar(keys %{$cache->{files}}), 0, 'nothing is written to the cache');
};

done_testing();
