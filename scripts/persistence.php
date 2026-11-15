<?php
// UVdesk's public console command performs writes; database queries below are read-only.
$path='/var/www/uvdesk/var/railway-product-proof.json';
$phase=getenv('SMOKE_PHASE'); $email='railway-persistence@example.invalid';
$pdo=new PDO('mysql:host='.getenv('UVDESK_DB_HOST').';port='.(getenv('UVDESK_DB_PORT')?:'3306').';dbname='.(getenv('UVDESK_DB_NAME')?:'uvdesk'),getenv('UVDESK_DB_USER')?:'uvdesk',getenv('UVDESK_DB_PASSWORD'),[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION]);
function userRow($pdo,$email) { $q=$pdo->prepare('SELECT id,email,password FROM uv_user WHERE email=?');$q->execute([$email]);return $q->fetch(PDO::FETCH_ASSOC); }
if ($phase==='boot') {
 if(file_exists($path)||userRow($pdo,$email)) throw new Exception('boot must be pristine');
 $cmd='cd /var/www/uvdesk && php bin/console uvdesk_wizard:defaults:create-user ROLE_SUPER_ADMIN '.escapeshellarg('Persistent Validation User').' '.escapeshellarg($email).' '.escapeshellarg(getenv('UVDESK_ADMIN_PASSWORD').'Proof').' --no-interaction';
 exec($cmd.' 2>&1',$lines,$rc);if($rc!==0)throw new Exception('UVdesk account API failed: '.implode("\n",$lines));
 $user=userRow($pdo,$email);if(!$user)throw new Exception('account API did not create user');
 file_put_contents($path,json_encode(['id'=>$user['id'],'email'=>$email,'password_hash'=>$user['password']]));
} elseif(!file_exists($path))throw new Exception('original account manifest lost; refusing recreation');
$seed=json_decode(file_get_contents($path),true,512,JSON_THROW_ON_ERROR);$user=userRow($pdo,$email);
if(!$user||$user['id']!=$seed['id']||$user['password']!==$seed['password_hash'])throw new Exception('original user identity or password lost');
if(!password_verify(getenv('UVDESK_ADMIN_PASSWORD').'Proof',$user['password']))throw new Exception('persisted credential invalid');
echo json_encode(['phase'=>$phase,'user_id'=>$user['id'],'email'=>$email,'original_identity_preserved'=>true])."\n";
