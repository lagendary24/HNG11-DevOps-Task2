#!/bin/bash

# Define log and password file paths
LOG_PATH="/var/log/user_management.log"
PASSWD_PATH="/var/secure/user_passwords.txt"
USER_INPUT="$1"

# Verify if the user file is provided
if [ -z "$USER_INPUT" ]; then
    echo "Usage: $0 <user-data-file>"
    exit 1
fi

# Create necessary directories and files with appropriate permissions
sudo mkdir -p /var/secure
sudo touch "$LOG_PATH"
sudo touch "$PASSWD_PATH"
sudo chmod 600 "$PASSWD_PATH"

# Function to log messages with timestamp
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a "$LOG_PATH"
}

# Ensure the input file ends with a newline
echo "" >> "$USER_INPUT"

while IFS=';' read -r user_name group_list; do
    # Trim whitespace
    user_name=$(echo "$user_name" | xargs)
    group_list=$(echo "$group_list" | xargs)

    # Skip empty lines and invalid usernames
    if [ -z "$user_name" ]; then
        continue
    fi

    # Create a personal group for the user if it doesn't exist
    if ! getent group "$user_name" &>/dev/null; then
        sudo groupadd "$user_name"
        if [ $? -eq 0 ]; then
            log_message "Personal group $user_name created."
        else
            log_message "Failed to create personal group $user_name."
            continue
        fi
    fi

    # Create user with personal group
    if id "$user_name" &>/dev/null; then
        log_message "User $user_name already exists."
    else
        sudo useradd -m -s /bin/bash -g "$user_name" "$user_name"
        if [ $? -eq 0 ]; then
            log_message "User $user_name created."
        
            # Generate a random password
            passwd=$(openssl rand -base64 12)
            echo "$user_name:$passwd" | sudo chpasswd
            if [ $? -eq 0 ]; then
                echo "$user_name,$passwd" | sudo tee -a "$PASSWD_PATH"
                log_message "Password set for user $user_name."
            else
                log_message "Failed to set password for user $user_name."
            fi

            # Set home directory permissions
            sudo chown "$user_name:$user_name" "/home/$user_name"
            sudo chmod 700 "/home/$user_name"
        else
            log_message "Failed to create user $user_name."
            continue
        fi
    fi

    # Add user to specified groups
    IFS=',' read -r -a groups_array <<< "$group_list"
    for group in "${groups_array[@]}"; do
        group=$(echo "$group" | xargs)
        if ! getent group "$group" &>/dev/null; then
            sudo groupadd "$group"
            if [ $? -eq 0 ]; then
                log_message "Group $group created."
            else
                log_message "Failed to create group $group."
                continue
            fi
        fi
        sudo usermod -aG "$group" "$user_name"
        if [ $? -eq 0 ]; then
            log_message "User $user_name added to group $group."
        else
            log_message "Failed to add user $user_name to group $group."
        fi
    done

done < "$USER_INPUT"

log_message "User creation process completed."
