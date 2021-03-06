#!/usr/bin/perl -w
#
#
# WARNING: DO NOT EDIT THIS FILE BY HAND.
#
# This file has been generated by mib2c using the mib2c.perl.conf file
# This is intended to be used by the net-snmp agent with embedded perl
# support. See perldoc NetSNMP::agent
#
# Created on Mon Jan  6 19:06:35 2014
#
# To load this into a running agent with embedded perl support turned
# on, simply put the following line (without the leading # mark) your
# snmpd.conf file:
#
# perl do 'path/to/agent_sys4Pacemaker.pl'
#
# You will need a copy of NetSNMP installed. This has been developed using
# NetSNMP version 5.2.2
#

use NetSNMP::agent::Support;
use NetSNMP::ASN (':all');
use XML::Simple;
use Switch;
use POSIX qw(uname);
use List::Util qw(first);
use Data::Dumper;

my %CIB;
my %cibstatus;
my $cibfilename;
my $statustime = 0;
my @resname = [];
my @resstate = [];
my @resfail = [];

sub init_CIB {

  my $rescounter = 0;
  my $uname = (uname)[1];

  $CIB = XMLin ($cibfilename, Cache => 'memshare',
        GroupTags =>  { nodes => 'node', },
	KeyAttr => { nvpair => 'name', },
        ForceArray => [ 'nvpair', 'primitive', 'group', 'clone', 'master', ],
  );

  if ( (time () - $statustime) > 30) {

    print STDERR "Starting to init pcmk data.\n";

    # Init the %cibstatus hash
    my $dummy = `cibadmin -Q -o status`;
    $cibstatus = XMLin ($dummy, ForceArray => [ 'node_state', ] );

    # Init the resoruces arrays
    my $maxresources = find_MaxResources ();

    # Collect all primitive resource names
    my $primitives = @{$CIB->{configuration}->{resources}->{primitive}};

    for my $i (0 .. $primitives-1) {
      $resname[$i] = $CIB->{configuration}->{resources}->{primitive}[$i]->{id};
    }
    $rescounter = $primitives;

    # Collect all group names and the primitives in the groups.
    my $groups = @{$CIB->{configuration}->{resources}->{group}};

    for my $i (0 .. $groups-1) {
      $resname[$rescounter] = $CIB->{configuration}->{resources}->{group}[$i]->{id};
      $rescounter++;
      my $gp = @{$CIB->{configuration}->{resources}->{group}[$i]->{primitive}};
      for my $j (0 .. $gp-1) {
        $resname[$rescounter] = $CIB->{configuration}->{resources}->{group}[$i]->{primitive}[$j]->{id};
        $rescounter++;
      }
    }

    #  Collect the names of all clone resources
    my $clones = @{$CIB->{configuration}->{resources}->{clone}};
    for my $i (0 .. $clones-1) {
      $resname[$rescounter] = $CIB->{configuration}->{resources}->{clone}[$i]->{id};
      $rescounter++;
    }

    # Collect the names of all master resources
    my $masters = @{$CIB->{configuration}->{resources}->{master}};
    for my $i (0 .. $masters-1) {
      $resname[$rescounter] = $CIB->{configuration}->{resources}->{master}[$i]->{id};
      $rescounter++;
    }

    for my $i (0 .. $maxresources-1) {
      my $command = "crm_resource --resource $resname[$i] --locate 2>/dev/null";
      my @lines = `$command`;

      my $running = 0;
      foreach my $line (@lines) {
        if ($line =~ $uname) {
          if ($running < 1) { $running = 1; }
          if ($line =~ "Master") { $running = 2; }
        }
      }
      $resstate[$i] = $running;
    }

    # Now fill the @resfail
    for my $i (0 .. $maxresources - 1) {
      my $resource = $resname[$i];
      my $nodeattrib = $cibstatus->{node_state}->{$uname}->{transient_attributes}->{instance_attributes}->{nvpair};
      my $failkey = ${$nodeattrib}{ ( first { m/\Qfail-count-$resource/ } keys %{$nodeattrib} ) || '' };
      my $failures = 0;
      if ( $failkey->{'value'} ) { $failures = $failkey->{'value'} };

      $resfail[$i] = $failures;
    }

    $statustime = time ();

  }

}

