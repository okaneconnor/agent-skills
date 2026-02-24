#!/usr/bin/env python3
"""
Script to post a Jira story to Atlassian Cloud Jira.

Usage:
  python3 post_to_jira.py <markdown_file> --epic SCRUM-123
  python3 post_to_jira.py <markdown_file> --dry-run
  python3 post_to_jira.py <markdown_file> --epic SCRUM-123 --project SCRUM

All options can also be set via environment variables (see --help).
"""

import argparse
import base64
import json
import os
import re
import sys
from pathlib import Path

try:
    import requests
except ImportError:
    print("Error: 'requests' package is required. Install it with: pip install requests")
    sys.exit(1)

# Configuration — read from environment variables
JIRA_URL = os.environ.get('JIRA_URL', '').rstrip('/')
DEFAULT_PROJECT = os.environ.get('JIRA_PROJECT', '')


def load_env_file():
    """Load environment variables from .env file if present."""
    env_path = Path(__file__).parent / '.env'

    if env_path.exists():
        with open(env_path, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    if '=' in line:
                        key, value = line.split('=', 1)
                        key = key.strip()
                        value = value.strip()
                        if key not in os.environ:
                            os.environ[key] = value


def parse_markdown_file(file_path):
    """Parse markdown file and extract the title and description."""

    if not os.path.exists(file_path):
        print(f"Error: File '{file_path}' not found.")
        sys.exit(1)

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Extract title (first # heading or ## Title)
    title_match = re.search(r'^#\s+(.+?)$', content, re.MULTILINE)
    if title_match:
        content = content.replace(title_match.group(0), '', 1).strip()

    # Look for ## Title section — extract only the first line as the summary,
    # leaving any subsequent paragraph (short description) in the body.
    title_section_match = re.search(r'^##\s+Title\s*\n(.+?)(?=\n|$)', content, re.MULTILINE)
    if title_section_match:
        summary = title_section_match.group(1).strip()
        # Remove just the "## Title" heading and the summary line from the content
        content = content.replace(title_section_match.group(0), '', 1).strip()
    elif title_match:
        summary = title_match.group(1).strip()
    else:
        print("Error: Could not find title in markdown file.")
        print("  Please ensure your markdown has either:")
        print("  - A '# Title' at the top, or")
        print("  - A '## Title' section")
        sys.exit(1)

    jira_description = convert_markdown_to_jira(content)
    return summary, jira_description


def convert_markdown_to_jira(markdown_text):
    """Convert markdown to Jira Wiki Markup."""

    # Remove the draft header if present
    text = re.sub(r'^#.*?JIRA Story Draft.*?\n', '', markdown_text, flags=re.MULTILINE)

    # Convert code blocks first (before other conversions touch backticks)
    text = re.sub(r'```(\w+)\n(.*?)```', r'{code:\1}\n\2{code}', text, flags=re.DOTALL)
    text = re.sub(r'```\n(.*?)```', r'{code}\n\1{code}', text, flags=re.DOTALL)

    # Convert inline code `text` to {{text}}
    text = re.sub(r'`([^`]+)`', r'{{\1}}', text)

    # Convert headers
    text = re.sub(r'^#### (.+?)$', r'h4. \1', text, flags=re.MULTILINE)
    text = re.sub(r'^### (.+?)$', r'h3. \1', text, flags=re.MULTILINE)
    text = re.sub(r'^## (.+?)$', r'h2. \1', text, flags=re.MULTILINE)

    # Convert italic *text* to _text_ BEFORE bold, so we don't clobber bold output.
    # Match single * not preceded/followed by another *, but skip bullet lines.
    text = re.sub(r'(?<!\*)\*(?!\*|\s)(.+?)(?<!\*)\*(?!\*)', r'_\1_', text)

    # Convert bold **text** to *text* (Jira bold)
    text = re.sub(r'\*\*(.+?)\*\*', r'*\1*', text)

    # Convert markdown links [text](url) to [text|url]
    text = re.sub(r'\[([^\]]+)\]\(([^\)]+)\)', r'[\1|\2]', text)

    # Convert numbered lists: lines starting with "1. ", "2. ", etc.
    text = re.sub(r'^(\s*)\d+\.\s+', r'\1# ', text, flags=re.MULTILINE)

    # Tables are already in Jira format (||header|| and |cell|), so leave them as is

    return text.strip()


def build_auth_header(email, api_token):
    """Build Basic Auth header for Atlassian Cloud."""
    credentials = f"{email}:{api_token}"
    encoded = base64.b64encode(credentials.encode()).decode()
    return f"Basic {encoded}"


def create_jira_issue(email, api_token, project_key, summary, description, debug=False):
    """Create a Jira issue and return the issue key."""

    issue_data = {
        "fields": {
            "project": {
                "key": project_key
            },
            "summary": summary,
            "description": description,
            "issuetype": {
                "name": "Story"
            }
        }
    }

    headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": build_auth_header(email, api_token)
    }

    print(f"\nCreating Jira story in project {project_key}...")
    if debug:
        print(f"  [debug] Email: {email}")
        print(f"  [debug] Token length: {len(api_token)}")
        print(f"  [debug] URL: {JIRA_URL}/rest/api/2/issue")

    response = requests.post(
        f"{JIRA_URL}/rest/api/2/issue",
        headers=headers,
        data=json.dumps(issue_data)
    )

    if response.status_code == 201:
        issue_key = response.json()["key"]
        issue_url = f"{JIRA_URL}/browse/{issue_key}"
        print(f"Story created successfully!")
        print(f"  Issue Key: {issue_key}")
        print(f"  URL: {issue_url}")
        return issue_key
    else:
        print(f"Failed to create issue. Status code: {response.status_code}")
        print(f"  Response: {response.text}")
        return None


def link_to_epic(email, api_token, issue_key, epic_key, debug=False):
    """Link the created issue to an epic."""

    headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": build_auth_header(email, api_token)
    }

    # Try Epic Link custom field first
    link_data = {
        "update": {
            "customfield_10008": [{"set": epic_key}]
        }
    }

    if debug:
        print(f"  [debug] Attempting Epic Link via customfield_10008")

    response = requests.put(
        f"{JIRA_URL}/rest/api/2/issue/{issue_key}",
        headers=headers,
        data=json.dumps(link_data)
    )

    if response.status_code == 204:
        print(f"Successfully linked to Epic {epic_key}")
        print(f"  View Epic: {JIRA_URL}/browse/{epic_key}")
        return

    # Fallback: issue link
    if debug:
        print(f"  [debug] customfield_10008 failed ({response.status_code}), trying issueLink")

    link_data_alt = {
        "type": {"name": "Epic-Story Link"},
        "inwardIssue": {"key": issue_key},
        "outwardIssue": {"key": epic_key}
    }

    response = requests.post(
        f"{JIRA_URL}/rest/api/2/issueLink",
        headers=headers,
        data=json.dumps(link_data_alt)
    )

    if response.status_code == 201:
        print(f"Successfully linked to Epic {epic_key} (via issue link)")
    else:
        print(f"Warning: Could not automatically link to epic. You may need to link it manually.")
        print(f"  Please add Epic Link: {epic_key} in the Jira UI")


