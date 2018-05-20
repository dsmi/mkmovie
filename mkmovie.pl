#!/usr/bin/perl -w
# 
# Command-line video editor
#  Processes files with the records of the following form:
# fname.mp4 starttime endtime
# When done call 'ffmpeg -f concat -safe 0 -i mylist.txt -c copy output.mp4'
# to contat the pieces together
# Refer to examples.

# default options
my %copts = ( 
  '00.ffm' => '$ffm',
  '01.owr' => '-y',
  '10.sst' => '-ss $start',
  '20.inp' => '-i $movfile',
  '21.dur' => '-t $dur',
  '30.vcd' => '-vcodec libx264 -crf 18',
  '40.pfn' => '$partfn'
);

my $ffm = 'ffmpeg';
my $listfn = 'mylist.txt';

sub parse_time
{
    my($min, $sec) = $_[0] =~ /(\d+):(\d+)/;
    return $min * 60 + $sec;
}

my $npart = 0;

open(my $ofh, '>', $listfn)
  or die "Could not open file '$listfn' $!";

while(<STDIN>)
{
    if ( (/^\s*#/) or (/^\s*$/) )
    {
        # empty line or comment
    }
    elsif ( /^x\s+(.*)$/ )
    {
        eval( $1 );
    }
    elsif ( /^\+\s*([\w\.]+)\s+(.*)$/ )
    {
        $copts{ $1 } = $2;
    }
    elsif ( /^\-\s*([\w\.]+)/ )
    {
        delete $copts{ $1 };
    }
    else
    {
        my ($movfile, $starts, $ends) = split(/\s+/);
        my $start = parse_time($starts);
        my $end = parse_time($ends);
        my $dur = $end - $start;
        my $partfn = sprintf("part%03d.mp4", ++$npart);
        print "Doing $partfn: $movfile from $starts to $ends duration $dur\n";
        my $cmdl = join(' ', @copts{sort keys %copts}); # compose the cmdline
        $cmdl =~ s/(\$\w+)/$1/eeg; # expand variables
        print "cmdline: $cmdl\n";
        system($cmdl) == 0 or die "system $cmdl failed: $?";
        printf $ofh "file $partfn\n";
    }
}
