/* This file is part of SIP-Validator.
   Copyright (C) 2003  Philippe Gerard, Mario Schulz

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*/

/* project: 	sipvalidator
 * file: 	sipsniff.h
 *
 * Header-File for pcab-interface to snap SIP messages
 * 
 * Description:
 * 	1. It snaps packets from given port. (Only Ethernet-Packets are supported)
 *	2. Then it extracts SIP-Messages from these packets. (One packet per time)
 *	   But only UDP and TCP-Packets encapsulated in an IP-Packet are supported.
 *	   Only IPv4 is supported at the moment.	
**/

#ifndef __SIPSNIFF_H
#define __SIPSNIFF_H

#include <pcap.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include <net/ethernet.h>
#include <netinet/ip.h>
#include <netinet/in.h>
#include <netinet/udp.h>
#include <netinet/tcp.h>

#include "LoggerModul.h"

#define BUFFERSIZE 	ETHER_MAX_LEN+1  /* net/ethernet.h, +1 for EO-String-Nullbyte */
#define MAXSTRINGSIZE	101


/* methods-declarations */

 int sipsniff(char* device, int port, int nummsgs);


 /* internal procedures */
  void pcap_callback(u_char *buffer, const struct pcap_pkthdr* pkthdr, const u_char* packet);

  void freeResources();

  u_int16_t handle_ethernet(u_char** ether_payload, u_char* packet);

  int handle_ip(u_int8_t *protocol,u_char** ip_payload, u_char* ippacket);

  void handle_udp(u_char** udp_payload, u_char* udppacket);

  void handle_tcp(u_char** udp_payload, u_char* tcppacket);

/* END OF methods-declarations */

#endif
