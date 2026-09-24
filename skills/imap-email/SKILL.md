---
name: imap-email
description: "Read email from any provider via IMAP. Supports Gmail, Outlook, Yahoo, custom IMAP servers. Can search, read, classify, summarize, and mark as read. Trigger on 'check email', 'read emails', 'email summary', 'inbox', 'unread messages'. Works with any IMAP provider."
---

# IMAP Email Skill

## Overview
Fetch, parse, classify, and summarize emails from any IMAP provider without sending content to cloud APIs. Works with Gmail, Outlook, Yahoo, iCloud, and custom IMAP servers.

## Prerequisites

### Python imaplib (Built-in)
No additional package needed — uses Python standard library.

### Environment Variables
Set email credentials (never hardcode):

```bash
export IMAP_HOST="imap.gmail.com"
export IMAP_USER="your-email@gmail.com"
export IMAP_PASS="your-app-password"  # Use App Password, not main password

# For multiple accounts:
export IMAP_HOST_1="imap.gmail.com"
export IMAP_USER_1="account1@gmail.com"
export IMAP_PASS_1="password1"

export IMAP_HOST_2="imap.outlook.com"
export IMAP_USER_2="account2@outlook.com"
export IMAP_PASS_2="password2"
```

### Supported Providers

| Provider | IMAP Host | Port | Notes |
|----------|-----------|------|-------|
| Gmail | imap.gmail.com | 993 | Use App Password, enable IMAP in settings |
| Outlook | imap-mail.outlook.com | 993 | Use App Password |
| Yahoo | imap.mail.yahoo.com | 993 | Generate app password |
| iCloud | imap.mail.me.com | 993 | Use app-specific password |
| Custom | [your.imap.server] | 993 | SSL/TLS default |

## Phase 1: CONNECT

Establish secure IMAP connection:

```python
import imaplib
import os

def connect_imap():
    host = os.getenv('IMAP_HOST')
    user = os.getenv('IMAP_USER')
    password = os.getenv('IMAP_PASS')
    
    try:
        mail = imaplib.IMAP4_SSL(host, 993)
        mail.login(user, password)
        return mail
    except imaplib.IMAP4.error as e:
        print(f"Login failed: {e}")
        return None

mail = connect_imap()
mail.select('INBOX')  # Select mailbox
```

## Phase 2: FETCH

Search for messages:

```python
import imaplib
from datetime import datetime, timedelta

def fetch_unread(mail, days=1):
    """Fetch unread emails from last N days"""
    since_date = (datetime.now() - timedelta(days=days)).strftime("%d-%b-%Y")
    
    status, messages = mail.search(None, f'UNSEEN SINCE {since_date}')
    msg_ids = messages[0].split()
    
    return msg_ids

def fetch_by_sender(mail, sender_email):
    """Fetch emails from specific sender"""
    status, messages = mail.search(None, f'FROM {sender_email}')
    return messages[0].split()

def fetch_by_date_range(mail, start_date, end_date):
    """Fetch emails in date range"""
    status, messages = mail.search(None, 
        f'SINCE {start_date} BEFORE {end_date}')
    return messages[0].split()

# Examples
unread_ids = fetch_unread(mail, days=7)  # Last 7 days
urgent_ids = fetch_by_sender(mail, 'boss@company.com')
```

## Phase 3: PARSE

Extract email details:

```python
import email
from email.mime.multipart import MIMEMultipart

def parse_email(mail, msg_id):
    """Extract From, To, Subject, Date, Body, Attachments"""
    status, msg_data = mail.fetch(msg_id, '(RFC822)')
    
    email_msg = email.message_from_bytes(msg_data[0][1])
    
    parsed = {
        'from': email_msg.get('From'),
        'to': email_msg.get('To'),
        'subject': email_msg.get('Subject'),
        'date': email_msg.get('Date'),
        'message_id': email_msg.get('Message-ID'),
        'body': '',
        'attachments': []
    }
    
    # Extract body (prefer plain text)
    if email_msg.is_multipart():
        for part in email_msg.walk():
            if part.get_content_type() == 'text/plain':
                parsed['body'] = part.get_payload(decode=True).decode('utf-8', errors='ignore')
                break
            elif part.get_content_type() == 'text/html':
                # Fallback to HTML if no plain text
                if not parsed['body']:
                    parsed['body'] = part.get_payload(decode=True).decode('utf-8', errors='ignore')
    else:
        parsed['body'] = email_msg.get_payload(decode=True).decode('utf-8', errors='ignore')
    
    # Extract attachments
    for part in email_msg.walk():
        if part.get_content_disposition() == 'attachment':
            parsed['attachments'].append({
                'filename': part.get_filename(),
                'size': len(part.get_payload(decode=True))
            })
    
    return parsed

# Example
email_data = parse_email(mail, b'1')
print(f"From: {email_data['from']}")
print(f"Subject: {email_data['subject']}")
print(f"Body (first 200 chars): {email_data['body'][:200]}")
```

