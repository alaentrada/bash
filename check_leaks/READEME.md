When you are checking leaks in your program with Valgrind, it's pretty awkward looking for your own leaks among all the still reachable leaks from other libraries (like readline function's). This Bash script is designed to analyze a C program for memory leaks using Valgrind and extract function names from a specified header file. It checks for memory leaks in the compiled program and lists the functions from the header file that are associated with any detected leaks.

Usage:

-First of all make sure you have permission to execute the script with "chmod +x check_valgrind.sh"

-Then, execute the script "./check_valgrind.sh "name_of_program" [OPTIONAL:name_of_header.ext]"
If name of header is not specified, it will be assumed as "name_of_program.h".

-The script will launch the program and store the standard error output in "val" file. Then it will extract the functions' names from the header and look for them inside "val" file, storing the leaks associated to those functions inside "myLeaks.log" file.
