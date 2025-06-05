Here’s a well-structured `README.md` file for your Bash script, suitable for publishing on GitHub:

---

# 📧 Email Account Auto-Suspension Script for Spamming Detection (Exim + cPanel)

This Bash script helps system administrators detect and suspend email accounts on a **cPanel server using Exim** that are potentially sending spam. It uses **bounce-back messages and log analysis** to identify accounts exceeding defined thresholds and integrates with a **custom Exim system filter** to block outgoing mail from those users.

---

## 🔧 Features

* Parses `/var/log/exim_mainlog` for:

  * SMTP authentication activity
  * `mailnull` system user usage
  * Bounce/defer logs
  * Hourly/daily sending limits
* Identifies suspicious senders based on thresholds.
* Works with a **custom Exim system filter** to suspend outgoing mail access.
* Outputs reports for analysis and review.

---

## 📁 Script Overview

This script is designed to automatically suspend email accounts that are detected as sending spam or exceeding email sending limits on a cPanel server. Here's a breakdown of its functionality:

## Main Purpose
The script monitors Exim mail logs for signs of spam activity and automatically takes action against offending accounts by:
- Suspending outgoing mail capabilities
- Creating suspension logs
- Managing forwarders for suspended accounts
- Maintaining whitelists and caches

## Key Components

### 1. Initial Setup
- Creates necessary directories and files if they don't exist (`/var/log/spamsuspend`, `/pickascript/spam_whitelist`, etc.)
- Sets up date and hostname variables

### 2. Helper Functions

#### `contactemail()`
- Retrieves the contact email address for a given account by checking cPanel user files
- Handles both root-owned and non-root-owned accounts

#### `toaddfilter()`
- Main function that processes accounts to be suspended
- Handles different suspension reasons with corresponding messages
- Manages forwarders for suspended accounts
- Updates various cache and log files

#### `suspendinfo()`
- Gathers suspension information from Exim logs
- Creates suspension details in user directories
- Cleans up mail queue for suspended accounts

### 3. Log Analysis
The script analyzes Exim mail logs for various spam indicators:
- Outgoing mail suspensions
- Rejected messages after DATA
- Non-SMTP ACL rejections
- Exceeded email limits
- Spam bounces from major providers (Yahoo, Google)
- Various spam content indicators

### 4. Processing Flow
1. Parses recent Exim logs for spam indicators
2. Filters out whitelisted accounts and recently processed accounts
3. For each offending account:
   - Determines the account owner
   - Suspends the account if criteria are met
   - Logs the suspension
   - Cleans up mail queue
   - Optionally modifies forwarders
4. Maintains cache files to prevent duplicate processing

## Suspension Reasons
The script handles multiple types of spam indicators with corresponding reason codes:
- `a`: Has an outgoing mail suspension
- `c`: SpamAssassin found high spam score
- `e`: Reached maximum deferred limit
- `f`: Domain reached email hourly limit
- `g`: Message looks like spam (Google detection)
- `h`: Content presents security issue
- `i`: Yahoo policy rejection
- `j`: General spam content
- `k`: User complaints (Yahoo deferral)

## Technical Details
- Uses Exim log parsing with `grep`, `awk`, and other text processing tools
- Interfaces with cPanel through `/scripts/whoowns` and `cpapi2`
- Maintains state through various cache files in `/pickascript/`
- Logs all actions to `/var/log/spamsuspend/sa_suspended.log`

## Safety Mechanisms
- Whitelist support (`/pickascript/spam_whitelist`)
- Hourly cache to prevent duplicate suspensions
- Special handling for cPanel system emails
- Root account protection

--

## 🛠️ How It Works

### 1. **Run the Script**

```bash
bash exim-monitor.sh
```

### 2. **Review Output**

Review the output files (`topsender_hour.txt`, etc.) for accounts that may be sending spam.

### 3. **Suspend Offending Users**

Append suspicious usernames (e.g., `U=username`) to:

```
/etc/outgoing_mail_suspended_users_filter
```

This file is used by Exim’s custom system filter.

### 4. **Exim Filter Rule**

Your server must have the following filter configured in `/etc/cpanel_exim_system_filter`:

```exim
if ("${lookup {$sender_address} partial-lsearch*@{/etc/outgoing_mail_suspended_users_filter}{1}}" is 1)
then
  seen finish
endif
```

This ensures outgoing emails are blocked for users listed in the `outgoing_mail_suspended_users_filter` file.

---

## 🔒 Security Notes

* Only root or privileged users should execute this script.
* Log file parsing is sensitive to format changes; ensure compatibility with your Exim version.
* Script should be integrated with a review/alert system before auto-suspension is enabled in production.

---

## 📅 Recommended Cron Setup

You can schedule the script to run every 30 minutes:

```bash
*/30 * * * * /path/to/exim-monitor.sh
```

---

Let me know if you’d like help converting this into a Markdown file or setting up GitHub Actions to automate it.
