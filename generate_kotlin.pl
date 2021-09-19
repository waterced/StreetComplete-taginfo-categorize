#!/usr/bin/perl -T
# by Matija Nalis <mnalis-git@voyager.hr> GPLv3+, started 20210905
#
# parses keys.txt and generates sc_to_remove.txt kotlin code in nicely commented blocks
# see README.md for description of structure

use strict;
use warnings;
use autodie qw/:all/;
use feature 'say';

my $SECTION_START = shift @ARGV;
my $SECTION_END = shift @ARGV;
my $VAR_NAME = shift @ARGV;

die "Usage: $0 <SECTION_START> <SECTION_END> <VAR_NAME>" if !defined $VAR_NAME;

say "val $VAR_NAME = listOf(";
print '    ';	# default indent

open my $existing_fd, '<', 'keys.txt';

my $skip_it = 1;
my $kotlin_str = '';
while (<$existing_fd>) {
    if (/^$SECTION_START/) { $skip_it=0; next; }
    if (/^$SECTION_END/) { last; }
    if ($skip_it) { next; }
    chomp;

    if (m{^[a-z.]}i) {		# detect key; line could start with regex like ".*xxxx"
        s{\s*(#|//).*$}{};		# remove inline comments
        s/([^\.])\*/$1.*/;		# make "*" wildcard into regex internally (if not regex already). NOTE: not perfect, but works for us!
        $kotlin_str .= qq{"$_", };
    } elsif (m{^//}) {		# detect whole-line-//-comment
        $kotlin_str .= "$_\n    ";
    } elsif (m{^#}) {		# detect whole-line-#-comment
        next;
    } elsif (m{^\s*$}) {	# detect empty line
        if ($kotlin_str =~ / $/) { $kotlin_str = substr($kotlin_str, 0, -1); }
        $kotlin_str .= "\n    ";
    } else {
        warn "SKIPPING unparseable line: $_";
    }

    #say STDERR "DEBUG: line: $_";
}

if ($kotlin_str =~ /    $/) { $kotlin_str = substr($kotlin_str, 0, -4); }
print $kotlin_str;

say ').map { it.toRegex() }';
exit 0;
