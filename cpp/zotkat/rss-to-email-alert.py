import requests
import time
import os
import smtplib
import traceback
import sys
import re
from xml.etree import ElementTree as ET
from lxml import etree
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from time import mktime, strptime
from datetime import datetime

# Configuration
CACHE_FILE = "rss_cache.txt"
SMTP_SERVER = "smtp.gmail.com"  # Replace with your SMTP server
SMTP_PORT = 587
LOG_DIR = "logs"
LOG_FILE_FORMAT = "%Y-%m-%d-rss.log"
EMAIL_ADDRESS = "xxx@gmail.com"  # Replace with your email
EMAIL_PASSWORD = "xxx"  # Replace with your email password
ALERT_EMAIL = "xxx"  # Replace with the recipient email
USER_HOME = "xxx"  # Update to your home path
BASE_DIR = os.path.join(USER_HOME, "rssemail")

print(f"Python executable: {sys.executable}")
print(f"Current working directory: {os.getcwd()}")
print(f"Script directory: {os.path.dirname(os.path.abspath(__file__))}")

# Force absolute paths in file operations
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CACHE_FILE = os.path.join(SCRIPT_DIR, "rss_cache.txt")
LOG_DIR = os.path.join(SCRIPT_DIR, "logs")
sys.path.insert(0, SCRIPT_DIR)  # Ensure local imports work

def create_log_dir():
    """Create log directory if not exists using absolute path"""
    os.makedirs(LOG_DIR, exist_ok=True)
    # Ensure directory permissions
    os.chmod(LOG_DIR, 0o755)

def write_to_log(timestamp, feed_info, status, error=None, new_articles=0):
    """Write processing result to log file"""
    log_date = datetime.now().strftime("%Y-%m-%d")
    log_file = os.path.join(LOG_DIR, log_date + ".log")
    
    # Create directory if it somehow doesn't exist
    os.makedirs(LOG_DIR, exist_ok=True)
    
    log_entry = [
        timestamp,
        feed_info.get('title', 'Unknown Feed'),
        feed_info.get('url', 'No URL'),
        "Success" if status else "Failed",
        str(error)[:100] if error else "None",
        str(new_articles)
    ]
    
    with open(log_file, 'a', encoding='utf-8') as f:
        f.write(" | ".join(log_entry) + "\n")

def parse_opml(opml_content):
    """Parse OPML file and extract RSS feeds"""
    feeds = []
    root = ET.fromstring(opml_content)
    
    for outline in root.iter('outline'):
        if outline.attrib.get('type', '') == 'rss':
            feed = {
                'title': outline.attrib.get('title', 'Untitled Feed'),
                'url': outline.attrib.get('xmlUrl', ''),
                'website': outline.attrib.get('htmlUrl', '')
            }
            if feed['url']:
                feeds.append(feed)
    return feeds

def clean_xml(xml_str):
    """Preprocess XML to fix common issues before parsing"""
    # Fix extra closing } in <style> block (specific to your feed example)
    xml_str = re.sub(r'}\s*</style>', '}</style>', xml_str)
    
    # Remove invalid control characters that XML parsers hate
    xml_str = re.sub(r'[\x00-\x08\x0B-\x0C\x0E-\x1F\x7F]', '', xml_str)
    
    return xml_str

def parse_datetime(date_str):
    """Robust datetime parsing for RSS dates"""
    formats = [
        '%a, %d %b %Y %H:%M:%S %z',  # RFC 822
        '%Y-%m-%dT%H:%M:%SZ',        # ISO 8601
        '%a, %d %b %Y %H:%M:%S',     # No timezone
    ]
    for fmt in formats:
        try:
            return datetime.strptime(date_str, fmt)
        except ValueError:
            continue
    return None

def normalize_uri(uri):
    """Clean URIs for consistent cache checks"""
    uri = uri.strip()  # Remove whitespace
    return uri  

