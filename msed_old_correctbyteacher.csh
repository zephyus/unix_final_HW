# ======================================================================
#                        開發者註記 (Developer's Note)
# ======================================================================
#
# 檔案狀態：參考實作 (Reference Implementation)
#
# 核心摘要：
# 這份腳本是 'msed' 前處理器的一個完整、可運作的實作版本。
# 它的目標是為標準 sed 增加參數化、負數行號等擴充功能。
#
# 技術細節：
# 請特別注意，此版本完全依賴高階且複雜的 'sed' 技巧（例如標籤、
# 分支、保留空間操作）來完成所有翻譯和邏輯處理。
#
# 與新作業的關聯性：
# 本腳本即為「舊版作業」或「sed 解決方案」。對於另一個需要使用
# 'awk' 來實作的版本，這份腳本扮演著「規格說明書」的角色。
# 它精確地定義了 awk 版本在每個步驟中所需達成的行為和目標。
#
# 使用建議：
# 雖然此腳本功能上是正確的，但其可讀性低且難以維護。
# 建議將其作為理解邏輯的參考，而未來的開發應以 'awk' 版本為主。
#
# ======================================================================


#!/usr/bin/csh
#Save the piped-in input into a file:
cat > t4

#Create a file and put $1 into it, but also add a space in front of it. (The
#space is added so that line 17 below is facilitated. Further, see footnote 1
#for information on why it is argument 1 that gets put into the file):
echo \ $1:q > t5

#Loop through all of the passed-in arguments except for the first argument:
foreach i ( "`seq $# -1 2`" )
   #Within the t5 file, iteratively look for the $2, then the $3, etc.
   #If you find a match, create a new file t6, where the argument is replaced
   #by the actual argument value. (See footnote 2 in the README file for more
   #info on what I mean by saying the argument is replaced by its value, and
   #also for info on how to not be fooled by back-quoted $s.):
   cat t5 | sed ':L;s/\([^\\]\)\$'$i'/\1'$argv[$i]'/g;tL' > t6
   #Now move t6 back to t5, so that we are ready to set up the next argument.
   mv t6 t5
   #Since we're done processing this argument, remove it from argv, but not if
   #it's a flag that starts with a "-" (but remember that Cshell if-conditions
   #have a problem to overcome, when testing things that start with a "-").
   if ( X$argv[$i] !~ "X-*" ) set argv[$i] = ""
end

#Now we want to use almost every ";" into a line separation.
#   A line separator? Yes: The ";" becomes "\n;"
#   Almost every? Yes: because we DON'T want to do it for "\;". (See footnote
#   3 in the README file for more info on our strategy in handling backquoting
#   and also its limitations.)
#We also want to get rid of the space added by line 8, above:
#And we want to prevent any "\" that is itself backquoted (\\) from being used
#to backquote anything else. This is handled by turning them into "\a"s. 
cat t5 | sed 's/\\\\/\a/g;s/.//;s/\\;/\f/g;s/;/\n;/g' > t6

#Create a sed file from the part of this file below the exit:
sed 1,/^exit/d < msed > t7

#Use the sed program created on line 35, above, in order to process the file
#created on line 32 above (which, you will recall, is derived from argument 1,
#which is the sed program the user has provided):
cat t6 | sed -ft7 > t8

#Here are some initializations to set up the foreach loop that will follow:
rm -f t9
@ cnt = 0
@ z = 0

#Go through the version of sed commands stored in t8 (created from Line 40
#above), to see if any of the commands used a $-# syntax or a "f" or "F":
foreach x ( `cat t8`)
   #Here, x is a single line from t8, so it is usually a single sed command.
   #Now we want to make a variable y that will be the number # of any $-# that
   #might be on this line x. (Let y be "" otherwise.):
   set y = `echo $x:q | sed 's/[^\v]*\$\v-\([0-9]*\).*/\1/g;s/[^0-9]//g'`

   #So now, what if $y==a number? Well that means that we need to work out
   #what line number would match to $#-1? Set z to that line number:
   if ( X$y != X ) @ z = `cat t4 | wc -l` - $y

   #So now we take the single line $x and clean it up. The $-# will turn into
   #the number $z. Also to fix: make the branches used for "F" unique, by
   #adding a counter number to the end of whateven branch label may be in #x.
   #(See footnote 4 of the README file, for details on handling "F".)
   echo $x:q | sed 's/label7/&'$cnt'/g;s/\$-\v[0-9]*/'$z/ >> t9

   #Increase the counter used for the branch labels on line 63, above:
   @ cnt = $cnt + 1