## Phase 4: CLASSIFY

Categorize emails using local rules (no cloud API):

```python
import re
from datetime import datetime

def classify_email(email_data):
    """Classify email: URGENT, PERSONAL, NEWSLETTER, NOTIFICATION, SPAM"""
    
    from_addr = email_data['from'].lower()
    subject = email_data['subject'].lower()
    body = email_data['body'].lower()
    
    # Known urgent patterns
    urgent_keywords = ['urgent', 'asap', 'critical', 'emergency', 'immediate']
    if any(kw in subject for kw in urgent_keywords):
        return 'URGENT'
    
    # Known urgent senders (customize per user)
    urgent_senders = ['boss@', 'ceo@', 'legal@']
    if any(from_addr.endswith(s) for s in urgent_senders):
        return 'URGENT'
    
    # Personal (from known contacts)
    personal_domains = ['gmail.com', 'yahoo.com', 'hotmail.com']
    if any(from_addr.endswith(d) for d in personal_domains):
        return 'PERSONAL'
    
    # Newsletter (check for List-Unsubscribe header)
    if 'List-Unsubscribe' in email_data.get('headers', ''):
        return 'NEWSLETTER'
    
    # Marketing keywords
    marketing_keywords = ['unsubscribe', 'promotional', 'special offer', 'limited time']
    if any(kw in body for kw in marketing_keywords):
        return 'NEWSLETTER'
    
    # Notification (from automated systems)
    notification_patterns = ['noreply@', 'no-reply@', 'notifications@', 'alerts@']
    if any(from_addr.startswith(p.split('@')[0]) for p in notification_patterns):
        return 'NOTIFICATION'
    
    # Default to PERSONAL
    return 'PERSONAL'

# Example
category = classify_email(email_data)
print(f"Category: {category}")
```

## Phase 5: SUMMARIZE

Create daily digest markdown:

```python
def generate_digest(emails_by_category):
    """Generate markdown digest grouped by priority"""
    
    digest = "# Daily Email Digest\n\n"
    digest += f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M')}\n\n"
    
    # URGENT first
    if 'URGENT' in emails_by_category:
        digest += "## Urgent (Action Required)\n\n"
        for email in emails_by_category['URGENT']:
            digest += f"- **{email['subject']}** — {email['from']}\n"
            digest += f"  {email['body'][:100]}...\n\n"
    
    # PERSONAL
    if 'PERSONAL' in emails_by_category:
        digest += "## Personal\n\n"
        for email in emails_by_category['PERSONAL']:
            digest += f"- **{email['subject']}** — {email['from']}\n"
    
    # NOTIFICATION
    if 'NOTIFICATION' in emails_by_category:
        digest += "## Notifications\n\n"
        for email in emails_by_category['NOTIFICATION']:
            digest += f"- {email['subject']} ({email['from']})\n"
    
    # NEWSLETTER count only
    if 'NEWSLETTER' in emails_by_category:
        count = len(emails_by_category['NEWSLETTER'])
        digest += f"## Newsletters & Promotions\n\n"
        digest += f"{count} newsletters received (can be marked as read)\n\n"
    
    return digest

# Example
digest = generate_digest(emails_by_category)
print(digest)
```

## Phase 6: MARK AS READ

Mark emails as read (auto-archive newsletters/notifications):

```python
def mark_as_read(mail, msg_ids):
    """Mark email as read"""
    for msg_id in msg_ids:
        mail.store(msg_id, '+FLAGS', '\\Seen')

def auto_mark_newsletters(mail, emails):
    """Auto-mark newsletters and notifications as read"""
    for email in emails:
        if email['category'] in ['NEWSLETTER', 'NOTIFICATION']:
            mail.store(email['msg_id'], '+FLAGS', '\\Seen')

# IMPORTANT: Never auto-mark URGENT or PERSONAL emails
# Only auto-mark NEWSLETTER and NOTIFICATION
```

