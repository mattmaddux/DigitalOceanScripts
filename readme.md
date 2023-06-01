# Digital Ocean Scripts

Some simple convenience scripts for setting up DO Droplets.

## WARNING ##

DO NOT USE!

These scripts make certain assumptions that might not be true in your circumstance. They may lock out out of your machine. Feel free to take whatever you like from them, but they're nothing special.


## Instructions

### Initial Droplet Setup

Log in as root using key pair, then run:

``` shell
bash <(curl -s https://raw.githubusercontent.com/mattmaddux/DigitalOceanScripts/main/initial_setup.sh)
```

### Wordpress Install

After previous script, log in as sudo user, then run:

``` shell
bash <(curl -s https://raw.githubusercontent.com/mattmaddux/DigitalOceanScripts/main/wordpress_install.sh)
```


### Wordpress Import from Local

Export your Local WP site as a zip, upload to server, then run:

``` shell
bash <(curl -s https://raw.githubusercontent.com/mattmaddux/DigitalOceanScripts/main/wordpress_import.sh)
```


## Support

NONE! I told you not to use it.