def build_parser():
    """Build the argument parser."""
    parser = argparse.ArgumentParser(
        description="Post a JIRA story to Atlassian Cloud Jira from a markdown draft.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""\
Environment variables:
  JIRA_URL         Atlassian Cloud instance URL (required, e.g. https://your-domain.atlassian.net)
  JIRA_PROJECT     Default project key (required, e.g. SCRUM)
  JIRA_API_EMAIL   Atlassian account email (required for posting)
  JIRA_API_TOKEN   API token for authentication (required for posting)
  JIRA_EPIC_KEY    Epic key to link the story to (optional)

Examples:
  python3 post_to_jira.py draft_story.md --epic SCRUM-123
  python3 post_to_jira.py draft_story.md --dry-run
  JIRA_EPIC_KEY=SCRUM-123 python3 post_to_jira.py draft_story.md
"""
    )
    parser.add_argument("markdown_file", help="Path to the markdown draft file")
    parser.add_argument("--epic", help="Epic key to link the story to (e.g. SCRUM-123). "
                        "Falls back to JIRA_EPIC_KEY env var.")
    parser.add_argument("--project", help="Project key. "
                        "Falls back to JIRA_PROJECT env var, then to the epic key prefix.")
    parser.add_argument("--email", help="Atlassian account email. Falls back to JIRA_API_EMAIL env var.")
    parser.add_argument("--token", help="Jira API token. Falls back to JIRA_API_TOKEN env var.")
    parser.add_argument("--dry-run", action="store_true",
                        help="Parse and convert the draft, print the Jira payload, but do not post.")
    parser.add_argument("--debug", action="store_true",
                        help="Print additional debug information (token length, request URLs).")
    return parser


def resolve_project_key(args):
    """Determine the project key from args, epic key, env var, or default."""
    if args.project:
        return args.project

    project_env = os.environ.get('JIRA_PROJECT')
    if project_env:
        return project_env

    if args.epic and '-' in args.epic:
        return args.epic.split('-')[0]

    return DEFAULT_PROJECT


def main():
    load_env_file()

    parser = build_parser()
    args = parser.parse_args()

    # Validate Jira URL is configured
    if not JIRA_URL:
        print("\nError: No Jira instance URL configured.")
        print("  Set JIRA_URL in your environment, e.g.:")
        print("  export JIRA_URL=\"https://your-domain.atlassian.net\"")
        sys.exit(1)

    # Parse the markdown file
    print(f"Reading story from: {args.markdown_file}")
    summary, description = parse_markdown_file(args.markdown_file)

    # Resolve epic key
    epic_key = args.epic or os.environ.get('JIRA_EPIC_KEY')

    # Resolve project key
    project_key = resolve_project_key(args)

    # Resolve API credentials
    api_email = args.email or os.environ.get('JIRA_API_EMAIL')
    api_token = args.token or os.environ.get('JIRA_API_TOKEN')

    print(f"\nConfiguration:")
    print(f"  Jira URL:  {JIRA_URL}")
    print(f"  Project:   {project_key}")
    print(f"  Email:     {api_email or '(not set)'}")
    print(f"  Epic:      {epic_key or '(none)'}")
    print(f"  Story:     {summary}")

    if args.dry_run:
        print(f"\n{'=' * 70}")
        print("DRY RUN - Jira payload (not posted)")
        print(f"{'=' * 70}")
        payload = {
            "fields": {
                "project": {"key": project_key},
                "summary": summary,
                "description": description,
                "issuetype": {"name": "Story"}
            }
        }
        print(json.dumps(payload, indent=2))
        print(f"\n{'=' * 70}")
        print("Jira Wiki Markup description preview:")
        print(f"{'=' * 70}")
        print(description)
        return

    # Email and token are required for actual posting
    if not api_email:
        print("\nError: No Atlassian email provided.")
        print("  Set JIRA_API_EMAIL in your environment or pass --email.")
        sys.exit(1)

    if not api_token:
        print("\nError: No API token provided.")
        print("  Set JIRA_API_TOKEN in your environment or pass --token.")
        sys.exit(1)

    issue_key = create_jira_issue(api_email, api_token, project_key, summary, description, debug=args.debug)

    if issue_key and epic_key:
        print(f"\nLinking story to Epic {epic_key}...")
        link_to_epic(api_email, api_token, issue_key, epic_key, debug=args.debug)

    if issue_key:
        print(f"\n{'=' * 70}")
        print("All done! Your story is now in Jira.")
        print(f"{'=' * 70}\n")
    else:
        print("\nFailed to create the story. Please check the error messages above.")
        sys.exit(1)


if __name__ == "__main__":
    main()