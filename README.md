# ipynb_newcommand_expander
Github is great in that it can display ipynb files.
However, the \newcommand macro of tex seems to be not working. 

This program offers a solution; convert an .ipynb file to another .ipynb file in which \newcommand macros in the original file are expanded so that github can display the mathematical expressions properly.

Usage: ruby ipynb_nc_exp.rb path_to_input_file path_to_output_file