# -------------------------------------------------------
# Loader for table sys4PcmkNodeTable
# Edit this function to load the data needed for sys4PcmkNodeTable
# This function gets called for every request to columnar
# data in the sys4PcmkNodeTable table
# -------------------------------------------------------
sub load_sys4PcmkNodeTable { 

  init_CIB ();
  
}  
# -------------------------------------------------------
# Index validation for table sys4PcmkNodeTable
# Checks the supplied OID is in range
# Returns 1 if it is and 0 if out of range
# In Table: sys4PcmkNodeTable
# Index: sys4PcmkNodeName
# -------------------------------------------------------
sub check_sys4PcmkNodeTable {
  # The OID is passed as a NetSNMP::OID object
  my ($oid) = shift;

  # The values of the oid elements for the indexes
  my $idx_sys4PcmkNodeIndex = getOidElement($oid, 14);

  # Load the sys4PcmkNodeTable table data
  load_sys4PcmkNodeTable();

  # Check the index is in range and valid
  my $maxNodes = get_sys4PcmkTotalNodes ();
  if (($idx_sys4PcmkNodeIndex < 1) || ( $idx_sys4PcmkNodeIndex > $maxNodes)) {
    return 0;
  } else {
    return 1;
  }
}

# -------------------------------------------------------
# Index walker for table sys4PcmkNodeTable
# Given an OID for a table, returns the next OID in range, 
# or if no more OIDs it returns 0.
# In Table: sys4PcmkNodeTable
# Index: sys4PcmkNodeIndex
# -------------------------------------------------------
sub next_sys4PcmkNodeTable {
  # The OID is passed as a NetSNMP::OID object
  my ($oid) = shift;

  # The values of the oid elements for the indexes
  my $idx_sys4PcmkNodeIndex = getOidElement($oid, 14);

  # Load the sys4PcmkNodeTable table data
  load_sys4PcmkNodeTable();

  # Return the next OID if there is one
  # or return 0 if no more OIDs in this table

  my @idx = $oid->to_array();
  my $index = @idx[-1];
  my $maxNodes = get_sys4PcmkTotalNodes ();
  if (( $index >= 0) && ($index < $maxNodes)) {
    $idx[-1]++;
    my $str = "." . join ".", @idx;
    return new NetSNMP::OID($str);;
  } else {
    return 0;
  }

}

sub get_sys4PcmkNodeIndex {
  # The OID is passed as a NetSNMP::OID object
  my ($oid) = shift;

  # The values of the oid elements for the indexes
  my $idx_sys4PcmkNodeIndex = getOidElement($oid, 14);

  # Load the sys4PcmkNodeTable table data
  load_sys4PcmkNodeTable();

  # Code here to read the required variable from the loaded table
  # using whatever indexing you need.
  # The index has already been checked and found to be valid

  return "$idx_sys4PcmkNodeIndex";

}

sub get_sys4PcmkNodeName {
  # The OID is passed as a NetSNMP::OID object
  my ($oid) = shift;

  # The values of the oid elements for the indexes
  my $idx_sys4PcmkNodeIndex = getOidElement($oid, 14);

  # Load the sys4PcmkNodeTable table data
  load_sys4PcmkNodeTable();

  # Code here to read the required variable from the loaded table
  # using whatever indexing you need.
  # The index has already been checked and found to be valid

  my $name = ${$CIB->{configuration}->{nodes}}[$idx_sys4PcmkNodeIndex - 1]->{uname};

  return "$name";
}

# -------------------------------------------------------
# Handler for columnar object 'sys4PcmkNodeId' 
# OID: .1.3.6.1.4.1.39997.99.4.2.3.1.2
# Syntax: ASN_INTEGER
# From: PACEMAKER-MIB
# In Table: sys4PcmkNodeTable
# Index: sys4PcmkNodeIndex
# -------------------------------------------------------
sub get_sys4PcmkNodeId { 
  # The OID is passed as a NetSNMP::OID object
  my ($oid) = shift;

  # The values of the oid elements for the indexes
  my $idx_sys4PcmkNodeIndex = getOidElement($oid, 14);

  # Load the sys4PcmkNodeTable table data
  load_sys4PcmkNodeTable();

  # Code here to read the required variable from the loaded table
  # using whatever indexing you need.
  # The index has already been checked and found to be valid

  my $name = ${$CIB->{configuration}->{nodes}}[$idx_sys4PcmkNodeIndex-1]->{uname};

  # Sorry, but the CIB does not contain the node ID. So I have to call the command line.
  my $command = "crm_node -l";
  my @nodes = `$command`;
  my @arr;
  foreach my $line (@nodes) {
    if ($line =~ $name) {
      @arr = split (/ /, $line);
    }
  }
  return "$arr[0]";
}

