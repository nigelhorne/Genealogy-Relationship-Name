#!/usr/bin/env perl

# edge_cases.t - destructive, pathological, and boundary-condition tests
# for Genealogy::Relationship::Name.
# This is where the fun starts!

use strict;
use warnings;

use Test::Most;
use Scalar::Util qw(looks_like_number);

use lib 'lib', '../lib';

BEGIN {
	use_ok('Genealogy::Relationship::Name')
		or BAIL_OUT('Cannot load Genealogy::Relationship::Name');
}

# =========================================================================
# Boundary: step count = 0
# =========================================================================

subtest 'Boundary: zero steps (self)' => sub {
	plan tests => 2;

	my $namer = Genealogy::Relationship::Name->new();

	is($namer->name(steps_to_ancestor => 0, steps_from_ancestor => 0, sex => 'M'),
		'self', '0,0 M => self');
	is($namer->name(steps_to_ancestor => 0, steps_from_ancestor => 0, sex => 'F'),
		'self', '0,0 F => self');
};

# =========================================================================
# Boundary: single-step combinations at the edge of the table
# =========================================================================

subtest 'Boundary: maximum tabulated steps (6,6)' => sub {
	plan tests => 2;

	my $namer = Genealogy::Relationship::Name->new();

	is($namer->name(steps_to_ancestor => 6, steps_from_ancestor => 6, sex => 'M'),
		'fifth cousin', '6,6 M => fifth cousin');
	is($namer->name(steps_to_ancestor => 6, steps_from_ancestor => 6, sex => 'F'),
		'fifth cousin', '6,6 F => fifth cousin');
};

# =========================================================================
# Boundary: just beyond the table (7,7) → undef, no crash
# =========================================================================

subtest 'Boundary: just-beyond-table steps return undef without crashing' => sub {
	plan tests => 2;

	my $namer = Genealogy::Relationship::Name->new();

	my $r1 = $namer->name(steps_to_ancestor => 7, steps_from_ancestor => 7, sex => 'M');
	is($r1, undef, '7,7 M => undef');

	my $r2 = $namer->name(steps_to_ancestor => 7, steps_from_ancestor => 0, sex => 'F');
	is($r2, undef, '7,0 F => undef (not in table)');
};

# =========================================================================
# Pathological: extremely large step values
# =========================================================================

subtest 'Pathological: very large step values return undef without dying' => sub {
	plan tests => 3;

	my $namer = Genealogy::Relationship::Name->new();

	my $r1 = eval { $namer->name(steps_to_ancestor => 999, steps_from_ancestor => 999, sex => 'M') };
	is($@, '', 'No exception for large step values');
	is($r1, undef, '999,999 returns undef');

	my $r2 = eval { $namer->name(steps_to_ancestor => 0, steps_from_ancestor => 999, sex => 'F') };
	is($r2, undef, '0,999 returns undef');
};

# =========================================================================
# Pathological: invalid sex code triggers validation error
# =========================================================================

subtest 'Pathological: invalid sex code croaks' => sub {
	plan tests => 3;

	my $namer = Genealogy::Relationship::Name->new();

	# Check the first three invalid sex values; each must throw
	for my $bad_sex (qw(X U m)) {
		throws_ok {
			$namer->name(steps_to_ancestor => 1, steps_from_ancestor => 1, sex => $bad_sex)
		} qr/.+/, "Invalid sex '$bad_sex' causes exception";
	}
};

# =========================================================================
# Pathological: non-integer step values trigger validation error
# =========================================================================

subtest 'Pathological: non-integer step values croak' => sub {
	plan tests => 4;

	my $namer = Genealogy::Relationship::Name->new();

	for my $bad (qw(1.5 -1 abc)) {
		eval {
			$namer->name(steps_to_ancestor => $bad, steps_from_ancestor => 1, sex => 'M')
		};
		ok($@, "Non-integer steps_to_ancestor '$bad' croaks");
	}

	eval {
		$namer->name(steps_to_ancestor => 1, steps_from_ancestor => -1, sex => 'M')
	};
	ok($@, 'Negative steps_from_ancestor croaks');
};

# =========================================================================
# Pathological: missing required arguments
# =========================================================================

subtest 'Pathological: missing required args croak' => sub {
	plan tests => 3;

	my $namer = Genealogy::Relationship::Name->new();

	eval { $namer->name(steps_from_ancestor => 1, sex => 'M') };
	ok($@, 'Missing steps_to_ancestor croaks');

	eval { $namer->name(steps_to_ancestor => 1, sex => 'M') };
	ok($@, 'Missing steps_from_ancestor croaks');

	eval { $namer->name(steps_to_ancestor => 1, steps_from_ancestor => 1) };
	ok($@, 'Missing sex croaks');
};

# =========================================================================
# Pathological: invalid language code croaks via validate_strict
# =========================================================================

