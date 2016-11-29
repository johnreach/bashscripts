#!/bin/bash

firstName=""
lastName=""
phoneNumber=""
email=""
mode=""
noclobber=false
dest="contacts.txt"

function save_new_contact {
	
	# $lastName:$firstName:$email:$phoneNumber:
	echo -e "$lastName:$firstName:$email:$phoneNumber:" >> $dest
}

# process options
while true
do
    # Handle mode/first option
    case $1 in
		-h|-\?|--help|help) # help option
			printf "usage: $0 [mode] [options] \n" 
			printf '  mode - \n' 
			printf '    read    - interactive mode to add a new contact. Last name can not be blank. \n' 
			printf '    add     - non interactive mode to add new contact. Last name can not be blank. \n' 
			printf '    query   - search \n' 
			printf '    delete  - delete mode \n' 
			printf '    repalce - \n' 
			printf '  options - \n' 
			printf '    -firstname [ First name ] \n' 
			printf '    -lastname* [ Last name ] \n' 
			printf '    -phone     [ Phone number ] \n' 
			printf '    -email     [ Email address ] \n'
			
			exit 0
		;;
    	read|-r) # Read mode - interactive
			mode="add_interactive"

		;;
		add|-a) # Add mode - non interactive
			mode="add"
			
		;;
		query|search) # Query mode - search the database
			mode="query"
			
		;;
		-firstname|-first) # Get first name
			if [ -n $2 ]
			then
			
				firstName=$2
				shift 2
				continue
			else
				printf "ERROR: '%s' not set\n" "$1" >&2
				exit 1
			fi
		
		;;
		-lastname|-last) # Get last name
			if [ -n "$2" ]
			then
				lastName=$2
				shift 2
				continue
			else
				printf "ERROR: '%s' not set\n" "$1" >&2
				exit 1
			fi

		;;
		-phonenumber|-phone) # Get phone number
			if [ -n "$2" ]
			then
				phoneNumber=$2
				shift 2
				continue
			else
				printf "ERROR: '%s' not set\n" "$1" >&2
				exit 1
			fi

		;;
		-email) # Get email
			if [ -n "$2" ] && [ "$2" != '-*' ]
			then
				email=$2
				shift 2
				continue
			else
				printf "ERROR: '%s' not set\n" "$1" >&2
				exit 1
			fi

		;;
		-name) # Get first and last name together
			if [ -n "$2" ] && [ -n "$3" ]
			then
				firstName=$2
				lastName=$3
				shift 3
				continue
			else
				printf "ERROR: '%s' not set correctly\n" "$1" >&2
				exit 1
			fi

		;;
		-noclobber) # Don't add a duplicate
			noclobber=true

		;;
		-?*) # Unknown option
			printf "WARNING: Unkown option '%s': ignored\n" "$1" >&2
			
		;;
		*) # No more options
			break

	esac
	shift
done



# Validate options
case $mode in
	add_interactive)
	
		####################
		# Interactive Mode #
		####################
	
		printf 'Please enter the following \n' 
	
		printf 'Contact First Name: ' 
		read firstName
	
		while true # if last name is blank, loop until user enters something
		do
			printf 'Contact Last Name: ' 
			read lastName
			
			if [ -z $lastName ]
			then
				printf "ERROR: Last name can not be empty\n" >&2
			else
				break
			fi
		done # End last name loop
	
		printf 'Email Address:' 
		read email
	
		printf 'Phone Number: ' 
		read phoneNumber
		
		# Save contact to database
		save_new_contact
	;;
	add)
		####################
		##### Add Mode #####
		####################

		# Check whether to add duplicate
		if [ $noclobber == true ]
		then
		
			echo "no clobber"
		else
		
			# Save contact to database
			if [ -z $lastName ]
			then
				printf "ERROR: Last name can not be empty\n" >&2
			else
				save_new_contact
			fi
		fi
		
	;;
	query)
		# Set awk variables with -v
		awk -v first="$firstName" -v last="$lastName" -v phone="$phoneNumber" -v email="$email" -F ":" '
		  ((first == "" || $2 == first) && 
		  (last == "" || $1 == last)    && 
		  (email == "" || $3 == email)  &&
		  (phone =="" || $4 == $phone) ) { 
		  	
		  	printf "%-6s %-6s %-12s %s\n",$2,$1,$4,$3 
		  	
		  }' "$dest"
	;;
esac

#echo -e "$lastName:$firstName:$email:$phoneNumber:\n" #>> $dest