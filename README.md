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

### Files Generated

| File                                       | Description                                           |
| ------------------------------------------ | ----------------------------------------------------- |
| `topsender_hour.txt`                       | Users sending >200 emails in last 30 mins             |
| `topsender_6hour.txt`                      | Users sending >800 emails in last 5 hours             |
| `top_mailnull`                             | Recipients via `mailnull` user exceeding 30/200 mails |
| `defer.txt`                                | Domains triggering defers/failures per hour           |
| `hourly_lmit.txt`                          | Users exceeding cPanel hourly mail limit              |
| `emailreport.txt`, `emailreport1.txt`      | Custom email reports (reserved)                       |
| `spamassasin.txt`, `top_sender_reject.txt` | Placeholder for future integration                    |

---

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
