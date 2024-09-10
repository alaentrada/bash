#!/bin/bash

# Function to show the progress
showProgress() {
    local current=$1
    local total=$2
    local progress=$((current * 100 / total))
    local bar_length=50  # Length of the progress bar
    local filled_length=$((progress * bar_length / 100))
    local bar=$(printf "%-${bar_length}s" "#" | tr ' ' '#')
    printf "\r[%-${bar_length}s]" "${bar:0:filled_length}"| tr ' ' '.' && printf " %d%%" "$progress"
}

# Check if no arguments are provided
if [ "$#" -eq 0 ]; then
    exit
elif [ "$#" -eq 1 ] && [ "$1" == 'clean' ]; then
    # Clean up specified files
    rm -f val myLeaks.log funcs val
    exit
fi

if [ "$#" -gt 0 ] && [ "$1" == "--help" ]; then
    less usage.info
    exit
fi

# Set the header file based on input arguments
a="$1.h"
if [ "$#" -eq 2 ]; then
    a="$2"
fi

runValgrind() {
# Run Valgrind to check for memory leaks and direct output to 'val'
    valgrind -s --leak-check=full --show-leak-kinds=all ./$1 2>val
    # Extract function names from the header file and store in 'funcs'
    grep ");" "$a" | awk '{print $2}' | tr '*' ' ' | tr '(' ' ' | awk '{print $1}' > funcs
}

writeBlock () {
    cat blocks.tmp >> myLeaks.log
    echo "" >> myLeaks.log
    echo "" >> myLeaks.log
}

runValgrind "$1"
# Process the Valgrind output
# Set the control variables at initial values
patata=false
currentLines=0
totalLines=$(wc -l < val)
# Read the Valgrind output from 'val' file
echo "Checking Valgrind output:"
while read p; do
    # Update progress
    currentLine=$((currentLine + 1))
    showProgress "$currentLine" "$totalLines"
    # If control variable's value is 'false' it means "keep on looking for memory leaks or memory access issues"
    if [ "$patata" == "false" ]; then
        echo "$p" | grep "Invalid read of size" > blocks.tmp
        if [ ! -s blocks.tmp ]; then
            echo "$p" | grep "Syscall param" > blocks.tmp
        fi
        if [ ! -s blocks.tmp ]; then
            echo "$p" | grep "LEAK SUMMARY:" > blocks.tmp
        fi
        if [ ! -s blocks.tmp ]; then
            echo "$p" | grep "ERROR SUMMARY" > blocks.tmp
        fi
        if [ ! -s blocks.tmp ]; then
            echo "$p" | grep "errors in context" > blocks.tmp
        fi
        if [ ! -s blocks.tmp ]; then
            echo "$p" | grep "Invalid free" > blocks.tmp
        fi
        if [ ! -s blocks.tmp ]; then
            echo "$p" | grep "are still reachable in loss" > blocks.tmp
        fi
        if [ ! -s blocks.tmp ]; then
            # If no problem is found in this line jump to next line
            continue
        else
            # If found any issue, save the line in 'oldp' variable for not loosing it after reading next line
            oldp=$p
            patata="true"
            continue
        fi
    else
        # If control variable's value is 'true' check if current line is not the end of the parragraph asociated to the current issue
        echo "$p" | awk '{print $3}' > word.tmp
        <word.tmp read word
        # If it is not, add it to the 'blocks.tmp' file and keep on reading Valgrind output
        if [ "$word" != "" ]; then
            echo "$p" >> blocks.tmp
        else
            # If found the end of the parragraph set control variable's value to false again
            patata="false"
            # Check if there is any of our own functions asociated to the current issue
            while read f; do
                grep -a "ERROR SUMMARY" blocks.tmp > /dev/null
                if [ "$?" -eq 0 ]; then
                    writeBlock
                    break
                fi
                grep -a "LEAK SUMMARY" blocks.tmp > /dev/null
                if [ "$?" -eq 0 ]; then
                    writeBlock
                    break
                fi
                grep -a " $f " blocks.tmp > /dev/null
                if [ "$?" -eq 0 ]; then
                    # If there is any, print the line 'oldp' that defines the issue if its not the first one found
                    #echo $oldp | grep "== " >>/dev/null
                    #if [ $? -eq 0 ]; then
                    #    echo "$oldp" >> myLeaks.log
                    #fi
                    # Add the block to the file associated to our issues, adding two extra newlines
                    writeBlock
                    break 
                fi
            done < funcs;
        fi
    fi
done < val;

if [ ! -f "./myLeaks.log" ]; then
    echo ""
    echo "No leaks nor memory access issues found"
fi

# Clean up temporary files
rm -f blocks.tmp val.tmp word.tmp