# -------------------------------------------------------
# Handler for columnar object 'sys4PcmkNodeStatus'
# OID: .1.3.6.1.4.1.39997.99.4.2.3.1.4
# Syntax: ASN_INTEGER
# From: PACEMAKER-MIB
# In Table: sys4PcmkNodeTable
# Index: sys4PcmkNodeIndex
# -------------------------------------------------------
sub get_sys4PcmkNodeStatus {
  # The OID is passed as a NetSNMP::OID object
  my ($oid) = shift;

  # The values of the oid elements for the indexes
  my $idx_sys4PcmkNodeIndex = getOidElement($oid, 14);

  # Load the sys4PcmkNodeTable table data
  load_sys4PcmkNodeTable();

  # Code here to read the required variable from the loaded table
  # using whatever indexing you need.
  # The index has already been checked and found to be valid

  my $value = 0;
  my $node = ${$CIB->{configuration}->{nodes}}[$idx_sys4PcmkNodeIndex-1]->{uname};
  if ($cibstatus->{node_state}->{$node}->{crmd} eq "online") {
    if (${$CIB->{configuration}->{nodes}}[$idx_sys4PcmkNodeIndex-1]->{instance_attributes}->{nvpair}->{standby}->{value} eq "off") {
      $value = 1;
    } elsif (${$CIB->{configuration}->{nodes}}[$idx_sys4PcmkNodeIndex-1]->{instance_attributes}->{nvpair}->{standby}->{value} eq "on") {
      $value = 2;
    }
  } elsif ($cibstatus->{node_state}->{$node}->{crmd} eq "offline") {
    $value = 3;
  } else {
    $value = 4;
  }

  return "$value";
}

# -------------------------------------------------------
# Handler for scalar object sys4PcmkTotalNodes
# OID: .1.3.6.1.4.1.39997.99.4.2.1
# Syntax: ASN_INTEGER
# From: PACEMAKER-MIB
# -------------------------------------------------------
sub get_sys4PcmkTotalNodes { 

  init_CIB ();

  my $nodes = scalar @{$CIB->{configuration}->{nodes}};
  return ($nodes);

}
# -------------------------------------------------------
# Handler for scalar object sys4PcmkOnlineNodes
# OID: .1.3.6.1.4.1.39997.99.4.2.2
# Syntax: ASN_INTEGER
# From: PACEMAKER-MIB
# -------------------------------------------------------
sub get_sys4PcmkOnlineNodes { 

  init_CIB ();

  my $maxnodes = get_sys4PcmkTotalNodes ();
  my $onlinecount = 0;

  for my $i (0..$maxnodes-1) {
    my $nodename = ${$CIB->{configuration}->{nodes}}[$i]->{uname};
    if ($cibstatus->{node_state}->{$nodename}->{crmd} eq "online") {
      if ((${$CIB->{configuration}->{nodes}}[$i]->{instance_attributes}->{nvpair}->{standby}->{value} eq "off") ||
          (!exists ${$CIB->{configuration}->{nodes}}[$i]->{instance_attributes}->{nvpair}->{standby}->{value} )) {
        $onlinecount++;
      }
    }
  }

  return ($onlinecount);

}
# -------------------------------------------------------
# Handler for scalar object sys4PcmkResourcePrimitiveNumber
# OID: .1.3.6.1.4.1.39997.99.4.3.1
# Syntax: ASN_INTEGER
# From: PACEMAKER-MIB
# -------------------------------------------------------
sub get_sys4PcmkResourcePrimitiveNumber { 

  my $primitives = scalar @{$CIB->{configuration}->{resources}->{primitive}};
  return "$primitives";

}
# -------------------------------------------------------
# Handler for scalar object sys4PcmkResourceGroupNumber
# OID: .1.3.6.1.4.1.39997.99.4.3.2
# Syntax: ASN_INTEGER
# From: PACEMAKER-MIB
# -------------------------------------------------------
sub get_sys4PcmkResourceGroupNumber { 

  my $groups = @{$CIB->{configuration}->{resources}->{group}};
  return "$groups";

}
# -------------------------------------------------------
# Handler for scalar object sys4PcmkResourceCloneNumber
# OID: .1.3.6.1.4.1.39997.99.4.3.3
# Syntax: ASN_INTEGER
# From: PACEMAKER-MIB
# -------------------------------------------------------
sub get_sys4PcmkResourceCloneNumber { 

  my $clones = @{$CIB->{configuration}->{resources}->{clone}};
  return "$clones";

}
# -------------------------------------------------------
# Handler for scalar object sys4PcmkResourceMasterNumber
# OID: .1.3.6.1.4.1.39997.99.4.3.4
# Syntax: ASN_INTEGER
# From: PACEMAKER-MIB
# -------------------------------------------------------
sub get_sys4PcmkResourceMasterNumber { 

  my $masters = @{$CIB->{configuration}->{resources}->{master}};
  return "$masters";

}
# -------------------------------------------------------
# Handler for scalar object sys4PcmkResourceFailures
# OID: .1.3.6.1.4.1.39997.99.4.3.5
# Syntax: ASN_INTEGER
# From: PACEMAKER-MIB
# -------------------------------------------------------
sub get_sys4PcmkResourceFailures { 

  my $failures = 0;
  foreach my $node ( keys %{$cibstatus->{node_state}} ) {
    foreach my $attribute ( keys %{$cibstatus->{node_state}->{$node}->{transient_attributes}->{instance_attributes}->{nvpair}} ) {
      if ($attribute =~ "^fail-count") {
        $failures += $cibstatus->{node_state}->{$node}->{transient_attributes}->{instance_attributes}->{nvpair}->{$attribute}->{value};
      }
    };
  }
  return "$failures";

}