end

#Line 63 above created t9, the ordinary sed implementation of the original
#program the user had provided in $1. So we replace $1 with t9:
set argv[1] = -ft9

#Line 3 had captured the piped-in input into t4. So we now process it:
cat t4 | sed $*:q

#And now we are done with cshell:
exit 0
#The rest of this file is sed code (see line 35, above)
#
#The section below here puts individual sed commands on individual lines.
#The issue is to clean up "y", "s", or "\" commands, because these commands
#can have ";" inside them - and if they did have ";", then these ";" will have
#caused line separations on Line 32, above. We need to recogize if the current
#line _starts with a "y", "s", "/", or "\" *and* is incomplete. In that case,
#bring in additional line(s), until the full command is on one line.
#Note: This is a full section using multiple branches.
#Note: This section is as many lines as you need.
#Note: All of the following should get pulled into one line each:
#      s/;/;/  or  s;a;b;  or  y;,\;;\;,;  or  \;a;b;  or  /;;/p   or   etc.
#Note: But, to keep things simple, we won't worry about: "[;]".
#Note: In our new version of sed, we like the fact that ";" will cause breaks
#      for i, a, c, C, w, W, r.

#This section combines lines to form /.../ or \x...x -- if there are ; in it:
:L
/^[\/]/!bM
/^\/.*\//bM
/^\\\(.\).*\1/bM
N;s/\n/;/;tL

#Now we consider ", /.../" or ", \x...x" since these can have ;
#Step 1 is to mark off the part that might go before the , by using a \v
:M
s/^\/.*\/ */&\v/
s/^\\\(.\).*\1 */&\v/
s/^[0-9]\{1,\} */&\v/
s/^$ */&\v/

:N
/\v, *[\/]/!bO
/\v, *\/.*\//bO
/\v, *\\\(.\).*\1/bO
N;s/\n/;/;tN

:O
#Now put a \v after whatever predication may be given (including none)
s/\v\(, *\/.*\/ *\)/\1\v/
s/\v\(, *\\\(.\).*\1 *\)/\1\v/
s/\v\(, *[0-9]\{1,\} *\)/\1\v/
s/\v\(, *$ *\)/1\v/
/\v/!s/^ */&\v/

#Now deal with y and s comands that might use ";"
/\v[ys]/!bQ
:P
/\v[ys]\(.\).*\1.*\1/bQ
N;s/\\n/;/;bP

:Q
s/^;//;s/\v//

#
#So now we have whole sed commands on lines.
#Complete the lines below:
#In the lines below, note that these patterns match to the beginning of the
#line. If you think about it, this means that, in the msed language, these
#commands can't be predicated. We will just call this a feature of msed: so
#you do not need to worry about fixing predication on these commands.
#In the two flagL[12] lines I added here some cpability beyond what I require.
TflagL1; x; s/$/\r\v/; x; :flagL1
s_^Z_s/[^\\n]\\n\\{,1\\}//_
s_^W\(.*\)_{ s/^/\\v/\n H\n s/.//\n s/\\n.*//\n w\1\n g\n s/\\v.*//\n x\n s/.*\\v//\n}_
s_^D_{/\\n/!s/$/\\n/;D;}_
s_^C\(.*\)_s/.*/\1/_
TflagL2; :flagL2; x; s/$\r\x//; x
s_^f_s/^//_
#Next one uses generic labels, but line 63 above is needed to get them unique:
s_^F_tlabel7;:label7_
#These add an unusual symbol ("\v", which doesn't occur in the input) to mark
#out the $-#, so that line 63 above can find them and convert them:
s_^\$-_&\v_
s_, *\$-_&\v_
#These clean up the backquotes:
s_\f_\\;_g
s_\a_\\\\_g
