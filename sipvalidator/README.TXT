Little documentation for SIP-Validator
=====================================

1. What does SIP-Validator:
  SIP-Validator sniffs Ethernet-packets from a given network-device at a given port.
  If a packet contains a SIP-Message it will be extracted and then will be checked 
  for the syntactical correctness of the SIP-message-header.
  If there is a syntax-error line-number and range of the chars where the error is 
  suspected is logged - depending on the logoptions.

2. Compilation-Requirements:
  - Bison 1.875
  - flex 2.5
  - cc 3.2.3 (?)
  - libpcap-0.6.2-12

3. Compilation/Installation:
  - compile it with "make"
  - then simply start generated program "sipv"
  - "sipv -h" gives more info about usage
  
  

