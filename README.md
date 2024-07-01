# Advanced User Management Script

Welcome to the Advanced User Management Script! This script automates the process of creating users, assigning them to groups, generating random passwords, and logging all actions. It's an essential tool for SysOps engineers who need to manage user accounts efficiently.

## Features

* Reads user data from a specified text file.
* Creates users with home directories and assigns them to groups.
* Generates random passwords and sets them for the users.
* Logs all actions to /var/log/user_management.log.
* Stores generated passwords securely in /var secure/user_passwords.txt.
* Handles existing users and updates their groups if necessary.
## Requirements
* Bash
* OpenSSL
* User must have root or sudo privileges to run the script.
## Usage
1. ### Prepare the user data file:
 Create a text file (e.g., users.txt) with the following format:
```
 username;group1,group2,group3
```
#### Example:
```
light;sudo,dev,www-data
idimma;sudo
mayowa;dev,www-data
```
3. #### Run the script:
```
sudo ./create_users.sh users.txt
```
3. #### Verify the results:
Check the log file for details of the actions performed:
```
cat /var/log/user_management.log
```
View the generated passwords (only accessible by root or sudo user):

```
sudo cat /var/secure/user_passwords.txt
```
### Files
+ **create_users.sh:** The main script file.
+ **README.md:** This file.
### License
This project is licensed under the MIT License.

Author

***AMAZING CHIMEZIE***