# -------------------------------------------------------
# Loader for table sys4PcmkResourceTable
# Edit this function to load the data needed for sys4PcmkResourceTable
# This function gets called for every request to columnar
# data in the sys4PcmkResourceTable table
# -------------------------------------------------------
sub load_sys4PcmkResourceTable {

  init_CIB ();

}
# -------------------------------------------------------
# Index validation for table sys4PcmkResourceTable
# Checks the supplied OID is in range
# Returns 1 if it is and 0 if out of range
# In Table: sys4PcmkResourceTable
# Index: sys4PcmkResourceIndex
# -------------------------------------------------------
sub check_sys4PcmkResourceTable {
  # The OID is passed as a NetSNMP::OID object
  my ($oid) = shift;

  # The values of the oid elements for the indexes
  my $idx_sys4PcmkResourceIndex = getOidElement($oid, 14);


  # Load the sys4PcmkResourceTable table data
  load_sys4PcmkResourceTable();

  # Check the index is in range and valid
  my $maxresources = find_MaxResources ();

  if (($idx_sys4PcmkResourceIndex > 0) &&
      ($idx_sys4PcmkResourceIndex < $maxresources+1)) {
    return 1;
  } else {
    return 0;
  }
}

# This function find the number of resources on the node.
# It counts primitive, groups, number of primitives in avery group, clones and masters
sub find_MaxResources {

  # init_CIB ();

  my $primitives = 0;  
  $primitives = @{$CIB->{configuration}->{resources}->{primitive}};

  my $groups = 0;
  $groups = @{$CIB->{configuration}->{resources}->{group}};

  my $gp = 0;
  for my $i (0 .. $groups-1) {
    my $gpi = @{$CIB->{configuration}->{resources}->{group}[$i]->{primitive}};
    $gp += $gpi;
  }

  my $clones = @{$CIB->{configuration}->{resources}->{clone}};

  my $masters = @{$CIB->{configuration}->{resources}->{master}};

  my $resourcesum = $primitives + $groups + $gp + $clones + $masters;
  return "$resourcesum";

}

# -------------------------------------------------------
# Index walker for table sys4PcmkResourceTable
# Given an OID for a table, returns the next OID in range, 
# or if no more OIDs it returns 0.
# In Table: sys4PcmkResourceTable
# Index: sys4PcmkResourceIndex
# -------------------------------------------------------
sub next_sys4PcmkResourceTable {
  # The OID is passed as a NetSNMP::OID object
  my ($oid) = shift;

  # The values of the oid elements for the indexes
  my $idx_sys4PcmkResourceIndex = getOidElement($oid, 14);

  # Load the sys4PcmkResourceTable table data
  load_sys4PcmkResourceTable();

  # Return the next OID if there is one
  # or return 0 if no more OIDs in this table

  my @idx = $oid->to_array();
  my $index = $idx[-1];
  my $maxresources = find_MaxResources ();
  if (( $index >= 0) && ($index < $maxresources)) {
    $idx[-1]++;
    my $str = "." . join ".", @idx;
    return new NetSNMP::OID($str);;
  } else {
    return 0;
  }
}

