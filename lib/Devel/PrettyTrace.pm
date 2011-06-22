package Devel::PrettyTrace;

use 5.005;
use strict;

use parent qw(Exporter);
use Data::Printer;
use List::MoreUtils qw(all);

our $VERSION = '0.01';
our @EXPORT = qw(bt);

our $Indent = '  ';
our $Evalen = 40;
our $Deeplimit = 5;
our %Opts = (
    colored		=> 1,
    class 		=> {
        internals       => 1,
        show_methods    => 'none',
        parents         => 0,
        linear_isa      => 0,
        expand          => 1,
    },
    max_depth	=> 2,
);

sub bt{
    my ($deepness) = @_;
    
    $deepness = $Deeplimit if !defined $deepness;
    $deepness = 999 if $deepness <= 0;

    #local @DB::args;
    my $ret = '';
    my $i = 1;	#skip own call
    
    while (
        $i < $deepness
            &&
        (my @info = get_caller_info($i + 1))	#+1 as we introduce another call frame
    ){
        $ret .= format_call(\@info);
        $i++;
    }
    
    if (defined wantarray){
        return $ret;
    }else{
        print STDERR $ret;
    }
}

sub format_call{
    my $info = shift;

    my $result = $Indent;
    
    if (defined $info->[6]){
        if ($info->[7]){
            $result .= "require $info->[6]";
            
        }else{
            $info->[6] =~ s/\n;$/;/;
            $result .= "eval '".trim_to_length($info->[6], $Evalen)."'";
        }
        
    }elsif ($info->[3] eq '(eval)'){
            $result .= 'eval {...}';
            
    }else{
        $result .= $info->[3];
    }
    
    if ($info->[4]){
        $result .= "(";
    
        if (scalar @DB::args){
            $result .= format_args();
        }
        
        $result .= ')';
    }
    
    $result .= " called at $info->[1] line $info->[2]\n";

    return $result;
}

sub format_args{
    my $result = p(@DB::args, %Opts);
    
    #result is always non-empty array, so transform [\n a\n b\n] => \n\t\t a \n\t\t b \n\t
    $result =~ s/^.*?\n/\n/;
    $result =~ s/\]$//;
    $result =~ s/\n/\n$Indent/go;
    
    return $result;
}

sub trim_to_length{
    my ($str, $len) = @_;
    
    if ($len > 2 && length($str) > $len){
        substr($str, $len - 3) = '...';
    }
    
    return $str;
}

sub get_caller_info{
    my $level = shift;

    do {
        package DB;
        @DB::args = ();
        return caller($level);
    };
}

1;
