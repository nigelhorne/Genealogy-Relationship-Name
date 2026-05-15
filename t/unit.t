#!/usr/bin/env perl

# unit.t - black-box tests for public API of Genealogy::Relationship::Name
# Tests are strictly driven by the POD API documentation.
# Non-core dependencies outside this module are mocked via Test::Mockingbird.

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird;

use lib 'lib', '../lib';

BEGIN {
	use_ok('Genealogy::Relationship::Name')
		or BAIL_OUT('Cannot load Genealogy::Relationship::Name');
}

# =========================================================================
# new()
# =========================================================================

subtest 'new() contract' => sub {
	plan tests => 4;

	# No-arg construction
	my $obj = new_ok('Genealogy::Relationship::Name');

	# Returns blessed ref
	isa_ok($obj, 'Genealogy::Relationship::Name');

	# With language default
	my $obj_de = Genealogy::Relationship::Name->new(language => 'de');
	isa_ok($obj_de, 'Genealogy::Relationship::Name');
	is($obj_de->{language}, 'de', 'de default stored');
};

# =========================================================================
# name() – return type contract
# =========================================================================

subtest 'name() returns a string for known keys' => sub {
	plan tests => 3;

	my $namer = Genealogy::Relationship::Name->new();

	my $r = $namer->name(steps_to_ancestor => 1, steps_from_ancestor => 0, sex => 'M');
	ok(defined $r, 'Returns defined value for known key');
	ok(length($r) > 0, 'Returns non-empty string');
	ok(!ref($r), 'Returns a plain scalar, not a ref');
};

subtest 'name() returns undef for unknown keys' => sub {
	plan tests => 1;

	my $namer = Genealogy::Relationship::Name->new();
	my $r = $namer->name(steps_to_ancestor => 99, steps_from_ancestor => 99, sex => 'F');
	is($r, undef, 'Returns undef for deeply unknown combination');
};

# =========================================================================
# name() – English coverage table
# =========================================================================

subtest 'name() English – exhaustive known-key checks' => sub {
	my $namer = Genealogy::Relationship::Name->new();

	# [ steps_to, steps_from, sex, expected ]
	my @cases = (
		[0, 0, 'M', 'self'],
		[0, 0, 'F', 'self'],
		[0, 1, 'M', 'son'],
		[0, 1, 'F', 'daughter'],
		[0, 2, 'M', 'grandson'],
		[0, 2, 'F', 'granddaughter'],
		[0, 3, 'M', 'great-grandson'],
		[0, 3, 'F', 'great-granddaughter'],
		[0, 4, 'M', 'great-great-grandson'],
		[0, 4, 'F', 'great-great-granddaughter'],
		[1, 0, 'M', 'father'],
		[1, 0, 'F', 'mother'],
		[1, 1, 'M', 'brother'],
		[1, 1, 'F', 'sister'],
		[1, 2, 'M', 'nephew'],
		[1, 2, 'F', 'niece'],
		[1, 3, 'M', 'great-nephew'],
		[1, 3, 'F', 'great-niece'],
		[2, 0, 'M', 'grandfather'],
		[2, 0, 'F', 'grandmother'],
		[2, 1, 'M', 'uncle'],
		[2, 1, 'F', 'aunt'],
		[2, 2, 'M', 'first cousin'],
		[2, 2, 'F', 'first cousin'],
		[2, 3, 'M', 'first cousin once-removed'],
		[2, 3, 'F', 'first cousin once-removed'],
		[2, 4, 'M', 'first cousin twice-removed'],
		[3, 0, 'M', 'great-grandfather'],
		[3, 0, 'F', 'great-grandmother'],
		[3, 1, 'M', 'great-uncle'],
		[3, 1, 'F', 'great-aunt'],
		[3, 2, 'M', 'first cousin once-removed'],
		[3, 3, 'M', 'second cousin'],
		[3, 3, 'F', 'second cousin'],
		[3, 4, 'M', 'second cousin once-removed'],
		[4, 0, 'M', 'great-great-grandfather'],
		[4, 0, 'F', 'great-great-grandmother'],
		[4, 4, 'M', 'third cousin'],
		[5, 5, 'M', 'fourth cousin'],
		[6, 6, 'M', 'fifth cousin'],
	);

	plan tests => scalar @cases;

	for my $c (@cases) {
		my($s1, $s2, $sex, $want) = @{$c};
		my $got = $namer->name(steps_to_ancestor => $s1, steps_from_ancestor => $s2, sex => $sex);
		is($got, $want, "en ${s1},${s2} ${sex} => $want");
	}
};

# =========================================================================
# name() – French coverage
# =========================================================================

