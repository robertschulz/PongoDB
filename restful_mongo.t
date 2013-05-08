#!/usr/bin/perl
##============================================
## Tests for PONGO: A Perl Rest Layer MongoDB
##============================================
use JSON::XS;
use MongoDB;
use MongoDB::OID;
use MongoDB::GridFS;
use Text::TabularDisplay;
use Data::Dumper;
use HTTP::Request::Common;
use LWP::UserAgent;
use URI::Escape;

## The Setup
my $service_location = 'http://localhost:8080/mongo_services';
my $mongo_database   = 'pongo_test';
my $collection_name  = 'documents';

## The Connect:
my $conn = MongoDB::Connection->new;
my $db   = $conn->get_database($mongo_database); 

## The Collections:
my $collection = $db->get_collection($collection_name);
   $collection->drop;

##Add Some Test Data. Note Data Types on digitz!
my $test_data = {
                      a=>[1,2,3],
                      b=>{a=>'1',b=>'2',c=>'3'},
                      c=>[{a=>1,b=>2,c=>3}, {a=>4,b=>5,c=>6}],
                      d=>1,
                      e=>'foo'
                };
$collection->insert($test_data);

## Stuffz we will use
my ($orig_data, $directives, $new_data, $web_results);



##=============================================
## TEST ONE =>
## Read this as follows:
## In database $mongo_database,
## and collection named $collection_name,
## find all records with {"e":"foo", "d":1}
## and set new_field1 = 1
##=============================================
##Snap It
$orig_data = snapshot_data();

##Make It
$directives = {
                find              => '{"e":"foo", "d":1}',
                action            => 'set',
                new_field1        => '1'
              };

##Post It
$web_results = post_data($directives);
 
##Get It
$new_data = snapshot_data();

##Print It
compare_results($orig_data, $new_data);

##Check It
affirm($directives);


##=============================================
## TEST TWO =>
## find all records with {"e":"foo", "d":1}
## and remove new_field1 = 1
##=============================================
##Snap It
$orig_data = snapshot_data();

##Make It
$directives = {
                find              => '{"e":"foo", "d":1}',
                action            => 'unset',
                new_field1        => '1'
              };

##Post It
$web_results = post_data($directives);
 
##Get It
$new_data = snapshot_data();

##Print It
compare_results($orig_data, $new_data);

##Check It
affirm($directives);


##=============================================
## TEST THREE =>
## find all records with {"e":"foo", "d":1}
## and push a hash onto an array of hashes
##=============================================
##Snap It
$orig_data = snapshot_data();

##Make It
$directives = {
                find              => '{"e":"foo", "d":1}',
                action            => 'push',
                c                 => '{"Thats":"Pretty","Wicked":"Retarded"}'
              };

##Post It
$web_results = post_data($directives);
 
##Get It
$new_data = snapshot_data();

##Print It
compare_results($orig_data, $new_data);

##Check It
affirm($directives);


##=============================================
## TEST FOUR =>
## find all records with {"e":"foo", "d":1}
## and pop a hash off array of hashes
##=============================================
##Snap It
$orig_data = snapshot_data();

##Make It
$directives = {
                find              => '{"e":"foo", "d":1}',
                action            => 'pop',
                c                 =>  -1
              };

##Post It
$web_results = post_data($directives);
 
##Get It
$new_data = snapshot_data();

##Print It
compare_results($orig_data, $new_data);

##Check It
affirm($directives);



##=============================================
## TEST FIVE =>
## find all records with {"e":"foo", "d":1}
## and set a specific hash element of "b"
##=============================================
##Snap It
$orig_data = snapshot_data();

##Make It
$directives = {
                find              => '{"e":"foo", "d":1}',
                action            => 'set',
               'b.c'              =>  7
              };

##Post It
$web_results = post_data($directives);
 
##Get It
$new_data = snapshot_data();

##Print It
compare_results($orig_data, $new_data);

