eval 'exec perl -S $0 ${1+"$@"}'  # -*- Mode: perl -*-
	if $running_under_some_shell; # makeDependsTargets.pl

# $Id$
#
#  Author: Janet Anderson
# 

sub Usage
{
    my ($txt) = @_;

    print "Usage:\n";
    print "\makeDependsTargets infile\n";
    print "\nError: $txt\n" if $txt;

    exit 2;
}

# need at least one args: ARGV[0]
Usage("need an arg") if $#ARGV < 0;

use Cwd;
use File::Path;
use File::Copy;

$depfile = $ARGV[0];
$tempfile = $ARGV[0].temp;

if (-f $depfile) {
    unlink("$tempfile");
    copy ($depfile, $tempfile) or die "$! copying $depfile";
    open(OUT,">> $depfile") or die "$! opening $depfile";
    open(IN,"< $tempfile") or die "$! opening $tempfile";
    print OUT "\n#Depend files must be targets to avoid 'No rule to make target ...' errors\n";
    
    while ($line = <IN>) {
        next if ( $line =~ /\s*#/ );
        chomp($line);
        #$line =~ s/[ 	]//g; # remove blanks and tabs
        #next if ( $line =~ /^$/ ); # skip empty lines
        $depends = $line;
    
        $depends =~ s/.*://;
        $depends =~ s/\\$//;
        print OUT "$depends : \n";
    }

    print OUT "\n";
    close IN or die "Cannot close $tempfile: $!";
    close OUT or die "Cannot close $depfile: $!";
    unlink("$tempfile");
}