def get_feed_entries(feed_url):
    """Fetch and parse RSS feed entries"""
    try:
        session = requests.Session()  # MOVE THIS UP BEFORE THE REQUEST

        # Configure retry FIRST
        retries = requests.adapters.Retry(
            total=7,
            backoff_factor=0.3,
            status_forcelist=[403, 500, 502, 503, 504]
        )
        session.mount('https://', requests.adapters.HTTPAdapter(max_retries=retries))
        session.mount('http://', requests.adapters.HTTPAdapter(max_retries=retries))

        headers = {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Safari/605.1.15',
            'Accept': (
                'application/rss+xml, '          # RSS feeds
                'application/atom+xml, '          # Atom feeds
                'text/xml, '                      # Generic XML
                'application/xml, '              # Another XML variant
                'text/html;q=0.9, '               # HTML pages (lower priority)
                'text/plain;q=0.8, '             # Plain text (e.g., raw RSS/Atom)
                '*/*;q=0.1'                      # Fallback for all other content types
            ),
            'Referer': feed_url.split('//')[0] + '//' + feed_url.split('/')[2],  # Auto-generate domain
            'DNT': '1'
        }
        
        # Force HTTPS for servers that dislike HTTP
        feed_url = feed_url.replace('http://', 'https://')

        try:
            response = session.get(
                feed_url,
                headers=headers,
                timeout=(3.05, 30),
                verify=True  # Default
            )
        except requests.exceptions.SSLError:
            print(f"Retrying {feed_url} without SSL verification")
            response = session.get(
                feed_url,
                headers=headers,
                timeout=(3.05, 30),
                verify=False  # Last resort
            )

        response.raise_for_status()

        # Preprocess XML before parsing
        cleaned_xml = clean_xml(response.text)
        
        # Use lxml parser with recovery mode
        parser = etree.XMLParser(recover=True, resolve_entities=False)
        feed = etree.fromstring(cleaned_xml.encode(), parser=parser)

        namespaces = {
            'rss': 'http://purl.org/rss/1.0/',  # Needed for RSS 1.0 (RDF-based)
            'rdf': 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
            'dc': 'http://purl.org/dc/elements/1.1/',
            'prism': 'http://prismstandard.org/namespaces/1.2/basic/'
        }

        entries = []

        for item in feed.iterfind('.//item'):
            entry = {
                'guid': (item.findtext('guid') or item.findtext('link') or '').strip(),
                'title': item.findtext('title', 'No Title').strip(),
                'link': item.findtext('link', '').strip(),
                'description': (item.findtext('description', '') or '').strip(),
                'pub_date': item.findtext('pubDate', '').strip()
            }
            entries.append(entry)
                # ADD MISSING NAMESPACES (critical for RSS/RDF parsing)


        # KEY FIX: Use the correct XPath with the 'rss' namespace
        for item in feed.findall('.//rss:item', namespaces=namespaces):  
            entry = {
                'guid': (
                    (item.findtext('rss:guid', namespaces=namespaces, default='') or '').strip() or 
                    (item.findtext('dc:identifier', namespaces=namespaces, default='') or '').strip() or 
                    (item.findtext('rss:link', namespaces=namespaces, default='') or '').strip()
                ),
                'title': item.findtext('rss:title', namespaces=namespaces, default='No Title').strip(),
                'link': item.findtext('rss:link', namespaces=namespaces, default='').strip(),
                'description': (item.findtext('rss:description', namespaces=namespaces, default='') or '').strip(),
                'pub_date': (
                    item.findtext('pubDate', namespaces=namespaces) or  # RSS 2.0-style
                    item.findtext('dc:date', namespaces=namespaces) or 
                    item.findtext('prism:publicationDate', namespaces=namespaces) or ''
                ).strip(),
                # Handle namespaced fields (e.g., prism:doi)
                'doi': item.findtext('prism:doi', namespaces=namespaces),
                'authors': [creator.text.strip() 
                           for creator in item.findall('dc:creator', namespaces=namespaces)],
                'journal': item.findtext('prism:publicationTitle', namespaces=namespaces)
            }
            entries.append(entry)
        return entries

    except Exception as e:
        print(f"Error fetching {feed_url}: {str(e)[:200]}")  # Truncate long errors
        return []  # Return empty list instead of raising

def load_cache():
    """Load previously seen article GUIDs"""
    if os.path.exists(CACHE_FILE):
        with open(CACHE_FILE, 'r') as f:
            return set(f.read().splitlines())
    return set()

def save_cache(cache):
    """Save updated cache to file"""
    with open(CACHE_FILE, 'w') as f:
        f.write('\n'.join(cache))

def format_datetime(pub_date_str):
    """Parse various date formats from RSS feeds"""
    try:
        if pub_date_str:
            # Try RFC 822 format
            pub_date = strptime(pub_date_str, "%a, %d %b %Y %H:%M:%S %z")
            return datetime.fromtimestamp(mktime(pub_date))
    except ValueError:
        try:
            # Try ISO 8601 format
            return datetime.fromisoformat(pub_date_str)
        except:
            return None
    return None

def send_email(subject, body):
    """Send email notification"""
    msg = MIMEMultipart()
    msg['From'] = EMAIL_ADDRESS
    msg['To'] = ALERT_EMAIL
    msg['Subject'] = subject
    msg.attach(MIMEText(body, 'plain'))

    try:
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()
            server.login(EMAIL_ADDRESS, EMAIL_PASSWORD)
            server.sendmail(EMAIL_ADDRESS, ALERT_EMAIL, msg.as_string())
        print(f"Email sent: {subject}")
    except Exception as e:
        print(f"Error sending email: {e}")

def process_feed(feed, cache):
    """Process a single feed and return result with status"""
    try:
        entries = get_feed_entries(feed['url'])
        new_entries = []
        
        # Sort entries chronologically (oldest first)
        entries = sorted(entries, key=lambda x: format_datetime(x['pub_date']) or datetime.min)
        
        for entry in entries:
            # Use normalized GUID
            normalized_guid = normalize_uri(entry['guid'])
            entry['guid'] = normalized_guid  # Update entry GUID

            if normalized_guid not in cache:
                new_entries.append(entry)
                cache.add(normalized_guid)
        
        return {
            'success': True,
            'new_entries': new_entries,
            'error': None
        }
    except Exception as e:
        return {
            'success': False,
            'new_entries': [],
            'error': str(e)
        }

