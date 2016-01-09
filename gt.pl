#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;

my $aid = "";
my $help = 0;
my $test = 0;
my $noverify = 0;
my $threads = 1;
my $verbose = 1;
my $ratelimit = 25;   # 25 MB/s (suggestion from John Groboske 1/7/14)

GetOptions ("analysisid|a=s" => \$aid,
            "testonly|t"     => \$test,
            "help|h"         => \$help,
            "noverify|y"     => \$noverify,
            "threads|c=i"    => \$threads,
            "verbose|v"      => \$verbose,
            "ratelimit|r=i"  => \$ratelimit,
);

exec('perldoc', $0) if $help;
exec('perldoc', $0) unless $aid;

# build gtdownload command
my $command = "gtdownload -t -k 10";# -t timestamps
                                      # -k 10: terminate if no data transferred within any 10 minute interval
$command .= " -v" if ($verbose);
$command .= " -d $aid -c /ihome/jpipas/pgc92/refs/mykey.pem";
$command .= " --ssl-no-verify-ca" if ($noverify);
$command .= " --max-children $threads";
#$command .= " --rate-limit $ratelimit";

if ($test) {
  print "Command to run: $command\n";
} else {
  my $tryLimit = 3;
  my $tryCount = 0;
  while ($tryCount < $tryLimit) {
    $tryCount++;

    # download data (with one retry)
    my $rc = &downloadObject($aid, $command);
    if ($rc) {
      print "Failed downloading data for $aid\n";
      sleep 10 && next; # always wait 10 seconds before next download attempt
    }
    else {
      last; # successful download
    }
  }
}

exit 0;

# Args:   $aid - analysis UUID
#         $command - gtdownload command to execute
# Return: 0 on success, -1 failure
sub downloadObject {
  my ($aid, $command) = @_;

  my $rc = system $command;
  if ($?) {
    # retry once and always wait 10 seconds before retrying
    sleep 10;
    print "ERROR downloading $aid rc = $rc and error = $? Re-Trying...\n";

    # -k 20: allow 20 minutes to provide time to check existing data and resume in case of a partial download.
    $command =~ s/-k 10/-k 20/;
    my $rc = system $command;
    if ($?) {
      print "ERROR downloading $aid rc = $rc and error = $?\n";
      return -1;
    }
  }

  return 0;
}


=head1 NAME

gt.pl - GeneTorrent wrapper

=head1 SYNOPSIS

  gt.pl -a AID [OPTIONS]

    -a|analysisid     Analysis object ID (i.e. 36fbc8a1-0cea-4ceb-ae61-3a026b613f5e)
    -c|threads        Number of cpu cores (called --max-children by GeneTorrent) (default: 1)
    -v|verbose        Display progress every 5 seconds to stdout (default: on)
    -r|ratelimit      Limit network transfer rate (Millions of Bytes MB/s; default 25)
    -y|noverify       Specify that GT should not verify the SSL certificates (default: off)
    -t|test           Show command that would be executed
    -h|help


=head1 EXAMPLE

gt.pl -a 36fbc8a1-0cea-4ceb-ae61-3a026b613f5e
    - Retrieve the analysis object and save in folder by the same name.


=head1 DESCRIPTION


=head1 TODO


=head1 FEEDBACK

Any feedback should be sent to Paul Cantalupo (see email below)


=head1 BUGS

  Contact Paul Cantalupo pcantalupo_at_gmail-dot-com


=head1 AUTHOR

  Paul Cantalupo


=head1 VERSIONS

  0.02

=cut
