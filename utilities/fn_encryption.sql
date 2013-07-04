/*
* @author: Justin Leto
* @date: July 3nd, 2013
*
* Description:
* 	Functions to encrypt and decrypt data.
*
* Dependencies: pgcrypto and plpythonu extensions need to be installed.
*
* Instructions:
*	1) Public and private keys need to be generated and exported
*		a) gpg --gen-key
*		b) gpg -a --export "Name (comment) <email@address.com>" > public.key
*		c) gpg -a --export-secret-keys "Name (comment) <email@address.com>" > secret.key
*		d) [recommended] Remove passphrase from secret key. This is required to work with these functions as they are written.
*			 (i) gpg --edit-key (and remove the passphrase from secret key)
*			 (ii) If you keep the passphrase, you'll need to modify the 
*		   If you keep the passphrase, you'll need to modify the _utility.fn_decrypt_with_secret_key function
*		   the pgp_pub_decrypt_bytea function call to add a third psw parameter which is the passphrase in clear text.
*			 >> cleartext := pgp_pub_decrypt_bytea(ciphertext, secret_key_bin, psw);
*		
*	2) Store these keys in the postgres data directory
*		a) mv public.key secret.key /var/lib/pgsql/data
*
*	3) Change group of the secret key to postgres and set permissions
*		a) chgrp postgres secret.key
*		b) chmod 440 secret.key
*		c) chmod 644 public.key
*
*/

/* Check for _utility schema. If it doesn't exist, create it. */
do $$
begin
	if not (SELECT exists(select schema_name FROM information_schema.schemata WHERE schema_name = '_utility'))
	then
		create Schema _utility;
	end if;
end $$;

/*
* function: _utility.fn_get_public_key(path text)
*
* description:
* 	Reads public key from file on disk. Trusted language pl/pythonu is required to access file system.
*
* parameters:
*	Path to public key on file system.
*
* usage:
*/
/*
do $$
declare public_key text;
		path text;
begin
	path = 'public.key'; -- public.key is stored in the pg database data directory.

	select * into public_key from _utility.fn_get_public_key(path);
	
	raise notice 'Public key is: %', public_key;
end $$;

*/

create or replace function _utility.fn_get_public_key(path text)
returns text as
$$
	import os
	if not os.path.exists(path):
		return "file not found"
	return open(path).read()
$$ language plpythonu security definer;

revoke all on function _utility.fn_get_public_key(text) from public;

comment on function _utility.fn_get_public_key(text) is 'Reads public key from file specified by [path] parameter. Returns text of key';


/*
* function: _utility.fn_get_secret_key(path text)
*
* description:
* Reads secret key from file on disk. Language pl/pythonu is required to access file system.
*
*/

/* usage:

do $$
declare secret_key text;
		path text;
begin
	path = 'secret.key'; -- public.key is stored in the pg database data directory.

	select * into secret_key from _utility.fn_get_secret_key(path);
	
	raise notice 'Secret key is: %', secret_key;
end $$;

*/

create or replace function _utility.fn_get_secret_key(path text)
returns text as
$$
	import os
	if not os.path.exists(path):
		return "file not found"
	return open(path).read()
$$
language plpythonu security definer;

revoke all on function _utility.fn_get_secret_key(text) from public;

comment on function _utility.fn_get_secret_key(text) is 'Reads secret key from file specified by [path] parameter. Returns text of key.';
/*
* function: _utility.fn_encrypt_with_public_key(
	path text
	cleartext text,
	ciphertext out bytea)
*
* description:
* Reads secret key from file on disk. Language pl/pythonu is required to access file system.
*
* parameters:
*	path: path of the public key on the filesystem.
*	cleartext: clear text data
*	ciphertext: encrypted data
*	
*/

/* usage:

do $$
declare ciphertext bytea;
		cleartext text;
begin
	cleartext='Hello World.';

	select * into ciphertext from _utility.fn_encrypt_with_public_key('public.key'::text, cleartext);

	raise notice E'\nText to Encrypt: %;\nEncrypted text: %', cleartext::text, ciphertext::text;
end $$;

*/
create or replace function _utility.fn_encrypt_with_public_key(
	path text,
	cleartext text,
	ciphertext out bytea
	) as $$
declare pubkey_bin bytea;
begin
	--pass text version of public key through function
	pubkey_bin := dearmor(_utility.fn_get_public_key(path));
	ciphertext := pgp_pub_encrypt(cleartext, pubkey_bin);
end;
$$ language plpgsql security definer;

revoke all on function _utility.fn_encrypt_with_public_key(text, text) from public;

comment on function _utility.fn_encrypt_with_public_key(text,text) is 'Use the public key read in from file specified by [path] parameter. Encrypt and return binary data.';

/*
* function: _utility.fn_decrypt_with_secret_key(
*	path text
*	ciphertext bytea,
*	cleartext out text)
*
* description:
* Reads secret key from file on disk. Trusted language pl/pythonu is required to access file system.
*
* parameters:
*	path: path of the public key on the filesystem.
*	ciphertext: the encrypted data
*	cleartext: clear text data
*
*/

/* usage:

create schema _sec;

do $$
declare path text;
		ciphertext bytea;
		cleartext text;
begin
	cleartext='Hello World.';

	drop table if exists _sec.encrypt_test;
	create table _sec.encrypt_test
	(
	  id integer not null,
	  encrypted_data bytea not null,
	  constraint encrypttest_pk primary key (id )
	);

	insert into _sec.encrypt_test (id, encrypted_data) values (1, (select * from _utility.fn_encrypt_with_public_key('public.key'::text, cleartext)));

	select * into ciphertext from _utility.fn_encrypt_with_public_key('public.key'::text, cleartext);

	path = 'secret.key';
	ciphertext = (select encrypted_data from _sec.encrypt_test where id = 1);
	select * into cleartext from _utility.fn_decrypt_with_secret_key(path, (select encrypted_data from _sec.encrypt_test where id = 1) );

	raise notice E'\nEncrypted text: %; \nDecrypted text: %; ', ciphertext::text, cleartext::text;
end $$;
*/

create or replace function _utility.fn_decrypt_with_secret_key(
	path text,
	ciphertext bytea,
	cleartext out text
) as $$
	declare secret_key_bin bytea;
begin
	--pass text version of secret key through function
	secret_key_bin := dearmor(_utility.fn_get_secret_key(path));
	cleartext := pgp_pub_decrypt_bytea(ciphertext, secret_key_bin);
end;
$$ language plpgsql security definer;

revoke all on function _utility.fn_decrypt_with_secret_key(text, bytea) from public;

comment on function _utility.fn_decrypt_with_secret_key(text, bytea) is 'Use the secret key read in from file specified by the [path] parameter to decrypt and return data as clear text.';

/* cleanup */
drop schema if exists _sec cascade;
