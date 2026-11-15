#!/usr/bin/env python3
"""Server-side seeded account auth only; not HTTPS/browser cookie fidelity."""
import os,re,json,urllib.request,urllib.error,urllib.parse,http.cookiejar
from transport_guard import owned_url,redirect_ok,identity_ok
base=os.environ['BASE_URL'].rstrip('/');public_host=os.environ['PUBLIC_HOST'];password=os.environ['ADMIN_PASSWORD']+'Proof'
class NoRedirect(urllib.request.HTTPRedirectHandler):
 def redirect_request(self,*args,**kwargs):return None
def flow(pw):
 jar=http.cookiejar.CookieJar();opener=urllib.request.build_opener(NoRedirect(),urllib.request.HTTPCookieProcessor(jar))
 def request(path,data=None):
  url=owned_url(base,path)
  # Never mutate Secure/HttpOnly/SameSite. Replay only to exact owned worker origin.
  cookies='; '.join(c.name+'='+c.value for c in jar if c.value)
  req=urllib.request.Request(url,data=urllib.parse.urlencode(data).encode() if data else None,headers={'Cookie':cookies} if cookies else {})
  try:r=opener.open(req,timeout=30)
  except urllib.error.HTTPError as e:r=e
  return r.status,r.read().decode(),r.headers
 status,html,_=request('/en/member/login');assert status==200
 t=re.search(r'name="_csrf_token" value="([^"]+)"',html);assert t,'missing csrf token'
 status,html,headers=request('/en/member/login',{'_username':'railway-persistence@example.invalid','_password':pw,'_csrf_token':t.group(1)})
 return request,status,html,headers,jar
bad,_,_,_,_=flow('invalid-proof-password');status,html,_=bad('/en/member/dashboard');assert not identity_ok(status,html),'wrong password authorized'
request,status,html,headers,jar=flow(password)
assert redirect_ok(status,headers.get('Location',''),public_host),'unexpected canonical redirect'
assert jar, 'missing session cookie'
status,html,_=request('/en/member/dashboard');assert identity_ok(status,html),'seeded identity not authenticated'
print(json.dumps({'phase':os.environ['SMOKE_PHASE'],'seeded_account_authenticated':True,'server_auth_only':True,'browser_secure_cookie_verified':False,'tls_verified':False}))
