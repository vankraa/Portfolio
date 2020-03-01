#!/bin/bash
cd ..

if [ $# -eq 0 ]; then	#Letting the user provide input from the command line or choose after the program has started
	while :
	do
		echo "To compile an error log for python and haskell files, please enter 'errors'"
		echo "To find the last working version of a python or haskell file, please enter 'lwv'"
		echo "For file initiation with shebang and/or author information, please enter 'fi'"
		read f
		if [ $f = 'errors' ] || [ $f = 'lwv' ] || [ $f = 'fi' ]; then
			break
		elif [ $f = 'exit' ]; then exit
		else
			echo -e "Invalid input."
		fi
	done
else
	f=$1
fi

if [ $f = 'errors' ]; then	#Error Compiler
echo "To begin a new error log for Python and Haskell files, type 'n'"
echo "To read the contents of the current error log, type 'r'"
echo "To see these instructions again enter 'help'"
echo "Otherwise, type 'exit' to exit."
echo ""

	while :
	do
		read cmd

		if [[ $cmd =~ [Hh][Ee][Ll][Pp] ]]; then
			echo ""
			echo "To begin a new error log for Python and Haskell files, type 'n'"
			echo "To read the contents of the current error log, type 'r'"
			echo "To see these instructions again enter 'help'"
			echo "Otherwise, type 'exit' to exit."
			echo ""

		elif [[ $cmd =~ [Rr] ]]; then	#Display the current error log
			echo ""
			if [ -e "./Project01/compile_fail.log" ]; then
				cat ./Project01/compile_fail.log
				echo -e "\nPlease enter another command:"
			else
				echo -e "Error log does not exist\nPlease enter another command:"
			fi

		elif [[ $cmd =~ [Nn] ]]; then	#Creating the new error log
			echo ""
			if [ -e "./Project01/compile_fail.log" ]; then	#Removing the old error log
				rm ./Project01/compile_fail.log
			fi
			echo -e "CS1XA3 Repository Error Log\n" >> ./Project01/compile_fail.log	#initializing error log with a title

			find . -name "*.hs" -type f -print0 | while IFS= read -d $'\0' file	#Finding and compiling all haskell files found
			do
				echo -e "\n$file"
				if !( ghc -fno-code $file ); then	#If the file does not compile, the title of the file is appended to the error log
					echo "$file" >> ./Project01/compile_fail.log
				fi
			done

			find . -name "*.py" -type f -print0 | while IFS= read -d $'\0' file	#Finding and compiling all python files found
			do
				echo -e "\n$file"
				if !( python -B $file ); then
					echo "$file" >> ./Project01/compile_fail.log
				fi
			done

			echo -e "\nPlease enter another command:"

		elif [[ $cmd =~ [Ee][Xx][Ii][Tt] ]]; then
			break

		else
			echo -e "\nInvalid input. Please enter 'n', 'r', 'help' or 'exit'."
		fi
	done

elif [ $f = 'lwv' ]; then	#Last working file version feature
	while read -p "Please enter the branch you would like to restore to or enter 's' to stay on the current branch: " brn; do

		if git rev-parse --verify -q $brn; then	#Checking if the user specified branch exists
			git checkout $brn
			break
		elif [[ $brn =~ [Ss] ]]; then
			break
		else
			read -p "Branch does not exist. Create a new branch $brn\? (y/n)" cnb	#If the branch does not exist, the option to create a new one is presented
			if [[ $cnb =~ [Yy] ]]; then
				git checkout -b $brn
				break
			fi
		fi
	done
	while read -p "Please enter the file you would like to restore or enter 'exit' to exit:" file; do
		declare -a init	#Initial commit
		declare -a cmit	#Commit array to be parsed by the program
		declare wv=0	#Working version variable
		init+=($(git log --oneline --reverse --diff-filter="A" -- *$file | cut -d' ' -f1))	#Finding and recording the commit where the file was added
		cmit_array+=($(git rev-list ${init[0]}..HEAD | cut -d' ' -f1))	#Creating an array of all the commits from when the file was first added
		cmit_array+=(${init[0]})

		if [[ $file =~ [Qq][Uu][Ii][Tt] ]]; then
			exit

		elif ! [[ ( $file == *.hs ) || ( $file == *.py ) ]]; then	#Proper input checks
			echo "Incorrect file format."

		elif [[ ${init[0]} == '' ]]; then	#If no file found the program asks the user to enter another file
			echo -e "File not found on any commit"

		elif [[ $file == *.py ]]; then
			path=$(find . -name *$file -type f)
			if [[ $path != '' ]] && python -B $path; then
				echo -e "\nCurrent version is working\n"	#This and the next elif block check the current version of python
				wv=1						#and haskell files to see if they are already working. If so, the
			fi							#working version variable is set to 1 for working.

		elif [[ $file == *.hs ]]; then
			path=$(find . -name *$file -type f)
			if [[ $path != '' ]] && ghc -fno-code $path; then
				echo -e "\nCurrent version is working\n"
				wv=1
			fi

		fi
		if [ $wv -eq 0 ]; then	#If the current file is determined to not be working, then older commits are checked.
			echo -e "\nAttempting to find last working version...\n"
			git stash	#Stashing any unsaved changed to avoid conflicts within the program
			i=0	#counter used to match the length of the array of past commits
			if [[ $file == *.py ]]; then
				for commit in ${cmit_array[@]}; do	#Iterating over all past commits
					((i++))
					git checkout -b tmpbranch $commit
					path=$(find . -name *$file -type f)
					if [[ $path != '' ]] && python3 -B $path; then	#If the file exists on the commit and compiles, it is checked out to a branch
						git checkout $brn			#running on the current commit to restore the file and the temp branch is deleted.
						git checkout tmpbranch $path
						git add $path
						echo ""
						git commit -m"Restoring $file from commit $hash"
						echo ""
						git branch -D tmpbranch
						break
					else					#If no file is found then the script returns to the current branch
						git checkout $brn
						git branch -D tmpbranch
					fi
					if [[ $i == ${#cmit_array[@]} ]]; then	#If The end of the commit array is rached the user is informed
						echo -e "\nNo working file found. Retaining most recent version"
					fi
				done

			elif [[ $file == *.hs ]]; then	#Haskell version of the code is identical to the python version above
				for commit in ${cmit_array[@]}; do
					((i++))
					git checkout -b tmpbranch $commit
					path=$(find . -name *$file -type f)
					if [[ $path != '' ]] && ghc -fno-code $path; then
						git checkout $brn
						git checkout tmpbranch $path
						git add $path
						echo ""
						git commit -m"Restoring $file from commit $hash"
						echo ""
						git branch -D tmpbranch
						break
					else
						git checkout $brn
						git branch -D tmpbranch
					fi
					if [[ $i == ${#cmit_array[@]} ]]; then
						echo -e "\nNo working file found. Retaining most recent version"
					fi
				done
			fi
			git stash pop	#Undo the stash
		fi
	done

elif [ $f = 'fi' ]; then

	DATE=`date '+%Y-%m-%d %H:%M:%S UTC'`
	year=`date '+%Y'`
	while read -p "Please enter the directory within CS1XA3 you would like to add the files to: " dir;
	do
		if [ ! -d $dir ] && (mkdir $dir); then	#If the directory does not exist, creating a new one
			cd $dir
			break
		elif [ -d $dir ]; then
			read -p "Append to $dir\? (y/n)" ap
			if [ $ap = 'y' ] || [ $ap = 'Y' ]; then
				cd $dir
				break
			fi
		else
			echo "Invalid directory"
		fi
	done
	read -p "Please enter your name: " name				#Gathering the information of the user to be used for file initializing.
	read -p "Please enter your organization or type none: " co
	if [ "${co[0]}" = [Nn][Oo][Nn][Ee] ]; then
		org="Copyright: $year, $name"
	else
		org="Copyright: $year, $co"
	fi
	while echo "Enter filenames separated by a space or 'exit' to exit":
	do
		read -a files
		if [ ${files[0]} = 'exit' ]; then
			break
		fi
		for file in "${files[@]}"; do	#Checking the filetype and creating the file if it does not already exist
			if [ -f $file ]; then
				echo "$file already exists!"
			elif [[ $file == *.py ]]; then
				echo "Created $file"
				echo -e "#!/usr/bin/env python3\n\n\"\"\" Description:\nAuthor: $name\n$org\nLast revised: $DATE\n\"\"\"" >> "$file"
			elif [[ $file == *.hs ]]; then
				echo "Created $file"
				echo -e "#!/usr/bin/haskell\n\n{-\nDescription:\nAuthor: $name\n$org\nLast revised: $DATE\n-}" >> "$file"
			elif [[ $file == *.elm ]]; then
				echo "Created $file"
				echo -e "{-\nDescription:\nAuthor: $name\n$org\nLast revised: $DATE\n-}" >> "$file"
			elif [[ $file == *.sh ]]; then
				echo "Created $file"
				echo -e "#!/usr/bin/bash\n\n# Description:\n# Author: $name\n# $org\n# Last revised: $DATE\n" >> "$file"
			elif [[ $file == *.html ]]; then
				echo "Created $file"
				echo -e "<!DOCTYPE html>" >> "$file"
				echo -e "<head>" >> "$file"
				echo -e "\t<meta charset=\"UTF-8\">" >> "$file"
				echo -e "\t<meta name=\"description\" content=\"\">" >> "$file"
				echo -e "\t<meta name=\"keywords\" content=\"\">" >> "$file"
				echo -e "\t<meta name=\"author\" content=\"$name\">" >> "$file"
				echo -e "\t<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">" >> "$file"
				echo -e "\t<link rel=\"stylesheet\" href=\"\">" >> "$file"
				echo -e "</head>" >> "$file"
				echo -e "<body>" >> "$file"
				echo -e "</body>" >> "$file"
			elif [[ $file == *.js ]]; then
				echo "Created $file"
				echo -e "#!/usr/bin/env node\n\n/* Description:\n   Author: $name\n   $org\n   Last Revised: $DATE\n*/" >> "$file"
			elif [[ $file == *.css ]]; then
				echo "Created $file"
				echo -e "/* Description:\n   Author: $name\n   $org\n   Last Revised: $DATE\n*/" >> "$file"
			else
				echo -e "Warnning: Author information will not be commented out.\nCreated $file"
				echo -e "Description:\nAuthor: $name\n$org\nLast Revised: $DATE" >> "$file"
			fi
		done
	done
else
	echo "Exiting"
fi