sub get_sys4PcmkResourceIndex {
  # The OID is passed as a NetSNMP::OID object
  my ($oid) = shift;

  # The values of the oid elements for the indexes
  my $idx_sys4PcmkResourceIndex = getOidElement($oid, 14);

  # Load the sys4PcmkResourceTable table data
  load_sys4PcmkResourceTable();

  # Code here to read the required variable from the loaded table
  # using whatever indexing you need.
  # The index has already been checked and found to be valid

  return "$idx_sys4PcmkResourceIndex";

}


# -------------------------------------------------------
# Handler for columnar object 'sys4PcmkResourceName' 
# OID: .1.3.6.1.4.1.39997.99.4.3.6.1.2
# Syntax: ASN_OCTET_STR
# From: PACEMAKER-MIB
# In Table: sys4PcmkResourceTable
# Index: sys4PcmkResourceIndex
# -------------------------------------------------------
sub get_sys4PcmkResourceName {
  # The OID is passed as a NetSNMP::OID object
  my ($oid) = shift;

  # The values of the oid elements for the indexes
  my $idx_sys4PcmkResourceIndex = getOidElement($oid, 14);

  # Load the sys4PcmkResourceTable table data
  load_sys4PcmkResourceTable();

  # Code here to read the required variable from the loaded table
  # using whatever indexing you need.
  # The index has already been checked and found to be valid

  # TODO
  my $resName = $resname[$idx_sys4PcmkResourceIndex-1];
  return "$resName";
}
# -------------------------------------------------------
# Handler for columnar object 'sys4PcmkResourceStatus' 
# OID: .1.3.6.1.4.1.39997.99.4.3.6.1.3
# Syntax: ASN_INTEGER
# From: PACEMAKER-MIB
# In Table: sys4PcmkResourceTable
# Index: sys4PcmkResourceIndex
# -------------------------------------------------------
sub get_sys4PcmkResourceStatus {
  # The OID is passed as a NetSNMP::OID object
  my ($oid) = shift;

  # The values of the oid elements for the indexes
  my $idx_sys4PcmkResourceIndex = getOidElement($oid, 14);

  # Load the sys4PcmkResourceTable table data
  load_sys4PcmkResourceTable();

  # Code here to read the required variable from the loaded table
  # using whatever indexing you need.
  # The index has already been checked and found to be valid

  my $resstastus = $resstate[$idx_sys4PcmkResourceIndex-1];

  return "$resstastus";
}
# -------------------------------------------------------
# Handler for columnar object 'sys4PcmkResourceFailure' 
# OID: .1.3.6.1.4.1.39997.99.4.3.6.1.4
# Syntax: ASN_INTEGER
# From: PACEMAKER-MIB
# In Table: sys4PcmkResourceTable
# Index: sys4PcmkResourceIndex
# -------------------------------------------------------
sub get_sys4PcmkResourceFailure {
  # The OID is passed as a NetSNMP::OID object
  my ($oid) = shift;

  # The values of the oid elements for the indexes
  my $idx_sys4PcmkResourceIndex = getOidElement($oid, 14);

  # Load the sys4PcmkResourceTable table data
  load_sys4PcmkResourceTable();

  # Code here to read the required variable from the loaded table
  # using whatever indexing you need.
  # The index has already been checked and found to be valid

  my $resfailures = $resfail[$idx_sys4PcmkResourceIndex-1];

  return "$resfailures";

}