subtest 'name() French – key spot-checks' => sub {
	plan tests => 8;

	my $namer = Genealogy::Relationship::Name->new();

	my @cases = (
		[0, 1, 'M', 'fr', 'fils'],
		[0, 1, 'F', 'fr', 'fille'],
		[1, 0, 'M', 'fr', 'pere'],
		[1, 0, 'F', 'fr', 'mere'],
		[1, 1, 'M', 'fr', 'frere'],
		[1, 1, 'F', 'fr', 'soeur'],
		[2, 2, 'M', 'fr', 'cousin germain'],
		[2, 2, 'F', 'fr', 'cousine germaine'],
	);

	for my $c (@cases) {
		my($s1, $s2, $sex, $lang, $want) = @{$c};
		is($namer->name(steps_to_ancestor => $s1, steps_from_ancestor => $s2,
		                sex => $sex, language => $lang),
			$want, "fr ${s1},${s2} ${sex} => $want");
	}
};

# =========================================================================
# name() – German coverage
# =========================================================================

subtest 'name() German – key spot-checks' => sub {
	plan tests => 8;

	my $namer = Genealogy::Relationship::Name->new();

	my @cases = (
		[0, 1, 'M', 'de', 'Sohn'],
		[0, 1, 'F', 'de', 'Tochter'],
		[1, 0, 'M', 'de', 'Vater'],
		[1, 0, 'F', 'de', 'Mutter'],
		[1, 1, 'M', 'de', 'Bruder'],
		[1, 1, 'F', 'de', 'Schwester'],
		[2, 2, 'M', 'de', 'Cousin'],
		[2, 2, 'F', 'de', 'Cousine'],
	);

	for my $c (@cases) {
		my($s1, $s2, $sex, $lang, $want) = @{$c};
		is($namer->name(steps_to_ancestor => $s1, steps_from_ancestor => $s2,
		                sex => $sex, language => $lang),
			$want, "de ${s1},${s2} ${sex} => $want");
	}
};

# =========================================================================
# name() – language override precedence
# =========================================================================

subtest 'name() per-call language overrides constructor default' => sub {
	plan tests => 3;

	my $namer = Genealogy::Relationship::Name->new(language => 'de');

	# No per-call language → uses 'de' default
	is($namer->name(steps_to_ancestor => 0, steps_from_ancestor => 1, sex => 'M'),
		'Sohn', 'de default used when no per-call language');

	# Per-call 'en' overrides 'de' default
	is($namer->name(steps_to_ancestor => 0, steps_from_ancestor => 1, sex => 'M', language => 'en'),
		'son', 'en per-call overrides de default');

	# Per-call 'fr' overrides 'de' default
	is($namer->name(steps_to_ancestor => 0, steps_from_ancestor => 1, sex => 'M', language => 'fr'),
		'fils', 'fr per-call overrides de default');
};

# =========================================================================
# name() – language subtag stripping
# =========================================================================

subtest 'name() strips region subtag' => sub {
	plan tests => 3;

	my $namer = Genealogy::Relationship::Name->new();

	is($namer->name(steps_to_ancestor => 1, steps_from_ancestor => 1, sex => 'M', language => 'en-GB'),
		'brother', 'en-GB -> en');
	is($namer->name(steps_to_ancestor => 1, steps_from_ancestor => 1, sex => 'M', language => 'en-US'),
		'brother', 'en-US -> en');
	is($namer->name(steps_to_ancestor => 0, steps_from_ancestor => 1, sex => 'F', language => 'fr-FR'),
		'fille', 'fr-FR -> fr');
};

# =========================================================================
# supported_languages()
# =========================================================================

subtest 'supported_languages() list context' => sub {
	plan tests => 5;

	my $namer = Genealogy::Relationship::Name->new();
	my @langs = $namer->supported_languages();

	ok(@langs >= 3, 'At least three languages');
	ok((grep { $_ eq 'en' } @langs), 'en present');
	ok((grep { $_ eq 'fr' } @langs), 'fr present');
	ok((grep { $_ eq 'de' } @langs), 'de present');

	# Result should be sorted
	my @sorted = sort @langs;
	is_deeply(\@langs, \@sorted, 'List is sorted');
};

subtest 'supported_languages() scalar context' => sub {
	plan tests => 2;

	my $namer = Genealogy::Relationship::Name->new();
	my $ref   = $namer->supported_languages();

	isa_ok($ref, 'ARRAY');
	is(scalar @{$ref}, 3, 'Arrayref contains 3 entries');
};

# =========================================================================
# known_sexes()
# =========================================================================

subtest 'known_sexes() list context' => sub {
	plan tests => 3;

	my $namer  = Genealogy::Relationship::Name->new();
	my @sexes  = $namer->known_sexes();

	is(scalar @sexes, 2, 'Exactly two sex codes');
	ok((grep { $_ eq 'M' } @sexes), 'M present');
	ok((grep { $_ eq 'F' } @sexes), 'F present');
};

