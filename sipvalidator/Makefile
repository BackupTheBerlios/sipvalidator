# ############################# #
# Makefile for SipValidator     #
# 		                #
# ############################# #

sipvalidator : LoggerModul.o sipparser.o sipsniff.o sipvalidator.o
	gcc -osipv LoggerModul.o sipparser.o sipsniff.o sipvalidator.o -lpcap
	
sipparser.o : sipparser.bison sipscanner.flex
	flex -osipscanner.c sipscanner.flex 
	@echo "!!! Ignore Bison-conflict-messages (will be solved by glr-parsing-algorithm) !!!:"
	bison -t -v -osipparser.c sipparser.bison 
	gcc -c sipparser.c
		
LoggerModul.o : LoggerModul.h LoggerModul.c
	gcc -c LoggerModul.c
	
sipsniff.o : sipsniff.h sipsniff.c
	gcc -c sipsniff.c
	
sipvalidator.o : sipvalidator.c LoggerModul.o
	gcc -c sipvalidator.c
	
clean :
	rm -f sipv sipparser.c sipparser.o sipscanner.c \
	sipsniff.o sipvalidator.o sipparser.output \
	LoggerModul.o

