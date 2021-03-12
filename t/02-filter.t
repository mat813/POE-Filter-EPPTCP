#!/usr/bin/env perl

use 5.010;
use utf8;
use strict;
use warnings;

use Test::More 'tests' => 55;

use lib::relative '../lib';

use POE::Filter::EPPTCP;

my $filter = POE::Filter::EPPTCP->new;

sub make_length {
	my $str = shift;
	return pack 'N', 4 + length $str;
}

isa_ok($filter, 'POE::Filter::EPPTCP');

is_deeply $filter->buffer, [], 'buffer is empty';
is $filter->has_buffer, 0, 'buffer 0 length';

note 'get_one_start / get_one, one complete str at a time';

$filter->get_one_start;

is $filter->has_buffer, 0, 'buffer still 0 length';

is_deeply $filter->get_one, [], 'nothing to get';

is $filter->has_buffer, 0, 'buffer still 0 length, again';

my $buffer_length = 0;

my @list = ('badaboum', 'bom bom bom bom', "some long string with multiple lines\n" x 10, 'and a short one to end');

for my $str (@list) {
	my $header = make_length($str);

	$filter->get_one_start([ $header . $str ]);

	$buffer_length++;

	is $filter->has_buffer, $buffer_length, 'buffer increases';
} ## end for my $str (@list)

for my $str (@list) {
	my $ret = $filter->get_one;

	is scalar @{$ret}, 1, 'got one entry';
	is $ret->[0], $str, 'got the entry in order';
	$buffer_length--;
	is $filter->has_buffer, $buffer_length, 'buffer decreases';
} ## end for my $str (@list)

note 'get_one_start/get_one with many strings as one';

$filter->get_one_start([ join q{}, map { make_length($_) . $_ } @list ]);

for my $str (@list) {
	my $ret = $filter->get_one;

	is scalar @{$ret}, 1, 'got one entry';
	is $ret->[0], $str, 'got the entry in order';
} ## end for my $str (@list)

note 'get_one_start/get_one with many strings as one but madly splitted';

$filter->get_one_start([ split /(.{3})/oms, join q{}, map { make_length($_) . $_ } @list ]);

for my $str (@list) {
	my $ret = $filter->get_one;

	is scalar @{$ret}, 1, 'got one entry';
	is $ret->[0], $str, 'got the entry in order';
} ## end for my $str (@list)

note 'put';

is_deeply $filter->put([]), [], 'empty put';

for my $str (@list) {

	my $out = $filter->put([$str]);

	my $length = 4 + length $str;

	is scalar @{$out}, 1, 'one result';
	is length($out->[0]), $length, "output length ok, $length";
	is substr($out->[0], 0, 4), pack('N', $length), "packed length ok, $length";
	is substr($out->[0], 4), $str, 'content ok';
} ## end for my $str (@list)

1;
