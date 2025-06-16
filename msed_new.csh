#!/usr/bin/csh
# ======================================================================
#                        開發者註記 (Developer's Note)
# ======================================================================
#
# 檔案狀態：任務範本 (Work-in-Progress)
#
# 核心任務：
# 使用 'awk' 語言，完整實作 'msed' 前處理器的所有功能。
# 目標是將帶有擴充語法（如參數化、負數行號、新命令等）的 msed
# 腳本，翻譯成標準 'sed' 可執行的指令。
#
# 具體工作：
# 完成此腳本中所有標記為 '_________' 的空白部分。這包含了位於
# csh 迴圈中的 'awk' 指令，以及在 'exit' 指令下方的主體 'awk' 腳本。
#
# 重要參考：
# 強烈建議參考 'msed' 的「sed 實作版本」（即上次的作業）。
# 該版本是本作業的功能規格書 (Functional Specification)，它完整
# 定義了在每個處理階段，輸入文字應被如何轉換。
#
# 開發策略：
# 您的任務是用 'awk' 的語法與邏輯，來重現 'sed' 版本中
# 的轉換行為。建議逐一對照 'sed' 版本的每個區塊，理解其
# 功能後，再用 'awk' 進行實作。

# 一次只專注於一個 區塊
# 每次完成一個之後都要立即使用多terminal指令測試：確保該部分功能正確無誤。
# Note: You cannot use the \(.\)\1 syntax here, because awk used extended regular expressions.
# ======================================================================


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
   #by the actual argument value. 
   cat t5 | awk '{while(match($0,/([^\\])\$'$i'/)){ $0=substr($0,1,RSTART-1) substr($0,RSTART,1) "'$argv[$i]'" substr($0,RSTART+RLENGTH); } print }' > t6
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
cat t5 | awk '{gsub(/\\\\/, "\a"); sub(/^./, ""); gsub(/\\;/, "\f"); gsub(/;/, "\n;"); print}' > t6

#Create an awk file from the part of this file below the exit:
awk 'found{print} /^exit/{found=1}' < msed > t7

#Use the awk program created on line 35, above, in order to process the file
#created on line 32 above (which, you will recall, is derived from argument 1,
#which is the msed program the user has provided):
cat t6 | awk -ft7 > t8

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
    set y = `echo $x:q | awk '{if(match($0,/\$-\\v([0-9]+)/,m))print m[1]}'`

   #So now, what if $y==a number? Well that means that we need to work out
   #what line number would match to $#-1? Set z to that line number:
   if ( X$y != X ) @ z = `cat t4 | wc -l` - $y

   #So now we take the single line $x and clean it up. The $-# will turn into
   #the number $z. Also to fix: make the branches used for "F" unique, by
   #adding a counter number to the end of whateven branch label may be in #x.
   echo $x:q | awk '{gsub(/label7/, "label7" '$cnt'); gsub(/\$-\\v[0-9]+/, '$z'); print}' >> t9

   #Increase the counter used for the branch labels on line 63, above:
   @ cnt = $cnt + 1
end

#Line 62 above created t9, the ordinary sed implementation of the original
#program the user had provided in $1. So we replace $1 with t9:
set argv[1] = -ft9

#Line 3 had captured the piped-in input into t4. So we now process it:
cat t4 | sed $*:q

#And now we are done with cshell:
exit 0
#The rest of this file is awk code (see line 35, above)
#The _________ sections below are followed by ..., because you are allowed to
#use as many lines as you want to implement these parts.
#
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
________
   .
   .
   .
________

#Now we consider ", /.../" or ", \x...x" since these can have ;
#Step 1 is to mark off the part that might go before the , by using a \v
________
   .
   .
   .
________

#Now put a \v after whatever predication may be given (including none)
________
   .
   .
   .
________

#Now deal with y and s comands that might use ";"
________
   .
   .
   .
________

#
#So now we have whole sed commands on lines. By I am adding a new part here:
#If the line uses a "{",then put what comes after the { to the next line.
#So "/x/{p"    =>  print("/x/{");$0="p"
#So "1,/x/{"   =>  print("1,/x/{");$0=""
#So "{="       =>  print("{");$0="="
#So "s{x{y{g"  =>  No change.

#Complete the lines below to handle the cases of Z, W, D, C, f, and F. This
#time I require that you not break the hold space or flags that the user's
#msed program is using. (That is: you saw how my solution on the last homework
#had logic to keep your code from breaking the hold space or the flag state;
#this homework must retain that.)
________
   .
   .
   .
________

#These add an unusual symbol ("\v", which doesn't occur in the input) to mark
#out the $-#, so that line 63 above can find them and convert them:
________
   .
   .
   .
________

#These clean up the backquotes:
________
   .
   .
   .
________