##Check It
affirm($directives);



##=============================================
## TEST SIX =>
## find all records with {"e":"foo", "c.a":4}
## and set a specific hash element of "THIS"
## element in the array of objects!!
##=============================================
##Snap It
$orig_data = snapshot_data();

##Make It
$directives = {
                find              => '{"e":"foo", "c.a":4}',
                action            => 'set',
               'c.$.new_field'    => 'Crazy Power!' 
              };

##Post It
$web_results = post_data($directives);
 
##Get It
$new_data = snapshot_data();

##Print It
compare_results($orig_data, $new_data);

##Check It
affirm($directives);


##=============================================
## TEST SEVEN =>
## find all records with {"e":"foo", "c.a":4}
## and set a specific hash element of "THIS"
## element in the array of objects!!
##=============================================
##Snap It
$orig_data = snapshot_data();

##Make It
$directives = {
                find              => '{"e":"foo"}',
                action            => 'pull',
                c                 => '{"new_field":"Crazy Power!"}' 
              };

##Post It
$web_results = post_data($directives);
 
##Get It
$new_data = snapshot_data();

##Print It
compare_results($orig_data, $new_data);

##Check It
affirm($directives);





##==========================================================
## Supporting Subs Below
##==========================================================
sub snapshot_data {
   my $doc = $collection->find_one({},{'_id'=>0});
   my $dumper = Data::Dumper->new([$doc]);
   my $data = $dumper->Sortkeys(1)->Dump();
   return $data;
}

sub post_data {
   my $directives = shift;
   my $ua = LWP::UserAgent->new;
   my $req = POST($service_location,
                  { 
                   db                => $mongo_database, 
                   update_collection => $collection_name,
                   %$directives
                  }
                 );

   my $query_string = uri_unescape($req->as_string()); 
      $query_string =~s/\+/ /g;
   
   print "$query_string\n";
   return $ua->request($req)->as_string;
}

sub compare_results {
   my ($orig_data, $new_data) = @_;
   my $table = Text::TabularDisplay->new('Pre Change', 'Post Change');
   $table->add($orig_data, $new_data);
   print $table->render(),"\n";
}

sub affirm {

   my $directives = shift;

   print "FIND $directives->{find} ", uc($directives->{action}), " ";
   delete $directives->{find};
   delete $directives->{action};
   for(keys %$directives){ print "$_ = $directives->{$_}\n"; }
   print "\nMake sense? ";
   my $go = <STDIN>;
   
   unless($go=~/y/i or $go!~/[a-z0-9]/i){
     print  "\nLook more closely.\n"; 
     exit 0;
   }

   print "\n\n";

}

__END__
curl --data 'db=pongo_test' \
        --data 'update_collection=documents' \
        --data 'find={"e":"foo", "d":1}' \
        --data 'action=set' \
        --data 'f=1' \
        http://localhost:8080/mongo_services



curl --data 'update_encounter=123456789' \
     --data 'action=push' \
     --data 'data.workspaces={"some_code":"v71.9"}' \
     http://localhost:8080/mongo_services


curl --data 'update_encounter=123456789' \
     --data 'action=pop' \
     --data 'data.workspaces=-1' \
     http://localhost:8080/mongo_services


curl --data 'update_encounter=123456789' \
     --data 'action=set' \
     --data 'data.age=77' \
     http://localhost:8080/mongo_services


curl --data 'update_encounter=123456789' \
     --data 'action=unset' \
     --data 'data.age=1' \
     http://localhost:8080/mongo_services
 


http://localhost:8080/mongo_services
            ?update_collection=encounters
            &find={"data.account_number":123456789, "data.code_set.ICD9.codes.id":4}
            &action=set
            &data.code_set.ICD9.codes.$.new_attribute=someshit



#my $hits = $collection->find_one({},{'_id'=>1});
#while (my $doc = $hits->next) {
#    print Dumper($doc),"\n";
#}
