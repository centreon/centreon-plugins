#!/usr/bin/perl

use strict;
use warnings;
use Crypt::Argon2 qw/argon2d_raw argon2i_raw argon2id_raw argon2_pass argon2_verify/;

# Password to hash
my $password = 'my_secure_password';
my $salt = 'random_salt';
my $iterations = 3;
my $memory_cost = 32 * 1024; # in KB
my $parallelism = 1;
my $hash_length = 32;

# Hash with Argon2d
my $argon2d_hash = argon2d_raw($password, $salt, $iterations, $memory_cost, $parallelism, $hash_length);
print("Argon2d hash: " . unpack("H*", $argon2d_hash) . "\n");
# Hash with Argon2i
my $argon2i_hash = argon2i_raw($password, $salt, $iterations, $memory_cost, $parallelism, $hash_length);
print("Argon2i hash: " . unpack("H*", $argon2i_hash) . "\n");
# Hash with Argon2id
my $argon2id_hash = argon2id_raw($password, $salt, $iterations, $memory_cost, $parallelism, $hash_length);
print("Argon2id hash: " . unpack("H*", $argon2id_hash) . "\n");

# Encode password with Argon2d
my $argon2d_encoded = argon2_pass('argon2d', $password, $salt, $iterations, $memory_cost, $parallelism, $hash_length);
print "Argon2d encoded: $argon2d_encoded\n";
# Encode password with Argon2i
my $argon2i_encoded = argon2_pass('argon2i', $password, $salt, $iterations, $memory_cost, $parallelism, $hash_length);
print "Argon2i encoded: $argon2i_encoded\n";
# Encode password with Argon2id
my $argon2id_encoded = argon2_pass('argon2id', $password, $salt, $iterations, $memory_cost, $parallelism, $hash_length);
print "Argon2id encoded: $argon2id_encoded\n";

# Verify password with Argon2d
# print argon2d_verify($argon2d_encoded1, $password) ? "Argon2d password is correct.\n" : "Argon2d password is incorrect.\n";
argon2_verify($argon2d_encoded, $password) ? print "Argon2d password is correct.\n" : exit(1);
# Verify password with Argon2i
argon2_verify($argon2i_encoded, $password) ? print "Argon2i password is correct.\n" : exit(1);
# Verify password with Argon2id
argon2_verify($argon2id_encoded, $password) ? print "Argon2id password is correct.\n" : exit(1);
