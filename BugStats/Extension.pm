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
# The Initial Developer of the Original Code is YOUR NAME
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

#########
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

    my ($id, @reported_bug_id, @assigned_bug_id, @commented_bug_id, @voted_bug_id, @cc_bug_id, @qa_bug_id, @patch_bug_id);

    # bug reporter
    my $sth = $dbh->prepare('SELECT bugs.bug_id 
                             FROM  bugs  WHERE bugs.reporter = ?');
    $sth->execute($who->id);
    while(($id) = $sth->fetchrow_array())
    {
        push (@reported_bug_id, $id);
    }
#   sort{$a <=> $b}@reported_bug_id;
    $sth->finish();
    
    # bug assigned to
    $sth = $dbh->prepare('SELECT bugs.bug_id 
                          FROM  bugs  WHERE bugs.assigned_to = ?');
    $sth->execute($who->id);
    while(($id) = $sth->fetchrow_array())
    {
        push (@assigned_bug_id, $id);
    }
#    sort{$a <=> $b}@assigned_bug_id;
#    my $tmp = join(',',@assigned_bug_id);
#    warn "id list: $tmp";
#    my $size = @assigned_bug_id;
#    warn "size: $size";

    $sth->finish();
    
    # comments
    $sth = $dbh->prepare('SELECT DISTINCT longdescs.bug_id
                          FROM longdescs
                          WHERE longdescs.who = ? ');
    $sth->execute($who->id);
    while(($id) = $sth->fetchrow_array())
    {
        push (@commented_bug_id, $id);
    }
    $sth->finish();
    
    # voting
    $sth = $dbh->prepare('SELECT votes.bug_id 
                          FROM votes 
                          WHERE votes.who = ?');
    $sth->execute($who->id);
    while (($id) = $sth->fetchrow_array())
    {
        push (@voted_bug_id, $id);
    }
#   sort{$a <=> $b}@voted_bug_id;
    $sth->finish();

    # CC List
    $sth = $dbh->prepare('SELECT cc.bug_id
                          FROM  cc
                          WHERE cc.who = ?');
    $sth->execute($who->id);
    while (($id) = $sth->fetchrow_array())
    {
        push (@cc_bug_id, $id);
    }
    $sth->finish();

    # QA Field
    $sth = $dbh->prepare('SELECT bugs.bug_id
                          FROM bugs
                          WHERE bugs.qa_contact = ?');
    $sth->execute($who->id);
    while (($id) = $sth->fetchrow_array())
    {
        push(@qa_bug_id, $id);
    }

    # bug Patch
    $sth = $dbh->prepare('SELECT attachments.bug_id
                          FROM attachments
                          WHERE attachments.submitter_id = ? AND attachments.ispatch = 1');
    $sth->execute($who->id);
    while (($id) = $sth->fetchrow_array())
    {
        push(@patch_bug_id, $id);
    }

    # Calculate Point for userid
    my $s1 = @reported_bug_id;
    my $s2 = @assigned_bug_id;
    my $s3 = @commented_bug_id;
    my $s4 = @voted_bug_id;
    my $s5 = @cc_bug_id;
    my $s6 = @qa_bug_id;
    my $s7 = @patch_bug_id;

    my $point = log($s3)/log(10) + log($s1 + 1) + log($s2 + 1)*2 + log($4 + 1) + log($5 + 1) + 3*log($s7 + 1);
    $vars->{'all_reported_bug_id'}  = \@reported_bug_id;
    $vars->{'all_assigned_bug_id'}  = \@assigned_bug_id;
    $vars->{'all_commented_bug_id'} = \@commented_bug_id;
    $vars->{'all_voted_bug_id'}     = \@voted_bug_id;
    $vars->{'all_cc_bug_id'}        = \@cc_bug_id;
    $vars->{'all_qa_bug_id'}        = \@qa_bug_id;
    $vars->{'all_patch_bug_id'}     = \@patch_bug_id;
    
    $vars->{'point'} = $point;
    $vars->{'user'} = $who;
    $vars->{'types'} = ['#bugs_reported', '#bugs_assigned', '#comment', '#voting', '#cc', '#qa','#patch','point'];
}
__PACKAGE__->NAME;
