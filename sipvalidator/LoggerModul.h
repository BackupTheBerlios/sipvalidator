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

/** 
 * LoggerModul.h 
 */

#ifndef __LOGGERMODUL_SIP_VALIDATOR
#define __LOGGERMODUL_SIP_VALIDATOR

#include <stdio.h>
#include <syslog.h>
#include <time.h>

// global Variablen
time_t t;
char *timeString;

//modus
static int MODDATE = 1;
static int MODERROR = 2;
static int MODMESSAGE = 3;

//destination
static int LOGFILE = 1;
static int LOGSYSLOG = 2;
static int LOGSTDOUT = 4;
 


// INIT timeString
void callTime();

// write a Message to destination
void setDestination(int modus, int destination);
void Log(char *message, char *errormessage);
int openLogFile(char *fileName);
int closeLogFile();

//#include "LoggerModul.c"


#endif // __LOGGERMODUL_SIP_VALIDATOR
