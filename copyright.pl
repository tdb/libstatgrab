#!/usr/bin/perl -w

# ./copyright.pl tests/*/*.{c,h} examples/*.{c,h} src/*/*.{c,h,in} .gitlab-ci.yml configure.ac

use strict;
use File::stat;

# The number of changes (additions+removals) needed to be considered
# worthy of being included in the Copyright line.
my $linecount = 7;

foreach my $file (@ARGV) {
	die "$file doesn't exist" unless -f $file;

	my @log = `git log --no-show-signature --numstat --ignore-all-space --author-date-order --follow --date=format:%Y%m%d%H%M%S --format="ENTRYSTART %ad %an" $file`;

	my @processed = ();

	my $stash;
	foreach my $entry (@log) {
		chomp $entry;
		if ($entry =~ /^ENTRYSTART (.*)/) {
			$stash = $1;
		} elsif (defined $stash && $entry =~ /^(\d+)\s+(\d+)\s+/) {
			push @processed, $1+$2 . " $stash";
			$stash = undef;
		} elsif ($entry ne "" ) {
			die "Unexpected log output: #$entry#"
		}
	}

	my $data = {};

	foreach my $entry (reverse @processed) {
		if ($entry =~ /^([\d]+)\s+([\d]+)\s+(.*)$/) {
			my $changecount = $1;
			my $name = $3;
			my $years = $2;

			if ($name ne "Tim Bishop" && $name ne "Peter Saunders" && $name ne "Adam Sampson" && $name ne "Jens Rehsack") {
				next;
			}

			$data->{$name}->{$years} = 1 if $changecount >= $linecount;
		}
	}

	foreach my $name (keys %{$data}) {
		my @ordered = sort {$a <=> $b} keys %{$data->{$name}};
		$data->{$name} = \@ordered;
	}

	my @copyright = ();

	foreach my $name (sort {@{$data->{$a}}[0] <=> @{$data->{$b}}[0]} keys %{$data}) {
		# keep only year and make unique
		my @ordered = map { s/(\d{4})\d{10}/$1/r } @{$data->{$name}};
		@ordered = do { my %seen; grep { !$seen{$_}++ } @ordered };

		# To do all years, but do ranges where possible
		#my $years = join ', ', @ordered;
		#$years =~ s/(?<!\d)(\d+)(?:, ((??{$++1}))(?!\d))+/$1-$+/g;
		#push @copyright, "Copyright (C) $years $name";

		# To do a single first-last range
		my $firsttolast = $ordered[0] == $ordered[-1] ? $ordered[0] : $ordered[0] . '-' . $ordered[-1];
		push @copyright, "Copyright (C) $firsttolast $name";
	}

	open (IN, "<$file") or die "Can't open $file for read: $!";
	open (OUT, ">$file.$$") or die "Can't open $file.$$ for write: $!";

	my $done = 0;
	while (<IN>) {
		my $line = $_;
		if ($line =~ /^(.*)Copyright \(C\)/) {
			unless ($done) {
				foreach my $newcopyright (@copyright) {
					print OUT "${1}${newcopyright}\n";
				}
				$done = 1;
			}
			# implicitly dump remaining copyright lines
		} else {
			print OUT $line;
		}
	}

	close (IN) or die "Can't close $file: $!";
	close (OUT) or die "Can't close $file.$$: $!";
	my $st = stat($file);
	chmod ($st->mode, "$file.$$") or die "Can't set permissions on $file.$$: $!";
	rename ("$file.$$", "$file") or die "Can't rename $file.$$ to $file: $!";
}