subtest 'Pathological: invalid language codes croak' => sub {
	plan tests => 5;

	my $namer = Genealogy::Relationship::Name->new();

	# validate_strict rejects anything not matching /^(?:en|de|fr)/
	for my $bad_lang (qw(zz xx zh ja es)) {
		throws_ok {
			$namer->name(steps_to_ancestor => 1, steps_from_ancestor => 1,
			             sex => 'M', language => $bad_lang)
		} qr/must match pattern/, "Invalid lang '$bad_lang' croaks";
	}
};

# =========================================================================
# Boundary: language is uppercase / mixed-case — croaks (validation before lc)
# =========================================================================

subtest 'Boundary: uppercase language codes croak (validation before lc)' => sub {
	plan tests => 3;

	my $namer = Genealogy::Relationship::Name->new();

	# validate_strict checks before lc() is applied, so 'EN'/'FR' don't match
	# the /^(?:en|de|fr)/ regex and croak; callers must supply lowercase
	for my $bad (qw(EN En FR)) {
		throws_ok {
			$namer->name(steps_to_ancestor => 1, steps_from_ancestor => 1,
			             sex => 'M', language => $bad)
		} qr/must match pattern/, "Uppercase language '$bad' croaks";
	}
};

# =========================================================================
# Boundary: numeric-looking language codes croak
# =========================================================================

subtest 'Boundary: numeric language code croaks' => sub {
	plan tests => 1;

	my $namer = Genealogy::Relationship::Name->new();

	throws_ok {
		$namer->name(steps_to_ancestor => 1, steps_from_ancestor => 1,
		             sex => 'M', language => '42')
	} qr/must match pattern/, 'Numeric language code croaks';
};

# =========================================================================
# Boundary: undef steps trigger validation
# =========================================================================

subtest 'Boundary: undef step values croak' => sub {
	plan tests => 2;

	my $namer = Genealogy::Relationship::Name->new();

	# validate_strict does not catch undef for integer fields; the module guards explicitly
	throws_ok {
		$namer->name(steps_to_ancestor => undef, steps_from_ancestor => 1, sex => 'M')
	} qr/steps_to_ancestor must be a defined/, 'undef steps_to_ancestor croaks';

	throws_ok {
		$namer->name(steps_to_ancestor => 1, steps_from_ancestor => undef, sex => 'M')
	} qr/steps_from_ancestor must be a defined/, 'undef steps_from_ancestor croaks';
};

# =========================================================================
# Boundary: empty-string values for steps
# =========================================================================

subtest 'Boundary: empty string steps croak' => sub {
	plan tests => 2;

	my $namer = Genealogy::Relationship::Name->new();

	eval { $namer->name(steps_to_ancestor => '', steps_from_ancestor => 1, sex => 'M') };
	ok($@, 'Empty string steps_to_ancestor croaks');

	eval { $namer->name(steps_to_ancestor => 1, steps_from_ancestor => '', sex => 'M') };
	ok($@, 'Empty string steps_from_ancestor croaks');
};

# =========================================================================
# Pathological: calling name() with no arguments
# =========================================================================

subtest 'Pathological: name() with no arguments croaks' => sub {
	plan tests => 1;

	my $namer = Genealogy::Relationship::Name->new();
	eval { $namer->name() };
	ok($@, 'name() with no args croaks');
};

# =========================================================================
# Pathological: inject array ref as step value
# =========================================================================

subtest 'Pathological: arrayref as step value croaks' => sub {
	plan tests => 1;

	my $namer = Genealogy::Relationship::Name->new();
	eval { $namer->name(steps_to_ancestor => [1, 2], steps_from_ancestor => 1, sex => 'M') };
	ok($@, 'Arrayref as step croaks');
};

# =========================================================================
# Regression: confirm asymmetric removed-cousin pairs
# =========================================================================

subtest 'Regression: cousin-removed symmetry across tables' => sub {
	plan tests => 4;

	my $namer = Genealogy::Relationship::Name->new();

	# 2,3 and 3,2 should both give "first cousin once-removed"
	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 3, sex => 'M'),
		'first cousin once-removed', '2,3 M => first cousin once-removed');
	is($namer->name(steps_to_ancestor => 3, steps_from_ancestor => 2, sex => 'M'),
		'first cousin once-removed', '3,2 M => first cousin once-removed');
	is($namer->name(steps_to_ancestor => 2, steps_from_ancestor => 3, sex => 'F'),
		'first cousin once-removed', '2,3 F => first cousin once-removed');
	is($namer->name(steps_to_ancestor => 3, steps_from_ancestor => 2, sex => 'F'),
		'first cousin once-removed', '3,2 F => first cousin once-removed');
};

# =========================================================================
# Stress: rapid repeated calls do not leak state or crash
# =========================================================================

