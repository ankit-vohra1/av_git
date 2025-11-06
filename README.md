# av-git

**PYTHON SKILLS**

1) multiprocessing_demo.py 
This has sample code for implementing multiprocessing functionality using Python; utilizing all cores of operating system for running multiple jobs together.
In practice, I have:

  1) Implemented Python multiprocessing for running multiple adhoc-reports in parallel. Thereby completing job of generating 10 reports in under 2 mins rather earlier 12-15 mins.
  2) Implemented Python multiprocessing with Pipe functionality (to share information among processes and return counts) for multi-file loading in Lambda.


2) thesarus.py
This program uses data.json as source, parses it and then searches it to find required word, thus implemnting offline dictionary like functionality.


3) utils
This has 2 files: UtilsSmartsheet.py and utils.py.
These 2 demonstrates Object-oriented programming skills and code reusability skills.
UtilsSmartsheet.py has several methods which are used for initilizing a Smartsheet, adding Or deleting rows from a Smartsheet and also implements Retry logic functionality.
We create an instance/object of UtilsSmartsheet in actual program and then call various methods of UtilsSmartsheet class via same instance.

utils.py has various functions which can be called from diffrent Python programs thereby providing code reusability.

**SQL SKILLS**

1) fn_data_checks_details.sql
   PostgreSQL function to return results in TABLE format.
   Here we use dynamic queries with RETURN NEXT record feature.
   We do proper EXCEPTION handling and error logging for troubleshooting any issues.  

2) league - Postgres (SQL Skills)
This is an entire project for implementing a Basketball league functionality.
Details of requirements and expected functionality of this application is in attached document "Application Information Document - MODEL.docx"
We generate team, player etc data on the fly. 

Thanks
