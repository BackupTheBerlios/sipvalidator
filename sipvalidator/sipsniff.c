/* This file is part of SIP-Validator.
   Copyright (C) 2003  Philippe Gérard, Mario Schulz

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

/* File: sipniff.c
 * pcab-interface to snap SIP messages
 * 
 * Description:
 * 	1. It snaps packets from given port. (Only Ethernet-Packets are supported)
 *	2. Then it extracts SIP-Messages from these packets. (One packet per time)
 *	   But only UDP and TCP-Packets encapsulated in an IP-Packet are supported.
 *	   Only IPv4 is supported at the moment.	
**/

#include "sipsniff.h"

/* resource-allocation-flags */
  unsigned char ALLOC_BUFFER   = 0;
  unsigned char ALLOC_PCAPHNDL = 0;
  
u_char* pbuffer;
pcap_t *pcap_handle;

/* ptr. to error-message-buffer */
  extern char* synerrbufp;
 
/* variables for syntaxerror-count */
  extern int numSynErrs;

/* prepare Parser */
 extern int initParsing();

/* pcap-callback-procedure */
void pcap_callback(u_char *buffer, const struct pcap_pkthdr* pkthdr, const u_char* packet) {
 
  while(1) { // for leaving procedure easily if problem occurs
 
	int packet_len;	
	u_char* ether_payload[0];
	int i,j;
	u_int16_t ether_type;
	u_char* ip_payload[0];
	u_char* payload[0];
	u_char* sipp;
	u_int8_t protocol;
	int sip_len;
	int hdrs_len;
	u_char validSip;
	
	/* Get packet-len */
 	  packet_len = pkthdr->len;

	/* check len of received packet - drop if nessescary */
	  if (packet_len>ETHER_MAX_LEN) break;
	
	/* copy packet to buffer */
	  memcpy(pbuffer,packet,packet_len);
	  /* add Nullbyte at the end for printing buffer later */
	  pbuffer[packet_len]='\0';
	
	/* get etherheader to check type, get ether_payload */	 
	  ether_type = handle_ethernet(ether_payload, pbuffer);
	  if (ether_type!=ETHERTYPE_IP) {
		// No IP-packet -> throw away
		break;
	  };

	/* now get protocol and IP-payload, check IP-Version (must be 4) */	 
	 if (!handle_ip(&protocol,ip_payload, ether_payload[0])) break;
	  	 
	/* get SIP-Message depending on protocol */  	 
	 
	  switch (protocol) {
	    case IPPROTO_TCP: /* netinet/in.h */
	  	handle_tcp(payload,ip_payload[0]);
	  	break;
	    case IPPROTO_UDP: /* netinet/in.h */
	  	handle_udp(payload,ip_payload[0]);
	  	break;
	    default: 
	  	// Unsupported protocol	-> throw away
	  	break;	
	  };	
	  sipp=payload[0];
	  
	/* Get len of SIP-Message */
	  sip_len=packet_len-(int)(payload[0]-pbuffer);
	/* Get len of headers before SIP-Message */
	  hdrs_len=packet_len-sip_len;	 
	
	/* check whether it is really a SIP-message 
	 * A SIP-message contains the string "SIP/" either at the
	 * beginning (reponse) or near the end (request) of the first 
	 * line as part of SIP-Version
	**/
	validSip=0;
	if (sip_len<4);
	else if (strncmp("SIP/",sipp,4)==0) validSip=1; // seems to be a response
	else {
	      // Goto end of line, then look backward for the first "S"
	      // and try cmp "IP/"
	      for (i=0;i<sip_len;i++) {
	  	if (*(sipp+i)=='\n') {
	  	  // EOL found	
	  		for (j=i;j>0;j--) {
	  			if (*(sipp+j)=='S') {
	  			  // "S" found	
	  				if (j+7<=i && strncmp("IP/",sipp+j+1,3)==0) validSip=1;
	  				break;
	  			};	
	  		};
	  		break;	
	  	};			
	      };
	};
	if (!validSip) break;  // seems to be no SIP-message -> drop
	 	 	  
	// say lex what buffer to use for analysing 
	    yy_scan_bytes(sipp, sip_len);
	  
	/* start flex & bison to check syntax */
	  initParsing();
	  yyparse();
	  CheckContentLength(sipp,sip_len);
	  if (numSynErrs!=0) Log(synerrbufp,sipp);
	  
	  break;
  }; // END OF while(1)
};

