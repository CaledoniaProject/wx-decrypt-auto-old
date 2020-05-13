### Intro

Old scripts to extract messages from WX, not guaranteed to work

### To compile sqlcipher 2.1 on MacOS

https://launchpad.net/ubuntu/+source/sqlcipher/2.1.1-2

```
./configure --enable-tempstore=yes CFLAGS="-DSQLITE_HAS_CODEC -I/usr/local/homebrew/opt/openssl/include /usr/local/homebrew/opt/openssl/lib/libcrypto.a"
```

