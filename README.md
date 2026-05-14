# NAME

Genealogy::Relationship::Name - Return a genealogical relationship name from step counts

# VERSION

Version 0.01

# SYNOPSIS

    use Genealogy::Relationship::Name;

    my $namer = Genealogy::Relationship::Name->new();

    my $name = $namer->name(
        steps_to_ancestor   => 2,
        steps_from_ancestor => 3,
        sex                 => 'F',
    );
    # Returns 'first cousin once-removed'

    # With language
    my $name_fr = $namer->name(
        steps_to_ancestor   => 2,
        steps_from_ancestor => 2,
        sex                 => 'M',
        language            => 'fr',
    );
    # Returns 'cousin germain'

# DESCRIPTION

`Genealogy::Relationship::Name` maps a pair of step-counts (person A to common
ancestor, common ancestor to person B) plus the sex of person B and an optional
language code to a human-readable relationship name string.

The relationship tables were originally embedded in the `gedcom` and `ged2site`
distributions inside `Gedcom::Individual::relationship_up()`; this module
extracts them into a reusable, installable CPAN distribution.

Supported languages: `en` (English, default), `fr` (French), `de` (German).

# METHODS

## name

Returns the name of the relationship between person A and person B.

### PURPOSE

Given the number of steps from person A up to the nearest common ancestor
(`steps_to_ancestor`) and the number of steps from that ancestor down to
person B (`steps_from_ancestor`), plus the sex of person B and a language
code, returns a localised relationship-name string.

### ARGUMENTS

- `steps_to_ancestor` (integer, required)

    Number of generational steps from person A up to the common ancestor.
    Must be a non-negative integer.  Zero means person A _is_ the ancestor.

- `steps_from_ancestor` (integer, required)

    Number of generational steps from the common ancestor down to person B.
    Must be a non-negative integer.

- `sex` (string, required)

    Sex of person B.  Must be `'M'` (male) or `'F'` (female).

- `language` (string, optional)

    BCP-47-style language tag (only the primary subtag is used).
    Supported values: `en` (default), `fr`, `de`.

### RETURNS

A string containing the relationship name, or `undef` if the combination
is not found in the lookup table.

### EXAMPLE

    my $namer = Genealogy::Relationship::Name->new();

    # Person A is the grandparent (2 steps up) of the common ancestor,
    # and person B is 3 steps below the ancestor; B is female => first cousin once-removed
    my $rel = $namer->name(
        steps_to_ancestor   => 2,
        steps_from_ancestor => 3,
        sex                 => 'F',
    );

### API SPECIFICATION

#### Input

    {
        steps_to_ancestor   => { type => 'integer', minimum => 0 },
        steps_from_ancestor => { type => 'integer', minimum => 0 },
        sex                 => { type => 'string', memberof => ['M', 'F'] },
        language            => { type => 'string', regex => qr/^(?:en|de|fr)/, optional => 1 },
    }

#### Output

    {
        type     => 'string',
        optional => 1,     # undef when the combination is not tabulated
    }

### FORMAL SPECIFICATION

    name ______________________________________________________
    [In]  steps_to_ancestor   : N0
          steps_from_ancestor : N0
          sex                 : {M, F}
          language            : {en, fr, de}?  (default en)
    [Out] result              : String | undef

    Let key == steps_to_ancestor ++ "," ++ steps_from_ancestor
    Let table == RELATIONSHIP_TABLES(language)(sex)
    result == table(key)  if key in dom table
           == undef       otherwise

## supported\_languages

Returns a sorted list of the language codes that the module supports.

### PURPOSE

Allows calling code to enumerate the languages available for `name()`
without hard-coding them.

### ARGUMENTS

None.

### RETURNS

A list (or array-ref in scalar context) of language code strings,
currently `('de', 'en', 'fr')`.

### EXAMPLE

    my @langs = $namer->supported_languages();
    # ( 'de', 'en', 'fr' )

### API SPECIFICATION

#### Input

    {}   # no arguments

#### Output

    {
        type => ARRAYREF,   # sorted list of language codes
    }

### FORMAL SPECIFICATION

    supported_languages ______________________________________
    [In]  (none)
    [Out] result : seq String

    result == sort(dom RELATIONSHIP_TABLES)

## known\_sexes

Returns the list of sex codes accepted by `name()`.

### PURPOSE

Documents and exposes the set of valid `sex` values so that callers can
validate their own input without duplicating knowledge.

### ARGUMENTS

None.

### RETURNS

A list (or array-ref in scalar context) of valid sex code strings: `('F', 'M')`.

### SIDE EFFECTS

None.

### EXAMPLE

    my @sexes = $namer->known_sexes();
    # ( 'F', 'M' )

### API SPECIFICATION

#### Input

    {}   # no arguments

#### Output

    {
        type => ARRAYREF,
    }

### FORMAL SPECIFICATION

    known_sexes ______________________________________________
    [In]  (none)
    [Out] result : seq String

    result == sort { $SEX_FEMALE, $SEX_MALE }

# CONFIGURATION

The constructor accepts an optional `language` key which sets the default
language for all subsequent calls to `name()`:

    my $namer = Genealogy::Relationship::Name->new(language => 'fr');

This default can be overridden per-call by passing `language` to `name()`.
The object is also compatible with `Object::Configure` for runtime
reconfiguration.

# DIAGNOSTICS

- Unsupported language '%s'; falling back to 'en'

    The `language` argument contained a value not in the supported set.
    The module continues with English relationship names.

# DEPENDENCIES

[Carp](https://metacpan.org/pod/Carp), [Params::Get](https://metacpan.org/pod/Params%3A%3AGet), [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict), [Readonly](https://metacpan.org/pod/Readonly), [Return::Set](https://metacpan.org/pod/Return%3A%3ASet)

# BUGS AND LIMITATIONS

The lookup tables currently cover steps 0-6 in both directions.  Relationships
further removed (seventh cousin, etc.) return `undef`.  Pull requests adding
deeper tables are welcome.

# SEE ALSO

[Gedcom::Individual](https://metacpan.org/pod/Gedcom%3A%3AIndividual), [Genealogy::Relationship](https://metacpan.org/pod/Genealogy%3A%3ARelationship)

# AUTHOR

Nigel Horne `<njh@nigelhorne.com>`

# REPOSITORY

[https://github.com/nigelhorne/Genealogy-Relationship-Name](https://github.com/nigelhorne/Genealogy-Relationship-Name)

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-genalogy-relationship-name at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Genealogy-Relationship-Name](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Genealogy-Relationship-Name).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Genealogy::Relationship::Name

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/dist/Genealogy-Relationship-Name](https://metacpan.org/dist/Genealogy-Relationship-Name)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-Relationship-Name](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-Relationship-Name)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Genealogy-Relationship-Name](http://matrix.cpantesters.org/?dist=Genealogy-Relationship-Name)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Genealogy::Relationship::Name](http://deps.cpantesters.org/?module=Genealogy::Relationship::Name)

# LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to GPL2 licence terms.
If you use it,
please let me know.
