# -*- Mode: perl; indent-tabs-mode: nil -*-
#
# The contents of this file are subject to the Mozilla Public
# License Version 1.1 (the "License"); you may not use this file
# except in compliance with the License. You may obtain a copy of
# the License at http://www.mozilla.org/MPL/
#
# Software distributed under the License is distributed on an "AS
# IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
# implied. See the License for the specific language governing
# rights and limitations under the License.
#
# The Original Code is the BugStats Bugzilla Extension.
#
# The Initial Developer of the Original Code is Wenjin Wu
# Portions created by the Initial Developer are Copyright (C) 2010 the
# Initial Developer. All Rights Reserved.
#
# Contributor(s):
# Wenjin Wu < kevin.wu86@gmail.com >
package Bugzilla::Extension::BugStats;
use strict;
use base qw(Bugzilla::Extension);

# This code for this is in ./extensions/BugStats/lib/Util.pm
use Bugzilla::Extension::BugStats::Util;

our $VERSION = '0.01';
#use constant NAME => 'BugStats';
# See the documentation of Bugzilla::Hook ("perldoc Bugzilla::Hook" 
# in the bugzilla directory) for a list of all available hooks.
sub install_update_db {
    my ($self, $args) = @_;

}

#########    $sth->finish();
# Pages #
#########

sub page_before_template {
    my ($self, $args) = @_;
    my $page = $args->{page_id};
    my $vars = $args->{vars};

   if ($page =~ m{^stats/user\.}) {
       _page_user($vars);
    }
}

sub _page_user {
    my ($vars) = @_;
    my $dbh = Bugzilla->dbh;
    my $user = Bugzilla->user;
    my $input = Bugzilla->input_params;
    my $who_id = $input->{user_id} || $user->id;
    my $who = Bugzilla::User->check({ id => $who_id });

    # 
    my (@sql_statements, %all_bug_ids,@all_bug_cnts, $id, $sql_state);
    my @types= qw( #bugs_reported #bugs_assigned #comment #voting #cc #qa #patch );

    $sql_statements[0] = "SELECT bugs.bug_id FROM  bugs  WHERE bugs.reporter = ?";
    $sql_statements[1] = "SELECT bugs.bug_id FROM  bugs  WHERE bugs.assigned_to = ?";
    $sql_statements[2] = "SELECT DISTINCT longdescs.bug_id FROM longdescs  WHERE longdescs.who = ?";
    $sql_statements[3] = "SELECT votes.bug_id FROM votes  WHERE votes.who = ?";
    $sql_statements[4] = "SELECT cc.bug_id FROM  cc WHERE cc.who = ?";
    $sql_statements[5] = "SELECT bugs.bug_id FROM bugs WHERE bugs.qa_contact = ?";
    $sql_statements[6] = "SELECT attachments.bug_id FROM attachments WHERE attachments.submitter_id = ? AND attachments.ispatch = 1";
    
    
    for (my $index = 0; $index < @sql_statements; $index++){
        my $sth = $dbh->prepare($sql_statements[$index]);
        $sth->execute($who->id);
        my @bug_ids;
        while(($id) = $sth->fetchrow_array())
        {
            push (@bug_ids, $id);
        }
        $all_bug_ids{$types[$index]} = [@bug_ids];
    
        my $cnt = @bug_ids;
        push (@all_bug_cnts, $cnt);
        $sth->finish();
    }

    # Calculate Point for userid
    my $point = log($all_bug_cnts[0] + 1) + log($all_bug_cnts[1]+ 1)*2 + log($all_bug_cnts[2])/log(10) + log($all_bug_cnts[3]+ 1) + log($all_bug_cnts[4] + 1) + 3*log($all_bug_cnts[6] + 1);

    $vars->{'all_bugs'} = \%all_bug_ids;
    $vars->{'point'} = $point;
    $vars->{'user'} = $who;
}
__PACKAGE__->NAME;
