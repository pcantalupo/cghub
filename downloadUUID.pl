#!/usr/bin/env perl
# Copied directly from https://annai.egnyte.com/dl/6gGNAqsGsL
use strict;
use warnings;

 
local $ENV{PATH} = "$ENV{PATH}:/usr/bin";
 
$usage = "usage $0 <list-file> <site> <key-file> <data_dir> \n";
 
if ($#ARGV != 3)
{
    print $usage;
    exit;
}
 
# get commandline arguments
$listFile = shift;
$source = shift;
$credFile = shift;
$dataDir = shift;
 
if (! -e $listFile)
{
    print $usage;
    print "List File $listFile not found \n";exit;
}
 
if (! -e $credFile)
{
    print $usage;
    print "Key File $credFile not found \n";exit;
}
 
if (! -d $dataDir)
{
    print $usage;
    print "Download Directory $dataDir not found \n";exit;
}
 
 
@uuidList = &initFileList($listFile);
$listSize = @uuidList;
 
# number of total download attempts
# allows an average of 3 ttwmpts per UUID
$tryLimit = $listSize * 3;
$tryCount = 0;
 
foreach $uuid(@uuidList)
{
    $tryCount++;
    if ($tryCount++ > $tryLimit)
    {
        print "Retry limit exceeded. Please check your list and try again later \n";
        exit;
    }
 
    # download data (with one retry)
    $rc = &downloadObject($uuid, $source);
    if ($rc)
    {
        print "Failed downloading data for $uuid from $source \n";
 
        # download failed so push the UUID back onto the list
        push(@uuidList, $uuid);
    }
 
    # always wait 10 seconds before next download attempt
    sleep 10;
}
 
exit;
 
 
sub downloadObject
{
    my $uuid = $_[0];
    my $site = $_[1];
    $dlUri = "$site/cghub/data/analysis/download/$uuid";
 
    # call gtdownload with:
    # -v        display progress every 5 seconds
    # --max-children 4  use 4 cpu cores for this download
    # -k 10     terminate the gtdownload attempt if no data is transferred within any 10 minute interval
    # -c <file>       path to the GNOS access token for the target repository
    # -p <directory>  path to the directory where the downloaded data is stored
    my $rc = system "gtdownload -v --max-children 4 -k 10 -c $credFile -p $dataDir $dlUri";
    if ($?)
    {
        # retry once
        # always wait 10 seconds before retrying
        sleep 10;
        print "ERROR downloading $uuid rc = $rc and error = $? Re-Trying...\n";
 
        # -k 20     allow 20 minutes to provide time to check existing data and resume in case of a partial download.
        my $rc = system "gtdownload -v --max-children 4 -k 20 -c $credFile -p $dataDir $dlUri";
        if ($?)
        {
            print "ERROR downloading $uuid rc = $rc and error = $? \n";
            return -1;
        }
    }
 
    return 0;
}
 
 
 
 
sub initFileList
{
    my $inputFile = shift;
    my @fileList = ();
 
    # open read close file
    open(DAT, "$inputFile") || die("Could not open input file! $inputFile");
    my @alllines=<DAT>;
    close(DAT);
 
    # strip out the tags leaving only uuid
    foreach $line (@alllines)
    {
        ($t1,$tag,$t3,$uuid,$nada)=split(/\s+/,$line);
        # check if cgquery output
        if ($tag eq 'analysis_id')
        {
            $newUuid = $uuid;
        }
        else
        {
            $newUuid = $line;
        }
        $newUuid =~ s/^\s+|\s+$//g;
        push(@fileList, $newUuid);
    }
 
    return @fileList;
}