def generate_email_body(feed, new_entries):
    """Generate email body content for new entries"""
    body = f"New articles in {feed['title']}:\n\n"
    body += f"Feed Website: {feed['website']}\n\n"
    
    for entry in new_entries:
        pub_date = format_datetime(entry['pub_date'])
        date_str = pub_date.strftime("%Y-%m-%d %H:%M:%S") if pub_date else "Unknown date"
        
        body += f"Title: {entry['title']}\n"
        body += f"Published: {date_str}\n"
        body += f"Link: {entry['link']}\n\n"
    
    return body

def write_email_error_log(error_details):
    error_log = os.path.join(LOG_DIR, "email_errors.log")
    with open(error_log, 'a') as f:
        f.write(f"{datetime.now()} - {error_details}\n")

def send_email_with_retry(subject, body, max_retries=3):
    """Send email with retry logic and connection validation"""
    for attempt in range(max_retries):
        try:
            msg = MIMEMultipart()
            msg['From'] = EMAIL_ADDRESS
            msg['To'] = ALERT_EMAIL
            msg['Subject'] = subject
            msg.attach(MIMEText(body, 'plain'))

            # Use SMTP_SSL for port 465, SMTP for port 587 with starttls()
            with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
                server.ehlo()
                if SMTP_PORT == 587:
                    server.starttls()
                    server.ehlo()
                server.login(EMAIL_ADDRESS, EMAIL_PASSWORD)
                server.sendmail(EMAIL_ADDRESS, ALERT_EMAIL, msg.as_string())
                print(f"Email sent successfully on attempt {attempt+1}")
                return True

        except smtplib.SMTPServerDisconnected:
            print(f"Connection lost. Retrying... ({attempt+1}/{max_retries})")
            time.sleep(5 * (attempt+1))  # Exponential backoff
        except smtplib.SMTPException as e:
            print(f"SMTP error: {str(e)}")
            break  # Fatal error, no retry
        except Exception as e:
            print(f"General error: {str(e)}")
            break

    print("Failed to send email after retries")
    return False

def check_feeds_and_notify(opml_content):
    """Main function to check feeds and send notifications per feed"""
    create_log_dir()
    feeds = parse_opml(opml_content)
    cache = load_cache()
    total_new_articles = 0
    
    for feed in feeds:
        processing_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"\nProcessing {feed['title']} at {processing_time}")

        status = False
        error = None
        articles_count = 0
        temp_cache = set()  # Temporary storage for new GUIDs
        
        try:
            result = process_feed(feed, cache)
            new_entries = result['new_entries']
            
            if result['success']:
                articles_count = len(new_entries)
                total_new_articles += articles_count
                
                if articles_count > 0:
                    new_entries_sorted = sorted(
                        new_entries,
                        key=lambda x: format_datetime(x['pub_date']) or datetime.min,
                        reverse=True
                    )
                    subject = f"{articles_count} new articles in {feed['title']}"
                    body = generate_email_body(feed, new_entries_sorted)
                    
                    # Try to send email before cache update
                    email_success = send_email_with_retry(subject, body)
                    
                    if email_success:
                        # If email succeeds, update both cache sets
                        for entry in new_entries_sorted:
                            cache.add(entry['guid'])
                            temp_cache.add(entry['guid'])
                        save_cache(cache)
                        status = True
                    else:
                        error = "Email failed after retries"
                        status = False

            # Store temporary cache even if email failed
            cache.update(temp_cache)  # Add this line if you want to preserve during failed emails

        except Exception as e:
            error = str(e)
            traceback.print_exc()
        
        finally:
            write_to_log(
                timestamp=processing_time,
                feed_info=feed,
                status=status,
                error=error,
                new_articles=articles_count
            )
    
    # Final cache save after all feeds processed
    save_cache(cache)
    
    # Write summary to log (optimized version)
    log_file = os.path.join(LOG_DIR, f"{datetime.now().strftime('%Y-%m-%d')}.log")
    summary_line = f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} | Processed {len(feeds)} feeds | Total new articles: {total_new_articles}"
    with open(log_file, 'a', encoding='utf-8') as f:
        f.write(f"\n{'-'*50}\n{summary_line}\n{'-'*50}\n")


def get_opml_from_github():
    """Fetch OPML content from GitHub repository"""
    github_raw_url = "https://raw.githubusercontent.com/ubtue/zotero-enhancement-maps/refs/heads/master/rss-to-email-zotkat"
    try:
        response = requests.get(github_raw_url)
        response.raise_for_status()
        return response.text
    except Exception as e:
        print(f"Error fetching OPML from GitHub: {e}")
        return None

if __name__ == "__main__":
    # Load OPML content from GitHub
    OPML_CONTENT = get_opml_from_github()
    if OPML_CONTENT:
        check_feeds_and_notify(OPML_CONTENT)
    else:
        print("Failed to load OPML content from GitHub")
