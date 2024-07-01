#!/bin/bash

# Log and password file locations
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.txt"
USER_FILE="$1"

# Ensure a user file is provided
if [[ -z "$USER_FILE" ]]; then
    echo "Usage: $0 <name-of-text-file>"
    exit 1
fi

# Setup log and password files
mkdir -p /var/secure
: > "$LOG_FILE"
: > "$PASSWORD_FILE"
chmod 600 "$PASSWORD_FILE"

# Ensure the user file ends with a newline
sed -i -e '$a\' "$USER_FILE"

# Function to trim whitespace
trim() {
    echo "$1" | xargs
}

# Process each line in the user file
while IFS=';' read -r username groups; do
    username=$(trim "$username")
    groups=$(trim "$groups")

    # Skip empty usernames
    if [[ -z "$username" ]]; then
        continue
    fi

    # Check if user already exists
    if id "$username" &>/dev/null; then
        echo "User $username already exists." | tee -a "$LOG_FILE"
    else
        # Create user with specified groups
        useradd -m -s /bin/bash -G "$groups" "$username" &>> "$LOG_FILE"
        if [[ $? -eq 0 ]]; then
            echo "User $username created." | tee -a "$LOG_FILE"
        
            # Generate and set password
            password=$(openssl rand -base64 12)
            echo "$username:$password" | chpasswd &>> "$LOG_FILE"
            if [[ $? -eq 0 ]]; then
                echo "$username,$password" >> "$PASSWORD_FILE"
                echo "Password set for user $username." | tee -a "$LOG_FILE"
            else
                echo "Failed to set password for user $username." | tee -a "$LOG_FILE"
            fi

            # Set home directory permissions
            chown "$username:$username" "/home/$username"
            chmod 700 "/home/$username"
            echo "User $username added to groups: $groups" | tee -a "$LOG_FILE"
        else
            echo "Failed to create user $username." | tee -a "$LOG_FILE"
        fi
    fi
done < "$USER_FILE"

echo "User creation process completed." | tee -a "$LOG_FILE"
