#!/bin/bash
#Author: Vasilis Nicolaou
#version: 0.1
#Copyright (c) CERN 2013
#Summer 2013
#Description: Merges ro user database with the rw one
VERSION=0.1
USERNAME=1
PASSWORD=2
USER_ID=3
GROUP_ID=4
INFO=5
HOME_DIR=6
LOGIN_SHELL=7
ifs_bck=$IFS
IFS=$'\n'
function id_exists {
    exists=""
    for user in `cat "$am_WORKING_DIR/newdb.tmp"`; do
        user_id=`echo $user | cut -d ':' -f $USER_ID`
        if [ $user_id -eq $1 ]; then
            exists="$user_id"
            echo $user_id exists
            break
        fi
    done
    echo "$exists"
}

user_update() {
    #set up
    cp "$1" "$am_WORKING_DIR/users.tmp" #at the end of the first for loop
    cp "$2" "$am_WORKING_DIR/rw_users.tmp"
    [ -f "$am_WORKING_DIR/map.tmp" ] && {
        rm "$am_WORKING_DIR/map.tmp"
    }
    touch "$am_WORKING_DIR/map.tmp"
    #---------deal with existing users on both databases--------
    for line in `cat $1`; do
        username=`echo $line | cut -d ':' -f $USERNAME`
        echo "username: $username"
        a=`cat "$2" | grep -w -o -e "$username:.*:.*"`
	    echo "a is: $a"
        if [ -n "$a" ]; then
            real_id=`echo "$line" | cut -d ':' -f $USER_ID`
            virtual_id=`echo "$a" | cut -d ':' -f $USER_ID`
            if [ "$virtual_id" != "$real_id" ]; then
		        echo "Same username $username but different ids: r:$real_id v:$virtual_id"
                echo "$real_id $virtual_id" | cat >>"$am_WORKING_DIR/map.tmp"
            fi
            echo "$a" | cat >>"$am_WORKING_DIR/newdb.tmp"
            #remove added rw user from potential new users
            cat "$am_WORKING_DIR/users.tmp" | grep -v "$line" | cat >"$am_WORKING_DIR/users2.tmp"
            mv "$am_WORKING_DIR/users2.tmp" "$am_WORKING_DIR/users.tmp"
            cat "$am_WORKING_DIR/rw_users.tmp" | grep -v "$a" | cat >"$am_WORKING_DIR/users2.tmp"
            mv "$am_WORKING_DIR/users2.tmp" "$am_WORKING_DIR/rw_users.tmp"        
        fi
    done

    cat "$am_WORKING_DIR/rw_users.tmp" | cat >>"$am_WORKING_DIR/newdb.tmp"
    #--------add new users----------------
    for user in `cat "$am_WORKING_DIR/users.tmp"`; do
        uID=`echo $user | cut -d ':' -f $USER_ID`
        newID=$uID
        existingID=$(id_exists "$newID")
        while [ -n "$existingID" ]; do
            echo "$existingID exists"
            newID=$(($RANDOM%500)) #users from the updates are assumed to be programs. assign an id <500
            
            if ((uID>=500)); then
                newID=$(($newID+500))
            fi
            existingID=$(id_exists $newID)
            #in extreme cases this will fail
        done
        if [ $newID -ne $uID ]; then
            echo $uID $newID | cat >>"$am_WORKING_DIR/map.tmp"
        fi 
        echo "$newID against $uID"
        userDef=`echo $user | cut -d ':' -f $USERNAME-2`
        userDef+=":$newID:"
        rest=`echo $user | cut -d ':' -f 4-$3`
        userDef+=$rest
       
        echo "$userDef"  | cat >>"$am_WORKING_DIR/newdb.tmp"
    done                
    rm "$am_WORKING_DIR/users.tmp"
    rm "$am_WORKING_DIR/rw_users.tmp"
}

