#!/usr/bin/env python3
import os,re,requests
b=os.environ['BASE_URL'].rstrip('/');pw=os.environ['ADMIN_PASSWORD'];home=requests.get(b+'/en/',timeout=30);assert home.status_code==200 and ('UVdesk' in home.text or 'Knowledgebase' in home.text)
s=requests.Session();g=s.get(b+'/en/member/login',timeout=30);token=re.search(r'name="_csrf_token" value="([^"]+)"',g.text);data={'_username':'admin@example.com','_password':pw};data.update({'_csrf_token':token.group(1)} if token else {});login=s.post(b+'/en/member/login',data=data,allow_redirects=True,timeout=30);assert login.status_code==200 and ('logout' in login.text.lower() or '/member/' in login.url),login.url
bad=requests.Session();g=bad.get(b+'/en/member/login');token=re.search(r'name="_csrf_token" value="([^"]+)"',g.text);data={'_username':'admin@example.com','_password':'wrong-password'};data.update({'_csrf_token':token.group(1)} if token else {});wrong=bad.post(b+'/en/member/login',data=data,allow_redirects=True);assert 'login' in wrong.url or 'invalid' in wrong.text.lower()
print('UVdesk smoke checks passed')
