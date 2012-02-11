# After fetching/pulling:
1. Run `git submodule update`
2. Followed by `./install.rb`
3. Add ~/bin to your path

# Decrypting certain files
Definitely the following files are encrypted:
* ssh/known_hosts
* ssh/config

To decrypt, do the above setup, then:

1. Initialize the repo

		$ gitcrypt init

2. Enter the salt, password, and cipher from 1Password
3. Invoke:

		git reset --hard HEAD

Props to [shadowhand](https://github.com/shadowhand/)'s [git-encrypt](https://github.com/shadowhand/git-encrypt) for this encrypted hotness.