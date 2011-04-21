#!/usr/bin/perl
#By Michael Holzt, DL3KJU, kju@fqdn.org, kju@debian.org, kju@IRCNet
#edited by novalis
# impoved by bkuhn over a period of 2005-2010.

use strict;

my ($fn, $onefile, $ofarg) = @ARGV;
if ($onefile ne '-o') {
  $onefile = -1;
} elsif ($ofarg) {
  $onefile = $ofarg;
}

die "Usage: splitgzip.pl <imagefile>\n" if ( $fn eq '' );

print "Reading $fn...\n";
open(IN,"<$fn") or die "Can't open: $fn\n";
my $image;
my $imglen = read(IN,$image, -s $fn);
die("did not get all the bytes, got $imglen expected " . -s $fn)
  if $imglen != -s $fn;
close(IN);

print "Analysing $fn...\n";

my $offset = 0;
my $output = 0;
my $jffs = 0;
my $filenum = 0;
for ( $offset=0; $offset<$imglen; $offset++ )
{
  if (ord(substr($image,$offset,1)) == 0x45 &&
       ord(substr($image,$offset+1,1)) == 0x3d &&
       ord(substr($image,$offset+2,1)) == 0xcd &&
       ord(substr($image,$offset+3,1)) == 0x28 )
  {
    print "Found cramfs-Header at $offset... ";
    close(OUT) if ( $output );
    $fn = "morx$filenum"; #fixme, get name from file if possible

    #hm, magic says this should work, but it didn't on the one i tried
    #$fn = '';
    #$i = 48;
    #while (substr ($image, $offset+$i, 1) ne "\0") {
    #  $fn .= substr ($image, $offset+$i, 1);
    #  $i ++;
    #}
    $filenum++;
    print "Filename $fn.cramfs... writing...\n";
    $fn .= $filenum if -e "$fn.cramfs";
    open(OUT,">$fn.cramfs") or die "Can't open: $fn\n";
    $output = 1;
    if ($onefile >= 0) {
      print OUT substr($image, $offset, 1+$imglen - $offset);
      close(OUT);
      $onefile --;
    }
    if (!$onefile) {
      exit (0);
    }
  }
  if (substr($image,$offset,4) eq "ISc(") {
   close(OUT) if ( $output );
    $fn = "data$filenum";

    $filenum++;
    print "Filename $fn.cab... writing... (don't forget the data1.hdr thing)\n";
    $fn .= $filenum if -e "$fn.cramfs";
    open(OUT,">$fn.cab") or die "Can't open: $fn\n";
    $output = 1;
    if ($onefile >= 0) {
      print OUT substr($image, $offset, 1+$imglen - $offset);
      close(OUT);
      $onefile --;
    }
    if (!$onefile) {
      exit (0);
    }
 }

  if (ord(substr($image,$offset,1)) == 0x5D &&
       ord(substr($image,$offset+1,1)) == 0x00 &&
       ord(substr($image,$offset+2,1)) == 0x00 &&
       ord(substr($image,$offset+3,1)) == 0x80 &&
       ord(substr($image,$offset+4,1)) == 0x00)
  {
    print "Found LZMA-Header at $offset\n";

    close(OUT) if ( $output );

    $fn = '';
    my $x  = 10;
    while ( ord(substr($image,$offset+$x,1)) != 0 )
    {
      $fn .= substr($image,$offset+$x,1);
      $x++;
    }
    $fn = substr ($fn, 0, 10);
    if ($fn !~ /^[\w-.]+$/) {
      $fn = "morx$filenum";
    }
    $filenum ++;
    $fn .= $filenum if -e "$fn.lzma";
    print "Filename $fn.lzma... writing...\n";
    open(OUT,">$fn.lzma") or die "Can't open: $fn\n";
    if ($onefile) {
      print OUT substr($image, $offset, 1+$imglen - $offset);
      close(OUT);
      $onefile --;
    }
    if (!$onefile) {
      exit (0);
    }
    $output = 1;
  }
  if (ord(substr($image,$offset,1)) == 0x1F &&
       ord(substr($image,$offset+1,1)) == 0x8B &&
       ord(substr($image,$offset+2,1)) == 0x08 )
  {
    #fixme
    #if ($onefile && $output) {
    #  next;
    #}
    print "Found GZIP-Header at $offset\n";

    close(OUT) if ( $output );

    $fn = '';
    my $x  = 10;
    while ( ord(substr($image,$offset+$x,1)) != 0 )
    {
      $fn .= substr($image,$offset+$x,1);
      $x++;
    }
    $fn = substr ($fn, 0, 10);
    if ($fn !~ /^[\w-.]+$/) {
      $fn = "morx$filenum";
    }
    $filenum ++;
    $fn .= $filenum if -e "$fn.gz";
    print "Filename $fn.gz... writing...\n";
    open(OUT,">$fn.gz") or die "Can't open: $fn\n";
    if ($onefile) {
      print OUT substr($image, $offset, 1+$imglen - $offset);
      close(OUT);
      $onefile --;
    }
    if (!$onefile) {
      exit (0);
    }
    $output = 1;
  }

  if (substr($image,$offset,3) eq "BZh") {
    #fixme
    #if ($onefile && $output) {
    #  next;
    #}
    print "Found Bzip-Header at $offset\n";

    close(OUT) if ( $output );

    $fn = '';
    my $x  = 0;
    while ( ord(substr($image,$offset+$x,1)) != 0 )
    {
      $fn .= substr($image,$offset+$x,1);
      $x++;
    }
    $fn = substr ($fn, 0, 10);
    if ($fn !~ /^[\w-.]+$/) {
      $fn = "morx$filenum";
    }
    $filenum ++;
    $fn .= $filenum if -e "$fn.bz2";
    print "Filename $fn.bz2... writing...\n";
    open(OUT,">$fn.bz2") or die "Can't open: $fn\n";
    if ($onefile) {
      print OUT substr($image, $offset, 1+$imglen - $offset);
      close(OUT);
      $onefile --;
    }
    if (!$onefile) {
      exit (0);
    }
    $output = 1;
  }

  if (substr($image,$offset,4) eq "sqsh" or
      substr($image,$offset,4) eq "hsqs") {
    #fixme
    #if ($onefile && $output) {
    #  next;
    #}
    my $endianIs = (substr($image,$offset,4) eq "sqsh") ? "big" : "little";
    print "Found squashfs filesystem, $endianIs endian at $offset\n";

    close(OUT) if ( $output );

    $fn = "morx$filenum";
    $filenum ++;
    $fn .= $filenum if -e "$fn.squash";
    print "Filename $fn.squash... writing...\n";
    open(OUT,">$fn.squash") or die "Can't open: $fn\n";
    if ($onefile) {
      print OUT substr($image, $offset, 1+$imglen - $offset);
      close(OUT);
      $onefile --;
    }
    if (!$onefile) {
      exit (0);
    }
    $output = 1;
  }

  if (substr($image,$offset,3) eq "Rar") {
    #fixme
    #if ($onefile && $output) {
    #  next;
    #}
    print "Found Rar at $offset (this hasn't been tested yet, might be saving wrong stuff)\n";

    close(OUT) if ( $output );

    $fn = '';
    my $x  = 0;
    while ( ord(substr($image,$offset+$x,1)) != 0 )
    {
      $fn .= substr($image,$offset+$x,1);
      $x++;
    }
    $fn = substr ($fn, 0, 10);
    if ($fn !~ /^[\w-.]+$/) {
      $fn = "morx$filenum";
    }
    $filenum ++;
    $fn .= $filenum if -e "$fn.rar";
    print "Filename $fn.rar... writing...\n";
    open(OUT,">$fn.rar") or die "Can't open: $fn\n";
    if ($onefile) {
      print OUT substr($image, $offset, 1+$imglen - $offset);
      close(OUT);
      $onefile --;
    }
    if (!$onefile) {
      exit (0);
    }
    $output = 1;
  }

  if (ord(substr($image,$offset+1,1)) == 0x39 &&
       ord(substr($image,$offset,1)) == 0x31 &&
       ord(substr($image,$offset+3,1)) == 0x34 &&
       ord(substr($image,$offset+2,1)) == 0x38)
    {
    $jffs = 1;
    print "Found JFFS Magic Bitmask at $offset\n";
    
    close(OUT) if ( $output );
    
    $fn = "morx$filenum";
    $filenum ++;
    $fn .= $filenum if -e "$fn.jffs";
    print "Filename $fn.jffs... writing...\n";
    open(OUT,">$fn.jffs") or die "Can't open: $fn\n";
    if ($onefile) {
      print OUT substr($image, $offset, 1+$imglen - $offset);
      close(OUT);
      $onefile --;
    }
    if (!$onefile) {
      exit (0);
    }
    $output = 1;
  }

# This Ext2 code doesn't work.  I googled around looking or a way to read it
#   but could not find one.
#   if (ord(substr($image,$offset,1)) == 0x53 &&
#        ord(substr($image,$offset+1,1)) == 0xef &&
#        ord(substr($image,$offset+2,1)) == 0x01 &&
#        ord(substr($image,$offset+3,1)) == 0x00)

#     {
#     print "Found EXT2/3 Magic Bitmask at $offset\n";
    
#     close(OUT) if ( $output );
    
#     $fn = "morx$filenum";
#     $filenum ++;
#     $fn .= $filenum if -e "$fn.ext";
#     print "Filename $fn.ext... writing...\n";
#     open(OUT,">$fn.ext") or die "Can't open: $fn\n";
#     if ($onefile) {
#       print OUT substr($image, $offset, 1+$imglen - $offset);
#       close(OUT);
#       $onefile --;
#     }
#     if (!$onefile) {
#       exit (0);
#     }
#     $output = 1;
#   }

  if (ord(substr($image,$offset,1)) == 0x85 &&
       ord(substr($image,$offset+1,1)) == 0x19 &&
       ord(substr($image,$offset+2,1)) == 0x03 &&
       ord(substr($image,$offset+3,1)) == 0x20)

    {
    $jffs = 1;
    print "Found JFFS2 Magic Bitmask at $offset\n";
    
    close(OUT) if ( $output );
    
    $fn = "morx$filenum";
    $filenum ++;
    $fn .= $filenum if -e "$fn.jffs2";
    print "Filename $fn.jffs2... writing...\n";
    open(OUT,">$fn.jffs2") or die "Can't open: $fn\n";
    if ($onefile) {
      print OUT substr($image, $offset, 1+$imglen - $offset);
      close(OUT);
      $onefile --;
    }
    if (!$onefile) {
      exit (0);
    }
    $output = 1;
  }


  print OUT substr($image,$offset,1) if ( $output );
}

close(OUT) if ( $output );