## Phase 7: DISCONNECT

Close IMAP connection safely:

```python
def close_connection(mail):
    """Close IMAP connection"""
    mail.close()
    mail.logout()

close_connection(mail)
```

## Multi-Account Workflow

Handle multiple email accounts:

```python
import os

def get_account_config(index):
    """Get IMAP config for account N"""
    return {
        'host': os.getenv(f'IMAP_HOST_{index}'),
        'user': os.getenv(f'IMAP_USER_{index}'),
        'pass': os.getenv(f'IMAP_PASS_{index}')
    }

def fetch_all_accounts():
    """Fetch emails from all configured accounts"""
    all_emails = []
    
    for i in range(1, 10):  # Support up to 9 accounts
        config = get_account_config(i)
        if not config['host']:
            break
        
        mail = imaplib.IMAP4_SSL(config['host'], 993)
        mail.login(config['user'], config['pass'])
        mail.select('INBOX')
        
        status, messages = mail.search(None, 'UNSEEN SINCE 1-Jan-2026')
        
        for msg_id in messages[0].split():
            email = parse_email(mail, msg_id)
            email['account'] = config['user']
            all_emails.append(email)
        
        close_connection(mail)
    
    return all_emails

# Unified digest
all_emails = fetch_all_accounts()
emails_by_category = {}
for email in all_emails:
    category = classify_email(email)
    if category not in emails_by_category:
        emails_by_category[category] = []
    emails_by_category[category].append(email)

digest = generate_digest(emails_by_category)
```

## Local-First: Ollama Classification

Use Ollama for sophisticated classification (no cloud API):

```python
import subprocess
import json

def classify_with_ollama(email_data):
    """Use local qwen3-coder for smart classification"""
    
    prompt = f"""Classify this email as one of: URGENT, IMPORTANT, PERSONAL, WORK, NEWSLETTER

From: {email_data['from']}
Subject: {email_data['subject']}
Body: {email_data['body'][:500]}

Respond with JSON: {{"category": "CATEGORY", "confidence": 0.95}}"""
    
    result = subprocess.run(
        ['ollama', 'run', 'qwen3-coder', prompt],
        capture_output=True,
        text=True
    )
    
    try:
        classification = json.loads(result.stdout)
        return classification['category']
    except:
        return 'PERSONAL'  # Fallback

# Example
category = classify_with_ollama(email_data)
```

Benefits of local classification:
- Fast (sub-second)
- No cloud API calls
- Email content stays local
- Can fine-tune rules per user
- Works offline

## Complete Workflow Example

```python
import imaplib
import os
from datetime import datetime, timedelta

# Connect
mail = imaplib.IMAP4_SSL(os.getenv('IMAP_HOST'), 993)
mail.login(os.getenv('IMAP_USER'), os.getenv('IMAP_PASS'))
mail.select('INBOX')

# Fetch unread from last 7 days
since_date = (datetime.now() - timedelta(days=7)).strftime("%d-%b-%Y")
status, messages = mail.search(None, f'UNSEEN SINCE {since_date}')
msg_ids = messages[0].split()

# Parse and classify
emails_by_category = {}
for msg_id in msg_ids:
    email = parse_email(mail, msg_id)
    category = classify_email(email)
    
    if category not in emails_by_category:
        emails_by_category[category] = []
    emails_by_category[category].append({**email, 'msg_id': msg_id})

# Generate digest
digest = generate_digest(emails_by_category)
print(digest)

# Auto-mark newsletters/notifications
for email in emails_by_category.get('NEWSLETTER', []):
    mail.store(email['msg_id'], '+FLAGS', '\\Seen')

for email in emails_by_category.get('NOTIFICATION', []):
    mail.store(email['msg_id'], '+FLAGS', '\\Seen')

# Close
mail.close()
mail.logout()

# Output digest to file
with open('email_digest.md', 'w') as f:
    f.write(digest)
```

## Security

### Never
- Hardcode credentials
- Log passwords
- Send email content to cloud APIs without explicit approval
- Store credentials in git

### Always
- Use environment variables for credentials
- Use App Passwords (not main account password)
- Enable 2FA on email account
- Restrict IMAP access (Gmail: "Less secure app access" or use App Passwords)
- Log connection attempts, not passwords