subtest 'known_sexes() scalar context' => sub {
	plan tests => 2;

	my $namer = Genealogy::Relationship::Name->new();
	my $ref   = $namer->known_sexes();

	isa_ok($ref, 'ARRAY');
	is(scalar @{$ref}, 2, 'Arrayref contains 2 entries');
};


# =========================================================================
# on_error coderef: black-box contract tests
# =========================================================================

subtest 'new() accepts valid on_error coderef' => sub {
	plan tests => 2;

	my $namer = Genealogy::Relationship::Name->new(on_error => sub {});
	ok(defined $namer, 'new() with on_error coderef returns defined object');
	isa_ok($namer, 'Genealogy::Relationship::Name');
};

subtest 'new() rejects non-coderef on_error' => sub {
	plan tests => 3;

	for my $bad ('string', 42, []) {
		throws_ok {
			Genealogy::Relationship::Name->new(on_error => $bad)
		} qr/on_error must be a CODE reference/, "on_error => ${\ref(\$bad)||$bad} croaks";
	}
};

subtest 'on_error handler called with warning and person keys' => sub {
	plan tests => 4;

	my %captured;
	my $namer = Genealogy::Relationship::Name->new(
		on_error => sub { %captured = @_ },
	);

	my $fake = bless {}, 'SomePerson';
	my $result = $namer->name(
		steps_to_ancestor   => undef,
		steps_from_ancestor => 1,
		sex                 => 'M',
		person              => $fake,
	);

	# Handler was called, name() returns undef
	ok(exists $captured{warning}, 'warning key present');
	ok(length $captured{warning}, 'warning is non-empty');
	is(ref $captured{person}, 'SomePerson', 'person forwarded to handler');
	is($result, undef, 'name() returns undef when handler returns');
};

subtest 'person arg accepted by name() without on_error' => sub {
	plan tests => 1;

	# person is optional and silently ignored when no on_error is set
	# and no error occurs
	my $namer = Genealogy::Relationship::Name->new();
	my $fake  = bless {}, 'SomePerson';
	my $result = $namer->name(
		steps_to_ancestor   => 1,
		steps_from_ancestor => 1,
		sex                 => 'M',
		person              => $fake,
	);
	is($result, 'brother', 'person arg ignored on success, correct result returned');
};


# =========================================================================
# logger + ctx: black-box contract tests (Log::Abstraction >= 0.28)
# =========================================================================

subtest 'new() accepts logger coderef and ctx' => sub {
	plan tests => 2;

	my $namer = Genealogy::Relationship::Name->new(
		logger => sub {},
		ctx    => bless({}, 'SomePerson'),
	);
	ok(defined $namer, 'new() with logger+ctx returns defined');
	isa_ok($namer, 'Genealogy::Relationship::Name');
};

subtest 'logger called on error with ctx, not on_error' => sub {
	plan tests => 4;

	my (@logger_calls, @error_calls);
	my $person = bless { name => 'Test Person' }, 'SomePerson';

	my $namer = Genealogy::Relationship::Name->new(
		logger   => sub { push @logger_calls, shift },
		on_error => sub { push @error_calls, {@_} },
		ctx      => $person,
	);

	$namer->name(steps_to_ancestor => undef, steps_from_ancestor => 1, sex => 'M');

	is(scalar @logger_calls, 1, 'logger called once');
	is(scalar @error_calls,  0, 'on_error not called when logger set');
	is($logger_calls[0]{level}, 'error', 'error level passed to logger');
	is(ref $logger_calls[0]{ctx}, 'SomePerson', 'ctx forwarded to logger');
};

subtest 'ctx falls back to constructor when no per-call person' => sub {
	plan tests => 2;

	my $captured;
	my $ctx_person = bless { id => 'ctx-001' }, 'SomePerson';

	my $namer = Genealogy::Relationship::Name->new(
		logger => sub { $captured = shift },
		ctx    => $ctx_person,
	);

	$namer->name(steps_to_ancestor => undef, steps_from_ancestor => 1, sex => 'M');

	is(ref $captured->{ctx}, 'SomePerson', 'ctx is a SomePerson object');
	is($captured->{ctx}{id}, 'ctx-001', 'constructor ctx used when no per-call person');
};

subtest 'no ctx key in logger args when neither ctx nor person set' => sub {
	plan tests => 1;

	my $captured;
	my $namer = Genealogy::Relationship::Name->new(
		logger => sub { $captured = shift },
	);

	$namer->name(steps_to_ancestor => undef, steps_from_ancestor => 1, sex => 'M');

	ok(!exists $captured->{ctx}, 'ctx key absent when no ctx or person set');
};

done_testing();
