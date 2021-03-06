use Cro::WebApp::Form;

say "Initializing Workshop";

#slightly tweaked example of gfldex Low profile quoting post
#viz. https://gfldex.wordpress.com/2021/06/01/low-profile-quoting/
#viz. https://p6steve.wordpress.com/2021/06/04/414/
#in Comma IDE set ⌘, - editor - color scheme - raku - bad syntax OFF
#nb. use '' quotes where you embed Cro tags in the payload (not needed for attr)

constant term:<§> = class :: does Associative {
    sub qh($s) {
        $s.trans([ '<'   , '>'   , '&' ] =>
                 [ '«'   , '»'   , '§' ]);                  #first shift some things "aside"
        
        $s ~~ s:g/'«' <[.?!$@:&|]> (<-[»]>)* '»' /<$0>/;    #second handle all the Cro tags
        
        $s.trans([ '«'   , '»'   , '§' ] =>
                 [ '&lt;', '&gt;', '&amp;' ]);              #third shift back to do residual HTML tags
    }
    sub et($k) {
        my @empty-tags = <area base br col hr img input link meta param command keygen source>;
        ' /' if $k ~~ @empty-tags.any
    }
    sub qa(%_) {
        %_.map({
            if    .value ~~ Bool && True     { .key }
            elsif .value ~~ /^ <[.?!$@:&|]>/ { .key ~ '="<' ~ .value ~ '>"' }  #Cro Template char set
            else                             { .key ~ '="'  ~ .value ~  '"' }
        }).join(' ')
    }
    
    role NON-QUOTE {}
    
    method AT-KEY($key) {
        when $key ~~ /^ '&' / {
            $key does NON-QUOTE
        }
        when $key ~~ /\w+/ {
            sub (*@a, *%_) {
                #dd @a;
                (
                '<' ~ $key ~ (+%_ ?? ' ' !! '')
                    ~ qa(%_) ~ et($key) ~ '>'
                    ~ @a.map({ $^a ~~ NON-QUOTE ?? $^a !! qh($^a) }).join('')
                    ~ (et($key) ?? '' !! '</' ~ $key ~ '>')
                ) does NON-QUOTE
            }
        }
    }
}

sub pretty-print-html(Str $html is rw --> Str) {
    $html ~~ s:g/'<' <!before <[.?!$@:&|/]>>/$?NL\</;     #Cro Template char set + end tag '/'
    $html ~~ s:g/'><'/\>$?NL\</;
    return '<!DOCTYPE html>' ~ $html;
}

class Context {
    has $.action = 'mailto:you@p6steve.com';
    has $.cf-name = 'p6steve';
    has $.cf-email = 'me@p6steve.com';
    has $.cf-subject = 'Raku does HTML';
    has $.cf-message = 'Describe some of your feelings about this...';
}
class Review does Cro::WebApp::Form {
    has Str $.name is required;
    has Int $.rating is required will select { 1..5 };
    has Str $.comment is multiline(:5rows, :60cols) is maxlength(1000);
}
class Workshop {
    method context() {
        Context.new;
    }
    method init() {
        self.init-qform;
        self.init-cform;
    }
    method init-cform() {
        #It is possible to mix LPQ and Cro::WebApp::Form s like this
        #Since the &form is in the payload, use must double quotes "" and backwhack the \&
        my $html =  §<html>(§<body>(
                §<h1>('Submit a review'),
                "<\&form(.form, :submit-button-text('Send your review'))>"
            )
        );
        spurt "templates/cform.crotmp", pretty-print-html($html);
    }
    method init-qform() {
        ##say dir "templates/";
        
        my $css = q:to/END/;
        #demoFont {
        font-size: 16px;
        color: #ff0000;
        }
        END
        
        my $size = <40>;
        my $pattern = <[a-zA-Z0-9 ]+>;
        
        my $html = §<html>(§<head>(§<title>()),
            §<style>(:type<text/css>, $css),
            §<body>(
                §<form>(:action<.action>, :method<post>,
                    §<p>('Your Name (required)'),
                    §<input>(:type<text>, :required, :name<cf-name>, :value<.cf-name>, :$size, :$pattern,),

                    §<p>('Your Email (required)'),
                    §<input>(:type<email>, :required, :name<cf-email>, :value<.cf-email>, :$size,),  #email type validates input

                    §<p>('Your Subject (required)'),
                    §<input>(:type<text>, :required, :name<cf-subject>, :value<.cf-subject>, :$size, :$pattern,),

                    §<p>(:id<demoFont>, 'Your Message (required)'),
                    §<p>(§<textarea>(:rows<10>, :cols<35>, :required, :name<cf-message>, '<.cf-message>', ),),

                    §<input>(:type<submit>, :name<cf-submitted>, :value<Send>,),
                )
            )
        );
        spurt "templates/qform.crotmp", pretty-print-html($html);
    }
}