MEMBERS=4
#gets two arguments, that are definitions
#of the same group with format as in
#/etc/group and merges their member list into one
#and returns a new definition
function merge_group_members {
    #unused
    list1=`echo $1 | cut -d ':' -f $MEMBERS | tr ',' $'\n'`
    list2=`echo $2 | cut -d ':' -f $MEMBERS | tr ',' $'\n'`
    final_list=""
    for member in $list1; do
        if [ -n "$final_list" ]; then
            final_list+=','
        fi
           
        final_list+=$member
        
        ifs_b=$IFS
        IFS=' '
        list2=`echo $list2 | grep -v "$member"`
        IFS=$ifs_b
    done
    for member in $list2; do
        if [ -n "$final_list" ]; then
            final_list+=','
        fi
        final_list+=$member
    done
    a=`echo $1 | cut -d ':' -f 1-3`
    a+=":$final_list"
    echo $a   
}

#checks for each user if group id has changed and changes
#it accordingly
update_user_groups() {
    touch "$1.tmp"
    for user in `cat $1`; do
        group_id=`echo $user | cut -d ':' -f $GROUP_ID`
        ifs_b=$IFS
        IFS=' '
        mapped=`cat "$am_WORKING_DIR/group_map.tmp" | grep -w -o -e "$group_id [0-9][0-9]*"`
        IFS=$ifs_b
        new_group_id=$group_id
        if [ -n "$mapped" ]; then
            new_group_id=`echo $mapped | cut -d ' ' -f 2`
        fi
        userDef1=`echo $user | cut -d ':' -f 1-3`
        userDef2=`echo $user | cut -d ':' -f 5-7`
        echo "$userDef1:$new_group_id:$userDef2" | cat >>"$1.tmp"
    done
    mv "$1.tmp" "$1"        
}

update_shadow() {
    for line in `cat $1`; do
        username=`echo $line | cut -d ':' -f $USERNAME`
        ifs_b=$IFS
        IFS=' '
        a=`cat "$2" | grep -w -e "$username:.*"`
        if [ -n "$a" ]; then
            echo "$a" | cat >>"$am_WORKING_DIR/newdb.tmp"
        else
            echo "$line" | cat >>"$am_WORKING_DIR/newdb.tmp"
        fi
        IFS=$ifs_b
    done
}

handle_update() {
    #create a temp directory to do the work
    export am_WORKING_DIR=$(mktemp -d)
    user_update $1 $2 7

    USER_ID=3
    mv "$am_WORKING_DIR/map.tmp" "$am_WORKING_DIR/user_map.tmp"
    mv "$am_WORKING_DIR/newdb.tmp" "$am_WORKING_DIR/users_newdb.tmp"        
    user_update $3 $4 4           
    mv "$am_WORKING_DIR/map.tmp" "$am_WORKING_DIR/group_map.tmp"
    mv "$am_WORKING_DIR/newdb.tmp" "$am_WORKING_DIR/group_newdb.tmp"

    update_user_groups "$am_WORKING_DIR/users_newdb.tmp"

    update_shadow $5 $6
    mv "$am_WORKING_DIR/newdb.tmp" "$am_WORKING_DIR/shadow_newdb.tmp"
}

run_user_merging() {
    CONFIG="$1"
    #read configuration file if any
    if [ ! -f "$CONFIG" ]; then
        echo "Configuration file is missing"
        exit 1
    fi
    . $CONFIG
    handle_update ${am_user_RO} ${am_user_RW} ${am_group_RO} ${am_group_RW} ${am_shadow_RO} ${am_shadow_RW}
    mv "$am_WORKING_DIR/users_newdb.tmp" "${am_passwd}"
    mv "$am_WORKING_DIR/user_map.tmp" "${am_user_map}"
    mv "$am_WORKING_DIR/group_map.tmp" "${am_group_map}"
    mv "$am_WORKING_DIR/shadow_newdb.tmp" "${am_shadow}"
    mv "$am_WORKING_DIR/group_newdb.tmp" "${am_group}"                                       
}

run_user_merging $1
IFS=$ifs_bck
