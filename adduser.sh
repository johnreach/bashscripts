#!/bin/bash

# adduser.sh
# Author: John Reach
# Student id: 50034193
# mysql> GRANT ALL ON lambda.* TO Yoga@'24.144.9.42' IDENTIFIED BY 'pass';
# Check for root access
if [ $EUID -ne 0 ]
then
	printf "ERROR: Must be administrator to add user.\n" >&2
	exit 1
fi

# Defaults
skeleton="/etc/skel"
home="/home"
user_shell="/bin/bash"

next_uid=-1
duplicate_username=false

# Array to contain warning and error messages
# This method allows all errors and warnings 
# be found and not just the first one.
# If there are any warnings, print them and continue.
# If there are any errors, print them and exit.
errors=()
warnings=()

###################
### Get Options ###
###################

while true
do
	case "$1" in
		--help | -h)
			# Display proper usage
			printf "Usage: adduser [ options ] [ username ] \n"
			printf "Options:\n"
			printf "\t--skeleton [ DIR ]\n"
			printf "\tThe skeleton directory to be copied for the new user\n"
			printf "\t--home\n [ DIR ]\n"
			printf "\tThis will be the new users home directory\n"
			exit 0
		;;
		--skeleton)
			# Check if skeleton directory is valid
			if [ ! -d "$2" ]
			then
				# Directory does not exist, add to error list
				errors+=("ERROR $1: $2 is not a valid directory")
				# Don't exit. Continue to check for more errors
			else
				# Set the skeleton directory to the user supplied directory
				skeleton="$2"
			fi
			
			shift 2
			continue
		;;
		--home)
			
			# Check if home directory is valid
			if [ ! -d "$2" ]
			then
				# Directory does not exist, add to error list
				errors+=("ERROR $1: $2 is not a valid directory")
			else
				home="$2"
			fi
			
			shift 2
			continue
		;;
		-?*) 
			# Unknown option
			warnings+=("WARNING: Unkown option $1 ignored")
			# Don't exit. Continue to check for more errors
			shift 1
			continue
		;;
		*) # No more options
			break
		
	esac
	shift
done

### TODO - Check if username already exist

new_username=$1

###################
### Next UID/GID ##
###################


# Store user ids and usernames in the format uid:username
# Sorted by uid
uids=( $( awk -F: '($3 >= 1000) {printf "%s:%s\n",$3,$1 }' /etc/passwd | sort -n ) )

# Split the uid and username into a temp array
# Format: temp[0] = uid temp[1] = username
temp=()
next=()


for i in "${!uids[@]}"
do
	temp=( $(echo ${uids[i]} | tr ':' "\n") )
	next=( $(echo ${uids[i+1]} | tr ':' "\n") )
	
	# next_uid is initialized to -1 to indicate that the next uid has not been found
	if [ $next_uid -lt 0 ] && [ $(( ${temp[0]}+1 )) -lt ${next[0]} ]
	then
		next_uid=$(( ${temp[0]}+1 ))
	fi
	
	# Check for duplicate username
	if [ "${temp[1]}" == "$new_username" ]
	then
		duplicate_username=true
		errors+=("ERROR: Username $new_username already exist.")
		
		# No need to go any further
		break
	fi
	
	#echo "${temp[0]} - ${temp[1]} Next: ${next[0]} - ${next[1]}" # testing
	
done

###################
# Errors/Warnings #
###################

# Print warnings and continue
if [ ${#warnings[@]} -ne 0 ]
then
	for i in "${!warnings[@]}"
	do
		printf "${warnings[i]}\n" >&2
	done
fi

# Print errors and exit
if [ ${#errors[@]} -ne 0 ]
then
	for i in "${!errors[@]}"
	do
		printf "${errors[i]}\n" >&2
	done
	
	printf "Exiting...\n" >&2
	exit 1
fi

###################
## Update Files ###
###################

# Update /etc/passwd and /etc/group
echo "$new_username:x:$next_uid:$next_uid:added by adduser.sh:$home/$new_username:$user_shell" >> /etc/passwd
echo "$new_username:x:$next_uid:" >> /etc/group

# Make the users new home directory with correct permissions
mkdir "$home/$new_username"
cp -r "$skeleton/." "$home/$new_username"
chown -R "$new_username:$new_username" "$home/$new_username"
chmod -R go=u,go-w "$home/$new_username"
chmod go= "$home/$new_username"

###################
## Get Password ###
###################

passwd "$new_username" 
