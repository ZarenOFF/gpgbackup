# GPG (GNU Privacy Guard) Guide

GPG (GNU Privacy Guard) is a tool for encrypting and signing data and communications. It is a free replacement for PGP (Pretty Good Privacy) and complies with the OpenPGP standard (RFC 4880).

### Installing GPG on Ubuntu

To install GPG on Ubuntu, run the following commands:

```sh
sudo apt update
sudo apt install gnupg
```

### Key Setup

To create a new GPG key, run the command:

```sh
gpg --full-generate-key
```

This command will start an interactive process where you will need to select the key type, key size, expiration date, and provide your name and email address.

Example steps:
1. Choose the key type (usually RSA and RSA).
2. Choose the key size (recommended 4096 bits).
3. Set the key expiration date.
4. Enter your name.
5. Enter your email address.
6. Enter a comment (optional).
7. Set a password to protect your key.

### Basic Commands

#### Encryption

To encrypt a file, use the command:

```sh
gpg --encrypt --recipient 'email@example.com' file.txt
```

Here, `email@example.com` is the email address you provided when creating the key.

#### Decryption

To decrypt a file, use the command:

```sh
gpg --decrypt file.txt.gpg
```

This command will prompt you to enter the password if the file was encrypted with a password.

To save the decrypted file, use the command:

```sh
gpg --output file.txt --decrypt file.txt.gpg
```

#### Exporting the Private Key

To export your private key, use the command:

```sh
gpg --export-secret-keys -a "email@example.com" > ~/gpg_key.asc
```

Here, `email@example.com` is the email address associated with your key, and `gpg_key.asc` is the file where your private key will be saved in ASCII format.