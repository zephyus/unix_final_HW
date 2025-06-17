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

#If the first argument is "-", it means the msed program comes from
#standard input rather than a real file.  In that case copy the
#already-saved input (t4) to t5 and shift the argument list so that
#$argv[1] always holds the script source.  Otherwise store the first
#argument in t5 with a leading space to simplify later processing.
if ( "$argv[1]" == "-" ) then
    cp t4 t5
    shift argv
else
    echo \ $1:q > t5
    shift argv
endif

set nonomatch
set noglob

#Loop through all of the passed-in arguments except for the first argument:
if ( $#argv >= 1 ) then
@ i = $#argv
while ( $i >= 1 )
   #Within the t5 file, iteratively look for the $2, then the $3, etc.
   #If you find a match, create a new file t6, where the argument is replaced
   #by the actual argument value. 
   set rep = "$argv[$i]"
   set rep = `printf "%s" "$rep" | sed 's/[\\&]/\\\\&/g'`
    cat t5 | awk -v rep="$rep" -v idx="$i" '{pat="(^|[^\\\\])\\$" idx; while(match($0,pat,m)){pre=substr($0,1,RSTART-1); post=substr($0,RSTART+RLENGTH); $0=pre m[1] rep post} print}' > t6
   #Now move t6 back to t5, so that we are ready to set up the next argument.
   mv t6 t5
   #Since we're done processing this argument, remove it from argv, but not if
   #it's a flag that starts with a "-" (but remember that Cshell if-conditions
   #have a problem to overcome, when testing things that start with a "-").
   if ( X$argv[$i] !~ "X-*" ) set argv[$i] = ""
   @ i--
end
endif

#Now we want to use almost every ";" into a line separation.
#   A line separator? Yes: The ";" becomes "\n;"
#   Almost every? Yes: because we DON'T want to do it for "\;". (See footnote
#   3 in the README file for more info on our strategy in handling backquoting
#   and also its limitations.)
#We also want to get rid of the space added by line 8, above:
#And we want to prevent any "\" that is itself backquoted (\\) from being used
#to backquote anything else. This is handled by turning them into "\a"s. 
cat t5 | awk '{gsub(/\\\\\\;/, "\b"); gsub(/\\\\;/, "\f"); gsub(/\\\\/, "\a"); if(NR==1) sub(/^ /, ""); gsub(/;/, "\n;"); gsub(/\b/, "\\\\;"); gsub(/\f/, "\\;" ); print}' > t6

#Create an awk file from the part of this file below the exit:
awk '/^# *The rest of this file is awk code/{f=1;next} f' < $0:q > t7

#Use the awk program created on line 35, above, in order to process the file
#created on line 32 above (which, you will recall, is derived from argument 1,
#which is the msed program the user has provided):
cat t6 | awk -ft7 > t8

#Here are some initializations to set up the foreach loop that will follow:
rm -f t9
@ total_lines = `cat t4 | wc -l`

#Go through the version of sed commands stored in t8 (created from Line 40
#above), to see if any of the commands used a $-# syntax:
cat t8 | awk -v tot="$total_lines" '{while (match($0, /\$-\v([0-9]+)/, m)) {off=m[1]; sub("\\$-\\v" m[1], tot - off)} print}' > t9

#Line 62 above created t9, the ordinary sed implementation of the original
#program the user had provided in $1. So we replace $1 with t9:
if ( $#argv >= 1 ) then
    set argv[1] = -ft9
else
    set argv = ( -ft9 )
endif

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
{
    if ($0 ~ /^[\\/]/) {
        delim = substr($0,1,1) == "\\" ? substr($0,2,1) : "/"
        tmp = $0
        delim_esc = delim
        if (delim_esc ~ /[.\^$*+?()[{\\|]/)
            delim_esc = "\\" delim_esc
        split(tmp, arr, delim_esc)
        cnt = length(arr)-1
        while (cnt < 2) {
            if (getline nxt > 0) {
                if (nxt ~ /^;/)
                    $0 = $0 nxt
                else
                    $0 = $0 ";" nxt
                tmp = $0
                delim_esc = delim
                if (delim_esc ~ /[.\^$*+?()[{\\|]/)
                    delim_esc = "\\" delim_esc
                split(tmp, arr, delim_esc)
                cnt = length(arr)-1
            } else
                break
        }
    }
}

#Now we consider ", /.../" or ", \x...x" since these can have ;
#Step 1 is to mark off the part that might go before the , by using a \v
{
    if ($0 ~ /^\/.*\/[ \t]*/) sub(/^\/.*\/[ \t]*/, "&\\v")
    if ($0 ~ /^\\/) {
        d = substr($0,2,1)
        if (match($0, "^\\" d ".*" d "[ \t]*"))
            $0 = substr($0,1,RLENGTH) "\\\\v" substr($0,RLENGTH+1)
    }
    if ($0 ~ /^[0-9]+[ \t]*/) sub(/^[0-9]+[ \t]*/, "&\\v")
    if ($0 ~ /^\$[ \t]*/) sub(/^\$[ \t]*/, "&\\v")

    if ($0 ~ /\\v, *[\\/]/) {
        pos = index($0, ",")
        rest = substr($0, pos+1)
        gsub(/^ */, "", rest)
        delim = substr(rest,1,1)
        tmp = rest
        delim_esc = delim
        if (delim_esc ~ /[.\^$*+?()[{\\|]/)
            delim_esc = "\\" delim_esc
        split(tmp, arr, delim_esc)
        cnt = length(arr)-1
        while (cnt < 2) {
            if (getline nxt > 0) {
                if (nxt ~ /^;/)
                    $0 = $0 nxt
                else
                    $0 = $0 ";" nxt
                rest = substr($0, pos+1)
                gsub(/^ */, "", rest)
                tmp = rest
                delim_esc = delim
                if (delim_esc ~ /[.\^$*+?()[{\\|]/)
                    delim_esc = "\\" delim_esc
                split(tmp, arr, delim_esc)
                cnt = length(arr)-1
            } else
                break
        }
    }
}

#Now put a \v after whatever predication may be given (including none)
{
    if (match($0, /\\v(, *\/.*\/ *)/)) {
        pre = substr($0, 1, RSTART - 1)
        mid = substr($0, RSTART + 2, RLENGTH - 2)
        post = substr($0, RSTART + RLENGTH)
        $0 = pre mid "\\v" post
    } else if (match($0, /\\v, *\\(.)/, m)) {
        d = m[1]
        pat = "\\\\v(, *\\\\" d "[^" d "]*" d " *)"
        if (match($0, pat)) {
            pre = substr($0, 1, RSTART - 1)
            mid = substr($0, RSTART + 2, RLENGTH - 2)
            post = substr($0, RSTART + RLENGTH)
            $0 = pre mid "\\v" post
        }
    } else if (match($0, /\\v(, *[0-9]+ *)/)) {
        pre = substr($0, 1, RSTART - 1)
        mid = substr($0, RSTART + 2, RLENGTH - 2)
        post = substr($0, RSTART + RLENGTH)
        $0 = pre mid "\\v" post
    } else if (match($0, /\\v(, *\$ *)/)) {
        pre = substr($0, 1, RSTART - 1)
        mid = substr($0, RSTART + 2, RLENGTH - 2)
        post = substr($0, RSTART + RLENGTH)
        $0 = pre mid "\\v" post
    }
    if ($0 !~ /\\v/)
        sub(/^ */, "&\\v")
}

#Now deal with y and s comands that might use ";"
{
    if ($0 ~ /^\\v[ys]/) {
        delim = substr($0,3,1)
        pattern = "^\\v[ys]" delim ".*" delim ".*" delim
        while ($0 !~ pattern) {
            if (getline nxt > 0)
                if (nxt ~ /^;/)
                    $0 = $0 nxt
                else
                    $0 = $0 ";" nxt
            else
                break
        }
    }
    sub(/^;/, "")
    sub(/\\v/, "")
    sub(/^;/, "")
}

#
#So now we have whole sed commands on lines. By I am adding a new part here:
#If the line uses a "{",then put what comes after the { to the next line.
#So "/x/{p"    =>  print("/x/{");$0="p"
#So "1,/x/{"   =>  print("1,/x/{");$0=""
#So "{="       =>  print("{");$0="="
#So "s{x{y{g"  =>  No change.

{
    if ($0 ~ /\{/ && $0 !~ /^s\{/) {
        pos = index($0, "{")
        print substr($0, 1, pos)
        $0 = substr($0, pos+1)
    }
}

#Simple translations for the new commands Z, W, D, C, f, and F:
{
    if (sub(/^[[:space:]]*Z/, "s/.*//")) {
        split(guard_block(), gb, "\n")
        print rename_labels(gb[1])
        print rename_labels($0)
        print rename_labels(gb[2])
        next
    }
    if (sub(/^[[:space:]]*W/, "s/.*//;g;s/.*//;G")) {
        split(guard_block(), gb, "\n")
        print rename_labels(gb[1])
        print rename_labels($0)
        print rename_labels(gb[2])
        next
    }
    if ($0 ~ /^[[:space:]]*D([[:space:]]|$)/) {
        split(guard_block(), gb, "\n")
        print rename_labels(gb[1])
        sub(/^[[:space:]]*D[ \t]*/, "")
        $0 = "x; s/.*//; x; d"
        print rename_labels($0)
        print rename_labels(gb[2])
        next
    }
    if ($0 ~ /^[[:space:]]*C([[:space:]]|$)/) {
        split(guard_block(), gb, "\n")
        print rename_labels(gb[1])
        sub(/^[[:space:]]*C[ \t]*/, "")
        $0 = "H; x; s/\\r\\v$//; x"
        print rename_labels($0)
        print rename_labels(gb[2])
        next
    }
    if (match($0, /^[[:space:]]*f[ \t]+([A-Za-z0-9_]+)/, m)) {
        lbl = m[1]
        sub(/^[[:space:]]*f[ \t]+[A-Za-z0-9_]+/, "x; /\\r\\v$/!b " lbl "; x")
    } else if (match($0, /^[[:space:]]*F[ \t]+([A-Za-z0-9_]+)/, m)) {
        orig = m[1]
        lbl = orig "_" fcnt
        fmap[orig] = lbl
        sub(/^[[:space:]]*F[ \t]+[A-Za-z0-9_]+/, "x; /\\r\\v$/b " lbl "; x")
        fcnt++
    }
}

#These add an unusual symbol ("\v", which doesn't occur in the input) to mark
#out the $-#, so that line 63 above can find them and convert them:
{
    while (match($0, /\$-([0-9]+)/, m))
        $0 = substr($0, 1, RSTART+1) "\v" m[1] substr($0, RSTART + RLENGTH)
}

#These clean up the backquotes:
BEGIN {
    flcnt=0
    fcnt=0
    split("", fmap)
}

function guard_block(  plabel, elabel, pre, post) {
    flcnt++
    plabel="flagL" flcnt "_a"
    elabel="flagL" flcnt "_b"
    pre="T" plabel "; x; s/$/\\r\\v/; x; :" plabel
    post="T" elabel "; :" elabel "; x; s/\\r\\v$//; x"
    return pre "\n" post
}

function rename_labels(line,    k, mat, pre, post, cmd, ws) {
    for (k in fmap) {
        while (match(line, ":" k "([^A-Za-z0-9_]|$)", mat)) {
            pre  = substr(line, 1, RSTART-1)
            post = substr(line, RSTART+RLENGTH)
            line = pre ":" fmap[k] mat[1] post
        }
        while (match(line, "([bBtT])([ \t]*)" k "([^A-Za-z0-9_]|$)", mat)) {
            pre  = substr(line, 1, RSTART-1)
            post = substr(line, RSTART+RLENGTH)
            cmd = mat[1]
            ws  = mat[2]
            line = pre cmd ws fmap[k] mat[3] post
        }
    }
    return line
}

{
    gsub(/\b/, "\\\\;")
    gsub(/\f/, "\\;")
    gsub(/\a/, "\\\\")
    n = split($0, lines, "\n")
    for (i = 1; i <= n; i++) {
        line = lines[i]
        trimmed = line
        sub(/^[ \t]*/, "", trimmed)
        if (trimmed ~ /(^|[ ,0-9$\/\\])s[ \t]*[^0-9A-Za-z]/ ||
            trimmed ~ /(^|[ ,0-9$\/\\])y[ \t]*[^0-9A-Za-z]/) {
            split(guard_block(), gb, "\n")
            print rename_labels(gb[1])
            print rename_labels(line)
            print rename_labels(gb[2])
        } else {
            print rename_labels(line)
        }
    }
}

