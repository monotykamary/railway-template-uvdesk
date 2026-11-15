import urllib.parse,re
def owned_url(base,path):
 if not path.startswith('/') or path.startswith('//') or '\\' in path:raise ValueError('nonlocal path')
 url=base.rstrip('/')+path;a=urllib.parse.urlsplit(base);b=urllib.parse.urlsplit(url)
 if a.scheme!='http' or (a.scheme,a.netloc)!=(b.scheme,b.netloc) or b.username:raise ValueError('cookie target mismatch')
 return url
def redirect_ok(status,location,public_host):
 v=urllib.parse.urlsplit(location);canonical=urllib.parse.urlsplit('https://'+public_host)
 return status in (301,302,303) and v.scheme=='https' and v.netloc==canonical.netloc and not v.username and v.path=='/en/member/dashboard'
def identity_ok(status,body):
 text=re.sub('<[^>]*>',' ',body);text=' '.join(text.split())
 return status==200 and 'logout' in body.lower() and ('Persistent Validation User' in text or 'railway-persistence@example.invalid' in body)