# Hash for all OIDs
my  $oidtable={
# Table objects
    ".1.3.6.1.4.1.39996.161.99.4.2.3.1.1.0"=>{func=>\&get_sys4PcmkNodeIndex,type=>ASN_INTEGER, check=>\&check_sys4PcmkNodeTable, nextoid=>\&next_sys4PcmkNodeTable, istable=>'1', next=>"", numindex=>1},
    ".1.3.6.1.4.1.39996.161.99.4.2.3.1.2.0"=>{func=>\&get_sys4PcmkNodeName,type=>ASN_OCTET_STR, check=>\&check_sys4PcmkNodeTable, nextoid=>\&next_sys4PcmkNodeTable, istable=>'1', next=>"", numindex=>1},
    ".1.3.6.1.4.1.39996.161.99.4.2.3.1.3.0"=>{func=>\&get_sys4PcmkNodeId,type=>ASN_INTEGER, check=>\&check_sys4PcmkNodeTable, nextoid=>\&next_sys4PcmkNodeTable, istable=>'1', next=>"", numindex=>1},
    ".1.3.6.1.4.1.39996.161.99.4.2.3.1.4.0"=>{func=>\&get_sys4PcmkNodeStatus,type=>ASN_INTEGER, check=>\&check_sys4PcmkNodeTable, nextoid=>\&next_sys4PcmkNodeTable, istable=>'1', next=>"", numindex=>1},
    ".1.3.6.1.4.1.39996.161.99.4.3.6.1.1.0"=>{func=>\&get_sys4PcmkResourceIndex,type=>ASN_INTEGER, check=>\&check_sys4PcmkResourceTable, nextoid=>\&next_sys4PcmkResourceTable, istable=>'1', next=>"", numindex=>1},
    ".1.3.6.1.4.1.39996.161.99.4.3.6.1.2.0"=>{func=>\&get_sys4PcmkResourceName,type=>ASN_OCTET_STR, check=>\&check_sys4PcmkResourceTable, nextoid=>\&next_sys4PcmkResourceTable, istable=>'1', next=>"", numindex=>1},
    ".1.3.6.1.4.1.39996.161.99.4.3.6.1.3.0"=>{func=>\&get_sys4PcmkResourceStatus,type=>ASN_INTEGER, check=>\&check_sys4PcmkResourceTable, nextoid=>\&next_sys4PcmkResourceTable, istable=>'1', next=>"", numindex=>1},
    ".1.3.6.1.4.1.39996.161.99.4.3.6.1.4.0"=>{func=>\&get_sys4PcmkResourceFailure,type=>ASN_INTEGER, check=>\&check_sys4PcmkResourceTable, nextoid=>\&next_sys4PcmkResourceTable, istable=>'1', next=>"", numindex=>1},
# Scalars
	'.1.3.6.1.4.1.39996.161.99.4.2.1.0'=>{func=>\&get_sys4PcmkTotalNodes,type=>ASN_INTEGER,next=>"", numindex=>1},	
	'.1.3.6.1.4.1.39996.161.99.4.2.2.0'=>{func=>\&get_sys4PcmkOnlineNodes,type=>ASN_INTEGER,next=>"", numindex=>1},	
	'.1.3.6.1.4.1.39996.161.99.4.3.1.0'=>{func=>\&get_sys4PcmkResourcePrimitiveNumber,type=>ASN_INTEGER,next=>"", numindex=>1},	
	'.1.3.6.1.4.1.39996.161.99.4.3.2.0'=>{func=>\&get_sys4PcmkResourceGroupNumber,type=>ASN_INTEGER,next=>"", numindex=>1},	
	'.1.3.6.1.4.1.39996.161.99.4.3.3.0'=>{func=>\&get_sys4PcmkResourceCloneNumber,type=>ASN_INTEGER,next=>"", numindex=>1},	
	'.1.3.6.1.4.1.39996.161.99.4.3.4.0'=>{func=>\&get_sys4PcmkResourceMasterNumber,type=>ASN_INTEGER,next=>"", numindex=>1},	
	'.1.3.6.1.4.1.39996.161.99.4.3.5.0'=>{func=>\&get_sys4PcmkResourceFailures,type=>ASN_INTEGER,next=>"", numindex=>1},	
};

$cibfilename = "/var/lib/heartbeat/crm/cib.xml";
if ( ! -e $cibfilename ) {
  $cibfilename = "/var/lib/pacemaker/crm/cib.xml";
}
if ( ! -e $cibfilename ) {
  $cibfilename = "/var/lib/pacemaker/cib/cib.xml";
}
if ( ! -e $cibfilename ) {
  print STDERR "Error: Could not find CIB.\n";
  exit -1;
}

print STDERR "Initializing pcmk agent from file $cibfilename.\n";
init_CIB ();
print  STDERR "Done pcmk initialization\n";

print "Done init pcmk subagent\n";


# Register the top oid with the agent
# registerAgent($agent, 'sys4Pacemaker', $oidtable);
registerAgent($agent, '.1.3.6.1.4.1.39996.161.99.4', $oidtable);