int sipsniff(char* device, int port, int nummsgs) {

	/* initialisations */
	  char 		pcaperrbuf[PCAP_ERRBUF_SIZE]; // error-buffer for pcab-messages
	  int		res;
	
	  extern pcap_t	*pcap_handle;
	  bpf_u_int32 	net;  // IP
	  bpf_u_int32 	mask; // netmask
        
	  struct	bpf_program filter; // struct for compiled filter
	  char		filter_expr[MAXSTRINGSIZE]; // space for filter expression
	   
	  extern u_char* pbuffer;

	/* Generate Filterexpression */
	  snprintf(filter_expr,MAXSTRINGSIZE,"port %d",port);


	/* Get memory for one packet */
	 
	  if (!(pbuffer = (u_char*)malloc(BUFFERSIZE*sizeof(u_char)))) {
		fprintf(stderr,"Cannot allocate packetbuffer.\n");
		freeResources(); return 1;
	  };
	  ALLOC_BUFFER   = 1; // buffer successfull allocated	  

	         
  	/* open requested device for sniffing
  	 *
  	 * pcap_t *pcap_open_live(char *device, int snaplen,
         * 	int promisc, int to_ms, char *errbuf)
         *
         * - promiscious-mode (1)
         * - no read-timeout (0)
  	**/
  	  pcaperrbuf[0]=0; // for warning-recognition

  	  pcap_handle = pcap_open_live(device, BUFSIZ, 1, 0, pcaperrbuf);	
       	
       	  /* Error ? */
       	    if (pcap_handle==NULL) {
       		fprintf(stderr,"ERROR: Cannot open device %s for sniffing!\n",device);
       		fprintf(stderr,"pcap-message: %s\n",pcaperrbuf);
 		freeResources(); return 1;
       	    }; 
       	    ALLOC_PCAPHNDL=1;

	  /* Warning ? */
	    if (pcaperrbuf[0]!=0) {
		fprintf(stderr,"pcap-warning: %s\n",pcaperrbuf);
	    };
	  
	  
	  /* get the device-properties (needed for filter) */
          if (pcap_lookupnet(device, &net, &mask, pcaperrbuf)==-1) {
           	fprintf(stderr,"Error:\npcap-message: %s\n",pcaperrbuf);
 		freeResources(); return 1;		  	
          };
	  
	/* compile and set the filter */	
          if (pcap_compile(pcap_handle, &filter, filter_expr, 0, net)==-1) {       	
          	fprintf(stderr,"Internal error: Couldn't compile filter\n");
          	pcap_perror(pcap_handle,"pcap-message: ");
          	freeResources();
  		return 1;
          };
          if(pcap_setfilter(pcap_handle, &filter)==-1) {
            	fprintf(stderr,"Internal error: Couldn't set filter\n");
          	pcap_perror(pcap_handle,"pcap-message: ");
          	freeResources();
  		return 1;       	
          };
	  pcap_freecode(&filter); // free space for generated filterprogramm
	   
	/* start sniffing packets
	 *
	 * int pcap_loop(pcap_t *p, int cnt,
         * 	pcap_handler callback, u_char *user)
	 *
	 * - we let pcap sniff nummsgs-times or forever (nummsgs==-1)
	 * - if a packet occurs pcap calls our callback-routine 
 	**/
 	  printf("Start sniffing from device:%s at port:%d ...\n",device,port); 
 	  if (pcap_loop(pcap_handle, nummsgs, pcap_callback, NULL)==-1) {
 	  	fprintf(stderr,"pcap-error\n");
	  };
	  
	/* leave program */
	  freeResources();
	  return 0;

};

/* Handles Ethernet-Packet
 * 
 * sets pointer to ethernet-packet-payload
 * returns ether_type
**/
u_int16_t handle_ethernet(u_char** ether_payload, u_char* packet) {
		
	  struct ether_header* etherhdrp;
	  etherhdrp=(struct ether_header*)packet;	
	   
	  ether_payload[0] = (packet+ETHER_HDR_LEN); // get payload
	
	  return ntohs(etherhdrp->ether_type); // return ETHERTYPE
};

/* Handles IP-Packet
 *
 * sets pointer to ip-packet-payload
 *
 * @return 1	, if success
 * @return 0	, else (e.g. no IPv4)	
**/
int handle_ip(u_int8_t* protocol,u_char** ip_payload, u_char* ippacket) {
 
 	struct ip* ipp;
	ipp=(struct ip*)(ippacket);
	  
	/* check version */
	  if ((ipp->ip_v)!=4) return 0;
	  
	/* Get payload */
	  ip_payload[0]=(ippacket+sizeof(struct ip));  // legal ? - to do  
	
	*protocol=ipp->ip_p;
	return 1;	
};

/* Handles UPD-Packet
 *
 * Simply extracts payload
**/
void handle_udp(u_char** udp_payload, u_char* udppacket) {
	udp_payload[0]=(udppacket+sizeof(struct udphdr));
};

/* Handles TCP-Packet
 *
 * Simply extracts payload
**/
void handle_tcp(u_char** tcp_payload, u_char* tcppacket) {
	tcp_payload[0]=(tcppacket+sizeof(struct tcphdr));
};

/* frees tracked allocated resources
**/
void freeResources() {
	extern pcap_t	*pcap_handle;
	/* resource-allocation-flags */
  	  extern unsigned char ALLOC_BUFFER;
  	  extern unsigned char ALLOC_PCAPHNDL; 
	
	/* Close pcap-Handle */
	  if (ALLOC_PCAPHNDL) pcap_close(pcap_handle);
	  
	/* Free buffer */
	  if (ALLOC_BUFFER) free(pbuffer);
};