subtest 'Stress: 1000 rapid calls without crash' => sub {
	plan tests => 1;

	my $namer = Genealogy::Relationship::Name->new();
	my $ok    = 1;

	for my $i (0..999) {
		my $s1 = $i % 7;
		my $s2 = ($i + 1) % 7;
		my $sex = ($i % 2) ? 'M' : 'F';
		eval { $namer->name(steps_to_ancestor => $s1, steps_from_ancestor => $s2, sex => $sex) };
		if($@) {
			$ok = 0;
			last;
		}
	}
	ok($ok, '1000 rapid calls without exception');
};

# =========================================================================
# Pathological: extra unknown arguments to name()
# =========================================================================

subtest 'Pathological: unknown extra argument to name()' => sub {
	plan tests => 1;

	my $namer = Genealogy::Relationship::Name->new();

	# Params::Validate::Strict should reject unknown keys
	eval {
		$namer->name(
			steps_to_ancestor   => 1,
			steps_from_ancestor => 1,
			sex                 => 'M',
			unknown_key         => 'oops',
		);
	};
	ok($@, 'Unknown argument to name() croaks via Params::Validate::Strict');
};

# =========================================================================
# Pathological: calling methods on non-object (bare class)
# =========================================================================

subtest 'Pathological: new() works as class method (not object)' => sub {
	plan tests => 1;

	# This should work — new() should handle both $class->new and $obj->new
	my $obj = Genealogy::Relationship::Name->new();
	isa_ok($obj, 'Genealogy::Relationship::Name');
};


# =========================================================================
# Pathological: on_error edge cases
# =========================================================================

subtest 'Pathological: on_error that itself croaks propagates' => sub {
	plan tests => 1;

	my $namer = Genealogy::Relationship::Name->new(
		on_error => sub { die "handler died: $_[1]\n" },
	);

	throws_ok {
		$namer->name(steps_to_ancestor => undef, steps_from_ancestor => 1, sex => 'M')
	} qr/handler died/, 'Exception from on_error propagates out of name()';
};

subtest 'Pathological: on_error called multiple times stays consistent' => sub {
	plan tests => 3;

	my @calls;
	my $namer = Genealogy::Relationship::Name->new(
		on_error => sub { push @calls, {@_} },
	);

	# Trigger the same error three times
	$namer->name(steps_to_ancestor => undef, steps_from_ancestor => 1, sex => 'M') for 1..3;

	is(scalar @calls, 3, 'on_error called once per invocation');
	is($calls[0]{warning}, $calls[1]{warning}, 'Same warning each time');
	is($calls[1]{warning}, $calls[2]{warning}, 'Consistent across all calls');
};

subtest 'Pathological: on_error undef explicitly is rejected' => sub {
	plan tests => 1;

	# Explicitly passing undef is fine — treated as not set, croaks normally
	my $namer = Genealogy::Relationship::Name->new(on_error => undef);
	throws_ok {
		$namer->name(steps_to_ancestor => undef, steps_from_ancestor => 1, sex => 'M')
	} qr/steps_to_ancestor/, 'undef on_error falls back to croak';
};


# =========================================================================
# Pathological: logger edge cases
# =========================================================================

subtest 'Pathological: logger that dies propagates exception' => sub {
	plan tests => 1;

	my $namer = Genealogy::Relationship::Name->new(
		logger => sub { die "logger exploded\n" },
	);
	throws_ok {
		$namer->name(steps_to_ancestor => undef, steps_from_ancestor => 1, sex => 'M')
	} qr/logger exploded/, 'Exception from logger propagates out';
};

subtest 'Pathological: ctx set but logger is array ref — falls through to on_error' => sub {
	plan tests => 2;

	# Log::Abstraction supports array-ref loggers too; these skip the coderef
	# path so on_error should fire instead
	my @error_calls;
	my $namer = Genealogy::Relationship::Name->new(
		logger   => [],        # array-ref logger: not a CODE ref
		on_error => sub { push @error_calls, {@_} },
		ctx      => bless({}, 'SomePerson'),
	);

	$namer->name(steps_to_ancestor => undef, steps_from_ancestor => 1, sex => 'M');

	is(scalar @error_calls, 1, 'on_error fired when logger is not a coderef');
	like($error_calls[0]{warning}, qr/steps_to_ancestor/, 'warning passed to on_error');
};

subtest 'Pathological: neither logger coderef nor on_error — croaks as before' => sub {
	plan tests => 1;

	my $namer = Genealogy::Relationship::Name->new(
		ctx => bless({}, 'SomePerson'),    # ctx set but no handlers
	);
	throws_ok {
		$namer->name(steps_to_ancestor => undef, steps_from_ancestor => 1, sex => 'M')
	} qr/steps_to_ancestor/, 'Falls through to croak when no handlers set';
};

done_testing();
