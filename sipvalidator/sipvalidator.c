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

/* project:	sipvalidator
 * file: 	sipvalidator.c
 *
 * USAGE(Command-Line-Options):
 *
 *  -d <device>   -- device to sniff on [default: eth0]
 *  -p <port>     -- device-port [default: 5060]
 *  -n <nummsgs>  -- number of messages to sniff [default: -1 = unlimited]
 *  -t            -- log messages to stdout [default]
 *  -l <logfile>  -- log messages to "logfile"
 *  -s            -- log messages to syslog
 *  -o <logopts>  -- loglevel [default: 0]
 *  -r <filename> -- parse from <filename> instead of sniffing from network 
 *
 *  -h            -- this message
 *     
 *  Info about loglevel:
 *	0 - only timestamp
 *      1 - + syntaxerror-messages
 *      2 - + SIP-message-header
**/

#include <stdio.h>
#include <stdlib.h>
#include "LoggerModul.h"
#include "sipsniff.h"

/* syntax-error-stuff */ 
 extern char *synerrbufp;
 extern int numSynErrs;
 
/* usage-message of sipvalidator */
 void printUsage();

/* extern procedures */
 extern void initParsing();
 extern void CheckContentLength(char* sipp,int siplen);
 extern char getopt(int argc, char *args[], char *mask);
   
