/* This file is part of SIP-Validator.
   Copyright (C) 2003  Mario Schulz, Philippe Gerard

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

/* project: sipvalidator
 * file: 	LoggerModul.c
 *
**/

#include "LoggerModul.h"

int LogMod = 0; 
int DestFile = 0; // Datei
int DestSysL = 0; // Syslog
int DestSdio = 0; // Standart out

FILE *fp;

void callSyslog(char *message, char *errormessage);
void callFile(char *message, char *errormessage);
void callStdout(char *message, char *errormessage);


// Init TimeString include actual Time
void callTime() {
    t = time(NULL);  
    timeString = ctime(&t);
};

void setDestination(int modus, int destination) {
  LogMod = modus;
    
  DestFile = ((destination) & LOGFILE);
  DestSysL = (((destination) & LOGSYSLOG)/LOGSYSLOG);  
  DestSdio = (((destination) & LOGSTDOUT)/LOGSTDOUT); 
};

// Log the messages
void Log(char *message, char *errormessage) {
  
  if(DestSysL==1) {
    callSyslog(message,errormessage);
  } else {};

  if(DestFile==1) {
    callFile(message,errormessage);
  } else {};

  if(DestSdio==1) {
    callStdout(message,errormessage);
  } else {};

};



// ############  SysLog ###########

// delete \n of the message
void printSyslog(char* message) {
		
  char dummy = message[0];
  char abbruch = message[0];
  char text[500];
  int i = 0;
  int d = 0;
  int lineno=0;
  if(message!=NULL) {
    while(abbruch != '\0') {
      while((dummy != '\n') && (dummy != '\0')) {
	text[i]=dummy;
	i++;
	dummy=message[d+i];
      }
      lineno++;
      text[i]=0;
      text[i-1]=0;
      abbruch = message[d+i];
      d = d+i+1; // delete the EscapeSequenz
      dummy = message[d];
      syslog(LOG_ERR, "(line %d) %s",lineno,text);
      i = 0;
    }
  }
} // End printSyslog


// write to Syslog
void callSyslog(char *message, char *errormessage) {
  
  openlog("SIP Validator", LOG_CONS | LOG_PID, LOG_USER);

  callTime();

  switch(LogMod) {
  case 1: //easy message
    syslog(LOG_ERR, "Syntax Fehler:");
    break;
  
  case 2: // message
    printSyslog(message);
    break;
  
  case 3: // message + errormessage
    printSyslog(message);
    printSyslog(errormessage);
    break;
  
  default: // Defaulmessage 
    syslog(LOG_ERR, "False use of LoogerModul");
    break;
  }

  closelog();

}; // end callSyslog(char*)

// ##########  Standartout ##########

void callStdout(char *message, char *errormessage) {

  callTime();

  switch(LogMod) {
  case 1: //Date
    printf("%s",timeString);
    break;
  
  case 2: // Date + errormessage
    printf("%s%s\n\n",timeString,message);
    break;
  
  case 3: // Date + errormessage + errormessage
    printf("%s%s\n%s\n\n",timeString,message,errormessage);
    break;
  
  default: // Date + Default Message
    printf("%s: %s",timeString, "False use of LoggerModul");
    break;
  }

} // ende callStdout

// ######### LogFile ##########

int openLogFile(char *fileName) {
  
  if ((fp=fopen(fileName,"a"))==NULL) { 
      return 1; 
  } 
  return 0;
}

void callFile(char *message, char *errormessage) {
   
  callTime();

  switch(LogMod) {
  case 1: //Date
    fprintf(fp, "%s\n",timeString);
    break;
  
  case 2: // Date + message
    fprintf(fp, "%s%s\n\n",timeString,message);
    break;
  
  case 3: // Date + message + errormessage
    fprintf(fp, "%s%s\n%s\n\n",timeString,message,errormessage);
    break;
  
  default: // Date + DefaultMessage
    fprintf(fp, "%s: %s",timeString, "False use of LoggerModul");
    break;
  }

} // end callFile

int closeLogFile() {
  if(fp!=NULL) {
    if(fclose(fp)==EOF) {
      return 1;
    }else{}
  }else{
    return 1;
  }
  return 0;

} // End closeLogFile



