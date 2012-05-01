#!/usr/bin/env bash

if [ $# -lt 2 ] ; then
    echo "Usage:   " $0 " <script name> <start | stop> <environment> <working group> <instance id>"
    echo "<environment> defaults to production"
    echo "<working group> and <instance id> are optional and passed to the named script if supplied"
    echo "E.g.     " $0 " generic_worker_daemon_ctl.rb start"
    exit 1
fi

script=$1
action=$2
environment=$3
working_group=$4
instance_id=$5

# set the default environment to production
: ${environment:="production"}

script_directory=`dirname $0`

nuntium_path=`readlink -f $script_directory/..`

cd $nuntium_path/..

rvmrc_contents=`cat $nuntium_path/.rvmrc`
ruby_version=`echo $rvmrc_contents | sed -e 's/rvm use //'`

path_to_ruby=`rvm env --path -- $ruby_version`
full_ruby_version=`basename $path_to_ruby`

/usr/bin/env BUNDLE_GEMFILE=$nuntium_path/Gemfile $rvm_path/gems/$full_ruby_version/bin/bundle exec $rvm_path/rubies/$full_ruby_version/bin/ruby $nuntium_path/lib/services/$script $action -- $environment $working_group $instance_id