int main(int argc, char *args[]) {

	/* initialization */
	  char ch;	
	  extern char *optarg;
    	  extern int optopt,opterr;
	
	  unsigned char BISONDEBUGMODE;
	  unsigned char MSGFRMFILE;
	  unsigned char EXIT;
	  char* parsefile;
	  char* logfile;
	  char* device;
	  int port;
	  int nummsgs;
	  int logdests;
	  int logvlevel;
          char* fileBufferp;
          int ctr;
	  
	  int temp;
	  FILE *file;

	  extern int yydebug;

	  opterr=0; // no automatic error-output

	  BISONDEBUGMODE=0;
	  MSGFRMFILE=0;
	  EXIT=0;
	  parsefile=NULL;
	  logfile=NULL;
	  device=NULL;
	  port=5060;
	  nummsgs=0;
	  logdests=0;
	  logvlevel=0;
	  
	/* parse commandline-options */
	  while ((ch = getopt(argc, args, ":d:p:n:l:sto:hvbr:")) != -1) {
        	switch (ch) {
        	case 'd':
        	  /* device */
            		device=optarg;
           		break;
        	case 'p':
        	  /* port */
        		port=atoi(optarg);
           		if (port<1 || port>65535) {
           			fprintf(stderr,"Invalid portnumber(%d)",port);
           			EXIT=1;
           		};
        		break;
        	case 'n':
        	  /* number of messages to sniff */
            		nummsgs=atoi(optarg);
            		if (nummsgs<1) nummsgs=-1; // endless sniffing
            		break;
        	case 'l':
        	  /* log-filename */
            		logfile=optarg;
            		logdests+=LOGFILE;
            		break;
            	case 's':
            	 /* log to syslog */
            	 	logdests+=LOGSYSLOG;
            		break;
            	case 't':
            	 /* log to stdout - default-log-destination */
            	 	logdests+=LOGSTDOUT;
            	 	break;
  		case 'o':
            	 /* log-verbose-level */
            		temp=atoi(optarg);
            		switch(temp) {
            		case 0:
            			logvlevel=MODDATE;
            			break;
            		case 1:
            			logvlevel=MODERROR;
            			break;
            		case 2:
            			logvlevel=MODMESSAGE;
            			break;
            		default:
            			logvlevel=MODDATE;
            			break;
            		};
            		break;
            	case 'h':
            	 /* help-message - if EXIT-flag is set, there will be
            	  *  		   a usage-message automatically
            	  */
 			EXIT=1;
            		break;
            	case 'v':
            	 /* version-info (same like the help-message) */
            		EXIT=1;
            		break;
            	case 'b':
            	 /* bison-debug-mode - only for development !*/
            		printf("bison-debugmode.\n");
            		BISONDEBUGMODE=1;
            		break;
            	case 'r':
            	 /* parse one message from file - only for development ! */
            		parsefile=optarg;
            		printf("Parse message from file %s.\n",parsefile);
            		MSGFRMFILE=1;
            		break;
            	case ':':       /* -d,-p,-n,-l or -o without operand */
                    	fprintf(stderr,"Option -%c requires an operand\n", optopt);
                    	EXIT=1;
                	break;
        	case '?':
             		fprintf(stderr,"Unrecognised option: -%c\n", optopt);
             		EXIT=1;
            		break;
        	};
    	  };


    	/* quit if nessescary */
    	  if(EXIT) { printUsage(); exit(0); };

   	/* activate bison-debugging-modus ? */
	  if (BISONDEBUGMODE) yydebug=1;
	  else yydebug=0;

	/* use default-device eth0 ? */
	  if (device==NULL) device="eth0";

	/* init logging */
	  /* defaults */
	    if (logvlevel==0) logvlevel=MODDATE;
	    if (logdests==0)  logdests=LOGSTDOUT;

	  if (logdests&LOGFILE) {
	  	if(openLogFile(logfile)==1) {
	  		fprintf(stderr,"Couldn't open file %s for logging",logfile);
	  		exit(1);
	  	};
	  };
	  setDestination(logvlevel,logdests);

	/* start sniffing, or parsing from file */
	  if (MSGFRMFILE) {
	    // parse from file
	  	file = fopen(parsefile,"r");

		// read file, insert '\r' when missing before '\n'
	  	if (file!=NULL) {
			// get file-size and number of missing '\r'
                          ctr=0;
			  temp=0;
			  ch=getc(file);
			  if (ch=='\n') ctr++;
                          while(ch!=EOF) {
				if (ch=='\r') temp=1;
                                ch=getc(file);
                                ctr++;
				if (ch=='\n' && !temp) ctr++;
				temp=0;
                          };
                        
			// alloc mem and copy file to it (with adding '\r' if needed)
			fileBufferp=(char*)malloc(ctr);
			if (fileBufferp!=NULL) {

                          rewind(file);

			  ctr=0;
			  temp=0;
                          ch=getc(file);
                          if (ch=='\n') { fileBufferp[ctr]='\r'; ctr++; };
			  while(ch!=EOF){
				if (ch=='\r') temp=1;
                                fileBufferp[ctr]=ch;
                                ch=getc(file);
                                ctr++;
				if (ch=='\n' && !temp) { fileBufferp[ctr]='\r'; ctr++; };
				temp=0;
                          };
	  		  
			  yy_scan_bytes(fileBufferp,ctr);
	   		
			  initParsing();
			  yyparse();
			  
			  CheckContentLength(fileBufferp,ctr);
			  
	   		  if (numSynErrs!=0) Log(synerrbufp,fileBufferp);
			
			} else {
				fprintf(stderr,"Couldn't allocate mem for loading file!\n");
			};
				  
	   		fclose(file);
	   	} else {
			fprintf(stderr,"Couldn't open file %s for parsing\n",parsefile);
		};
	  } else {
	    // sniff from network and parse
		sipsniff(device,port,nummsgs); // runs parsing automatically
	  };

	  /* quit sipvalidator */
	    if (logdests&LOGFILE) closeLogFile();
	    exit(0);

} // END OF main

/* usage-message of sipvalidator */
void printUsage() {
	printf("Sip-Validator-Version: 0.4b\n");
	printf("\nUSAGE:\n");
	printf(" -d <device>    -- device to sniff on [default: eth0]\n");
	printf(" -p <port>      -- device-port [default: 5060]\n");
 	printf(" -n <nummsgs>   -- number of messages to sniff [default: -1 = unlimited]\n");
 	printf(" -t 	        -- log messages to stdout [default]\n");
        printf(" -l <logfile>   -- log messages to \"logfile\"\n");
        printf(" -s  	        -- log messages to syslog\n"); 
        printf(" -o <logopts>   -- loglevel [default: 0]\n\n");
        printf(" -r <filename>  -- parse from <filename> instead of sniffing from network\n"); 
        printf(" -h  	        -- this message\n");
        printf(" -v	        -- version\n\n");
        printf("Info about loglevel:\n \t0 - only timestamp\n");
        printf("\t1 - + syntaxerror-messages\n");
        printf("\t2 - + SIP-message-header\n\n");
};

// EOF sipvalidator.c
