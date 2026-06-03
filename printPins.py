#!/usr/bin/env python3 -uB
# Copyright (c) 2026 AustinSoft.com

import os
import subprocess
import base64
import hashlib
import argparse
import plistlib
from enum import Enum

def get_subject_field(subject_output, field_name):
    for line in subject_output.strip().split('\n'):
        line = line.strip()
        if line.startswith(field_name):
            return line.split('=', 1)[1].strip()
    return None

def getCerts(hostname):
    certOutput = subprocess.run(
        [
            'openssl',
            's_client',
            '-connect',
            hostname + ':443',
            '-showcerts',
            '-verify_quiet',
            '-no-interactive'
        ],
        input='Q\n',
        capture_output=True,
        encoding='utf-8',
        timeout=10
    ).stdout
    certPEMs = []
    currentCert = None
    for line in certOutput.split('\n'):
        if currentCert is None and line == '-----BEGIN CERTIFICATE-----':
            currentCert = line
        elif currentCert is not None:
            currentCert += '\n' + line
            if line == '-----END CERTIFICATE-----':
                certPEMs.append(currentCert)
                currentCert = None
    if currentCert is not None:
        print('Current cert is not None')
        exit(1)
    # Return certs in root->leaf order
    certPEMs.reverse()
    return certPEMs

def cn_pin(pemStr):
    # Extract CN via openssl
    subject = str(
        subprocess.check_output(
            [
                'openssl',
                'x509',
                '-subject',
                '-nameopt',
                'multiline,space_eq',
                '-noout'
            ],
            input=pemStr.encode(encoding='utf-8')
        ),
        encoding='utf8'
    )
    return get_subject_field(subject, 'commonName')

def issuer_pin(pemStr):
    # Extract the issuer's CN via openssl
    issuer = str(
        subprocess.check_output(
            [
                'openssl',
                'x509',
                '-issuer',
                '-nameopt',
                'multiline,space_eq',
                '-noout'
            ],
            input=pemStr.encode(encoding='utf-8')
        ),
        encoding='utf8'
    )
    return get_subject_field(issuer, 'commonName')

def chain_common_names(hostname):
    certs = getCerts(hostname)
    names = []
    # Get the "root's" issuer, since it may not be sent because the user
    # already has it.
    issuerCommonName = issuer_pin(certs[0])
    certCommonName = cn_pin(certs[0])
    if issuerCommonName is not None and issuerCommonName != certCommonName:
        names.append(issuerCommonName)
    for cert in certs:
        names.append(cn_pin(cert))
    return names

def infer_link(commonName):
    # A trailing run of digits is treated as a rotating "generation" number
    # (e.g. "ISRG Root X1", "R13", "Apple Public Server ECC CA 1 - G3"): pin the
    # stable, non-numeric prefix with prefixWithNumber so routine CA renewals
    # don't break the pin. Everything else is pinned exactly. Review the result
    # before shipping-you may prefer to relax a leaf entry to a suffix match.
    i = len(commonName)
    while i > 0 and commonName[i - 1].isdigit():
        i -= 1
    if 0 < i < len(commonName):
        return ('prefixWithNumber', commonName[:i])
    return ('exact', commonName)

def plist_fragment(hostname, names, includesSubdomains):
    chain = [{'type': linkType, 'value': value} for (linkType, value) in (infer_link(name) for name in names)]
    configuration = {
        'includesSubdomains': includesSubdomains,
        'chainSet': [chain],
    }
    # plistlib only emits whole documents, so serialize { host: configuration }
    # and then strip the XML header and the outer <plist>/<dict> wrapper. What
    # remains is the <key>host</key>/<dict>... entry, ready to paste directly
    # inside CNPinningManager > PinnedDomains in the app's Info.plist.
    document = plistlib.dumps({hostname: configuration}, sort_keys=False).decode('utf-8')
    lines = document.split('\n')
    start = next(index for index, line in enumerate(lines) if line.strip() == '<dict>') + 1
    end = max(index for index, line in enumerate(lines) if line.strip() == '</dict>')
    return '\n'.join(lines[start:end])

parser = argparse.ArgumentParser(
    prog='printPins.py',
    description='Prints the CN pins for the designated host'
)
parser.add_argument(
    'hostname',
    help='Hostname to check'
)
parser.add_argument(
    '--format',
    choices=['names', 'plist'],
    default='names',
    help='Output format. "names" (default) prints one Common Name per line, '
         'root to leaf. "plist" prints an Info.plist <key>/<dict> fragment '
         'ready to paste into CNPinningManager > PinnedDomains.'
)
parser.add_argument(
    '--includes-subdomains',
    action='store_true',
    help='In plist output, set includesSubdomains to true (default is false).'
)

args = parser.parse_args()

names = chain_common_names(args.hostname)

if args.format == 'plist':
    print(plist_fragment(args.hostname, names, args.includes_subdomains))
else:
    for name in names:
        print(name)
