#!/bin/bash

VERSION='2.0'
DATE=`date +%F`
LOG=STIG-for-Debian-$DATE

TEXTFILE=stig-debian-9.txt
export SUCCESS_FLAG=0
export FAIL_FLAG=0

function version() {
	echo "STIG for Debian Compliance Checking Tools(v.$VERSION)"
}

function usage() {
cat << EOF
usage: $0 [options]

  -s    Start checking and output repot in html format.
  -v    Display version
  -h    Display help

Default report is output in current directory(STIG-for-Debian-*.html)

STIG for Debian Compliance Checking Tools (v$VERSION)

Ported from DISA RHEL 7 STIG
EOF
}

if [ $# -eq 0 ];then
        usage
        exit 1
elif [ $# -gt 1 ];then
        tput setaf 1;echo -e "\033[1mERROR: Too much parameter\033[0m";tput sgr0
        echo
        usage
        exit 1
fi

while getopts ":csvhqC" OPTION; do
        case $OPTION in
                s)      
			ENABLE_HTML=1
                        ;;
                v)
                        version
                        exit 0
                        ;;
                h)
                        usage
                        exit 0
                        ;;
                ?)
                        tput setaf 1;echo -e "\033[1mERROR: Wrong parameter!\033[0m";tput sgr0
                        echo
                        usage
                        exit 1
                        ;;
        esac
done

if [[ $EUID -ne 0 ]]; then
		tput setaf 1; #Setting Output Color To Red 
		echo -e "\033[1mPlease re-run this script as root!\033[0m";
		tput sgr0 #Turn off all attributes
	exit 1
fi

RUNTIME=$(date)
printf "Script Run: $RUNTIME\nStart checking process...\n\n"

spinner(){

        local pid=$1
        local delay=0.1
        local spinstr='|/-\'
        while [ "$(ps -a | awk '{print $1}' | grep "$pid")" ]; 
        do
                local temp=${spinstr#?}
                printf "%c" "$spinstr"
                local spinstr=$temp${spinstr%"$temp"}
                sleep $delay
                printf "\b"
        done
        printf " \b"
        wait $1
}

HTML_OVERVIEW_LOG="$LOG"_overview.html

function html_overview_gen_prologue() {
        cat html/html_overview_template_head1.html > $HTML_OVERVIEW_LOG
        echo "STIG for Debian Compliance Checking $DATE" >>$HTML_OVERVIEW_LOG #HTML title
        cat html/html_overview_template_style.html >> $HTML_OVERVIEW_LOG
        cat html/html_overview_template_script.html >> $HTML_OVERVIEW_LOG
        cat html/html_overview_template_head2.html >> $HTML_OVERVIEW_LOG
        cat html/html_overview_template_body1.html >> $HTML_OVERVIEW_LOG
        echo "$DATE" >> $HTML_OVERVIEW_LOG
        cat html/html_overview_template_body2.html >> $HTML_OVERVIEW_LOG
}

function html_overview_gen_middle() {
        cat html/html_overview_template_middle.html >> $HTML_OVERVIEW_LOG
}

function html_overview_gen_epilogue() {
        cat html/html_overview_template_footer.html >> $HTML_OVERVIEW_LOG
}

function html_overview_output() {
        echo '<tr><td data-title="ID">'"$RULE_ID"'</td>' >>$HTML_OVERVIEW_LOG
        echo '<td data-title="ID">'"$RULE_TITLE"'</td>' >>$HTML_OVERVIEW_LOG
        echo '<td data-title="ID">'"$LEVEL"'</td>' >>$HTML_OVERVIEW_LOG
        echo '<td data-title="ID">'"$STATUS"'</td></tr>' >>$HTML_OVERVIEW_LOG
}

function html_overview_manual_output() {
        echo '<tr><td data-title="ID">'"$RULE_ID"'</td>' >>$HTML_OVERVIEW_LOG
        echo '<td data-title="ID">'"$RULE_TITLE"'</td>' >>$HTML_OVERVIEW_LOG
        echo '<td data-title="ID">'"$LEVEL"'</td></tr>' >>$HTML_OVERVIEW_LOG
}

HTML_DETAILS_LOG="$LOG"_details.html

function html_details_gen_prologue() {
        cat html/html_details_template_head1.html > $HTML_DETAILS_LOG
        echo "STIG for Debian Compliance Checking  $DATE" >>$HTML_DETAILS_LOG #HTML title
        cat html/html_details_template_style.html >> $HTML_DETAILS_LOG
        cat html/html_details_template_script.html >> $HTML_DETAILS_LOG
        cat html/html_details_template_head2.html >> $HTML_DETAILS_LOG
        cat html/html_details_template_body1.html >> $HTML_DETAILS_LOG
        echo "$DATE" >> $HTML_DETAILS_LOG
        cat html/html_details_template_body2.html >> $HTML_DETAILS_LOG
}

function html_details_gen_middle() {
        cat html/html_details_template_middle.html >> $HTML_DETAILS_LOG
}

function html_details_gen_epilogue() {
        cat html/html_details_template_footer.html >> $HTML_DETAILS_LOG
}

function html_details_output() {
        echo '<section><font style="font-weight:bold;">Rule Title: </font>'"$RULE_TITLE"'<br />' >>$HTML_DETAILS_LOG
        echo '<font style="font-weight:bold;">Rule ID: </font>'"$RULE_ID"'<br />'>>$HTML_DETAILS_LOG
        echo '<font style="font-weight:bold;">Status: </font>'"$STATUS"'<br />' >>$HTML_DETAILS_LOG
        echo '<font style="font-weight:bold;">Description: </font>'"$(echo "$QUESTION_DESC" | sed -e 's/\\n\\n/<br \/>/g' -e 's/\\n/<br \/>/g')"'<br />' >>$HTML_DETAILS_LOG
        echo '<font style="font-weight:bold;">Check Content: </font>'"$(echo "$CHECK_CONTENT" | sed -e 's/\\n\\n/<br \/>/g' -e 's/\\n/<br \/>/g')"'<br />' >>$HTML_DETAILS_LOG
        echo '<font style="font-weight:bold;">Fix Method: </font>'"$(echo "$FIX" | sed -e 's/\\n\\n/<br \/>/g' -e 's/\\n/<br \/>/g')"'<br /></section>' >>$HTML_DETAILS_LOG
}

function html_details_manual_output() {
        echo '<section><font style="font-weight:bold;">Rule Title: </font>'"$RULE_TITLE"'<br />' >>$HTML_DETAILS_LOG
        echo '<font style="font-weight:bold;">Rule ID: </font>'"$RULE_ID"'<br />'>>$HTML_DETAILS_LOG
        echo '<font style="font-weight:bold;">Description: </font>'"$(echo "$QUESTION_DESC" | sed -e 's/\\n\\n/<br \/>/g' -e 's/\\n/<br \/>/g')"'<br />' >>$HTML_DETAILS_LOG
        echo '<font style="font-weight:bold;">Check Content: </font>'"$(echo "$CHECK_CONTENT" | sed -e 's/\\n\\n/<br \/>/g' -e 's/\\n/<br \/>/g')"'<br />' >>$HTML_DETAILS_LOG
        echo '<font style="font-weight:bold;">Fix Method: </font>'"$(echo "$FIX" | sed -e 's/\\n\\n/<br \/>/g' -e 's/\\n/<br \/>/g')"'<br /></section>' >>$HTML_DETAILS_LOG
}

function output() {

        EXIT_STATUS=$2
        LOCATION=$(sed -n "/$1/=" $TEXTFILE)
        #output rule id
        RULE_ID=$(sed -n "$LOCATION"p "$TEXTFILE" | sed "s/Rule ID: //" )
	#output severity level
	LEVEL=$(sed -n "$((LOCATION+=1))"p "$TEXTFILE" | sed "s/Severity: //" )
        #output rule title
        RULE_TITLE=$(sed -n "$((LOCATION+=2))"p "$TEXTFILE" | sed "s/Rule Title: //")
        #output description
        QUESTION_DESC=$(sed -n "$((LOCATION+=3))"p "$TEXTFILE" | sed "s/Description: //")
        #output check content
        CHECK_CONTENT=$(sed -n "$((LOCATION+=4))"p "$TEXTFILE" | sed "s/Check_content: //")
        #output fixtext
        FIX=$(sed -n "$((LOCATION+=5))"p $TEXTFILE | sed "s/Fixtext: //")
        HTML_FIX=$(echo $FIX)

        if [ $EXIT_STATUS -eq 0 ];then
                STATUS="PASS"
                ((SUCCESS_FLAG++))
        else
                STATUS='<font color="#FE4365">FAILED</font>'
                ((FAIL_FLAG++))
        fi

        if [ $ENABLE_HTML = "1" ];then
            html_overview_output >> $HTML_OVERVIEW_LOG
            html_details_output >> $HTML_DETAILS_LOG
        fi
}

function manual_output() {

        LOCATION=$(sed -n "/$1/=" $TEXTFILE)
        #output rule id
        RULE_ID=$(sed -n "$LOCATION"p "$TEXTFILE" | sed "s/Rule ID: //" )
        #output severity level
        LEVEL=$(sed -n "$((LOCATION+=1))"p "$TEXTFILE" | sed "s/Severity: //" )
        #output rule title
        RULE_TITLE=$(sed -n "$((LOCATION+=2))"p "$TEXTFILE" | sed "s/Rule Title: //")
        #output description
        QUESTION_DESC=$(sed -n "$((LOCATION+=3))"p "$TEXTFILE" | sed "s/Description: //")
        #output check content
        CHECK_CONTENT=$(sed -n "$((LOCATION+=4))"p "$TEXTFILE" | sed "s/Check_content: //")
        #output fixtext
        FIX=$(sed -n "$((LOCATION+=5))"p $TEXTFILE | sed "s/Fixtext: //")
        HTML_FIX=$(echo $FIX)

        if [ $ENABLE_HTML = "1" ];then
            html_overview_manual_output >> $HTML_OVERVIEW_LOG
            html_details_manual_output >> $HTML_DETAILS_LOG
        fi
}



if [ $ENABLE_HTML = "1" ]; then
        html_overview_gen_prologue
        html_details_gen_prologue
fi
##########################################################################

######CAT I
bash scripts/check-package-verify.sh 2>&1 &
spinner $!
output "SV-86479r2_rule" $?


bash scripts/check-session-lock.sh >/dev/null 2>&1 &
spinner $!
output "SV-86515r2_rule" $?


bash scripts/check-screensaver-idle-delay.sh >/dev/null 2>&1 &
spinner $!
output "SV-86517r2_rule" $?


dpkg -s screen >/dev/null 2>&1 &
spinner $!
output "SV-86521r1_rule" $?


bash scripts/check-password.sh /etc/pam.d/common-password pam_pwquality.so ucredit gt 1 >/dev/null 2>&1 &
spinner $!
output "SV-86527r2_rule" $?


bash scripts/check-password.sh /etc/pam.d/common-password pam_pwquality.so lcredit gt 1 >/dev/null 2>&1 &
spinner $!
output "SV-86529r2_rule" $?


bash scripts/check-password.sh /etc/pam.d/common-password pam_pwquality.so dcredit gt 1 >/dev/null 2>&1 &
spinner $!
output "SV-86531r2_rule" $?


bash scripts/check-password.sh /etc/pam.d/common-password pam_pwquality.so ocredit gt 1 >/dev/null 2>&1 &
spinner $!
output "SV-86533r1_rule" $?


bash scripts/check-password.sh /etc/pam.d/common-password pam_pwquality.so difok ge 8 >/dev/null 2>&1 &
spinner $!
output "SV-86535r1_rule" $?


bash scripts/check-password.sh /etc/pam.d/common-password pam_pwquality.so minclass ge 4 >/dev/null 2>&1 &
spinner $!
output "SV-86537r1_rule" $?


bash scripts/check-password.sh /etc/pam.d/common-password pam_pwquality.so maxrepeat le 2 >/dev/null 2>&1 &
spinner $!
output "SV-86539r1_rule" $?


bash scripts/check-password.sh /etc/pam.d/common-password pam_pwquality.so maxclassrepeat le 4 >/dev/null 2>&1 &
spinner $!
output "SV-86541r1_rule" $?


sed -e '/^#/d' -e '/^[ \t][ \t]*#/d' -e 's/#.*$//' -e '/^$/d' /etc/pam.d/* | grep password | grep pam_unix.so | grep sha512 > /dev/null 2>&1 &
spinner $!
output "SV-86543r1_rule" $?


grep -i encrypt /etc/login.defs | grep -v '^#' | grep SHA512 >/dev/null 2>&1 &
spinner $!
output "SV-86545r1_rule" $?


bash scripts/check-password-newuser-minday.sh 1 >/dev/null 2>&1 &
spinner $!
output "SV-86549r1_rule" $?


bash scripts/check-password-min-day.sh 1 >/dev/null 2>&1 &
spinner $!
output "SV-86551r1_rule" $?


bash scripts/check-password-max-day-4-newuser.sh 60 >/dev/null 2>&1 &
spinner $!
output "SV-86553r1_rule" $?


bash scripts/check-password-max-day-4-existing.sh 60 >/dev/null 2>&1 &
spinner $!
output "SV-86555r1_rule" $?


bash scripts/check-password.sh /etc/pam.d/common-password pam_unix.so remember ge 5 >/dev/null 2>&1 &
spinner $!
output "SV-86557r1_rule" $?


bash scripts/check-password.sh /etc/pam.d/common-password pam_pwquality.so minlen ge 15 >/dev/null 2>&1 &
spinner $!
output "SV-86559r1_rule" $?


bash scripts/check-nullok.sh >/dev/null 2>&1 &
spinner $!
output "SV-86561r1_rule" $?


bash scripts/check-ssh.sh emptypassword >/dev/null 2>&1 &
spinner $!
output "SV-86563r2_rule" $?


bash scripts/check-inactive.sh 0 >/dev/null 2>&1 &
spinner $!
output "SV-86565r1_rule" $?


bash scripts/check-inactive.sh 0 >/dev/null 2>&1 &
spinner $!
output "SV-86565r1_rule" $?


bash scripts/check-deny-and-locktime.sh 0 >/dev/null 2>&1 &
spinner $!
output "SV-86567r2_rule" $?


bash scripts/check-privilege-escalation.sh sudo >/dev/null 2>&1 &
spinner $!
output "SV-86571r1_rule" $?


bash scripts/check-privilege-escalation.sh authentication >/dev/null 2>&1 &
spinner $!
output "SV-86573r2_rule" $?


bash scripts/check-password-fail-delay.sh 4 >/dev/null 2>&1 &
spinner $!
output "SV-86575r1_rule" $?


bash scripts/check-ssh.sh emptypasswordenvironment >/dev/null 2>&1 &
spinner $!
output "SV-86581r2_rule" $?


bash scripts/check-ssh.sh hostauth >/dev/null 2>&1 &
spinner $!
output "SV-86583r2_rule" $?


bash scripts/check-packages.sh rsh-server >/dev/null 2>&1 &
spinner $!
output "SV-86591r1_rule" $?


bash scripts/check-packages.sh ypserv >/dev/null 2>&1 &
spinner $!
output "SV-86593r1_rule" $?


bash scripts/check-ctrl-alt-del.sh >/dev/null 2>&1 &
spinner $!
output "SV-86617r1_rule" $?


bash scripts/check-gids.sh >/dev/null 2>&1 &
spinner $!
output "SV-86627r1_rule" $?


bash scripts/check-root-uid.sh >/dev/null 2>&1 &
spinner $!
output "SV-86629r1_rule" $?


bash scripts/check-valid-owner.sh >/dev/null 2>&1 &
spinner $!
output "SV-86631r1_rule" $?


bash scripts/check-valid-group-owner.sh >/dev/null 2>&1 &
spinner $!
output "SV-86633r1_rule" $?


bash scripts/check-homedir-assigned.sh >/dev/null 2>&1 &
spinner $!
output "SV-86635r1_rule" $?


bash scripts/check-create-home.sh >/dev/null 2>&1 &
spinner $!
output "SV-86637r1_rule" $?


bash scripts/check-homedir-exist.sh >/dev/null 2>&1 &
spinner $!
output "SV-86639r1_rule" $?


bash scripts/check-homedir-permissive.sh >/dev/null 2>&1 &
spinner $!
output "SV-86641r1_rule" $?


bash scripts/check-homedir-owner.sh >/dev/null 2>&1 &
spinner $!
output "SV-86643r2_rule" $?


bash scripts/check-homedir-gowner.sh >/dev/null 2>&1 &
spinner $!
output "SV-86645r2_rule" $?


bash scripts/check-homedir-files-owner.sh >/dev/null 2>&1 &
spinner $!
output "SV-86647r1_rule" $?


bash scripts/check-homedir-files-gowner.sh >/dev/null 2>&1 &
spinner $!
output "SV-86649r1_rule" $?


bash scripts/check-homedir-files-permissive.sh >/dev/null 2>&1 &
spinner $!
output "SV-86651r1_rule" $?


bash scripts/check-homedir-initfiles-owner.sh >/dev/null 2>&1 &
spinner $!
output "SV-86653r1_rule" $?


bash scripts/check-homedir-initfiles-gowner.sh >/dev/null 2>&1 &
spinner $!
output "SV-86655r2_rule" $?


bash scripts/check-homedir-initfiles-permissive.sh >/dev/null 2>&1 &
spinner $!
output "SV-86657r1_rule" $?


bash scripts/check-homedir-to-exec-path.sh >/dev/null 2>&1 &
spinner $!
output "SV-86659r2_rule" $?


bash scripts/check-homedir-initfiles-world-writable.sh >/dev/null 2>&1 &
spinner $!
output "SV-86661r1_rule" $?


bash scripts/check-mount-option.sh home nosuid >/dev/null 2>&1 &
spinner $!
output "SV-86665r2_rule" $?


bash scripts/check-mount-option.sh media nosuid >/dev/null 2>&1 &
spinner $!
output "SV-86667r1_rule" $?


bash scripts/check-mount-option.sh nfs nosuid >/dev/null 2>&1 &
spinner $!
output "SV-86669r1_rule" $?


bash scripts/check-world-writable-dir-gowner.sh >/dev/null 2>&1 &
spinner $!
output "SV-86671r1_rule" $?


bash scripts/check-homedir-initfiles-umask.sh >/dev/null 2>&1 &
spinner $!
output "SV-86673r1_rule" $?


bash bash scripts/check-limits.sh core-dumps >/dev/null 2>&1 &
spinner $!
output "SV-86681r1_rule" $?


mount | grep "on./home.type" >/dev/null 2>&1 &
spinner $!
output "SV-86683r1_rule" $?


mount | grep "on./var.type" >/dev/null 2>&1 &
spinner $!
output "SV-86685r1_rule" $?


mount | grep "on./var/log/audit.type" >/dev/null 2>&1 &
spinner $!
output "SV-86687r3_rule" $?


mount | grep "on./tmp.type" >/dev/null 2>&1 &
spinner $!
output "SV-86689r1_rule" $?


bash scripts/check-fips_enabled.sh >/dev/null 2>&1 &
spinner $!
output "SV-86691r2_rule" $?


bash scripts/check-aide.sh acl >/dev/null 2>&1 &
spinner $!
output "SV-86693r2_rule" $?


bash scripts/check-aide.sh sha512 >/dev/null 2>&1 &
spinner $!
output "SV-86697r2_rule" $?


bash scripts/check-grub.sh >/dev/null 2>&1 &
spinner $!
output "SV-86699r1_rule" $?


bash scripts/check-packages.sh telnetd >/dev/null 2>&1 &
spinner $!
output "SV-86701r1_rule" $?


bash scripts/check-auditd.sh  active >/dev/null 2>&1 &
spinner $!
output "SV-86703r1_rule" $?


bash scripts/check-auditd.sh enableflag >/dev/null 2>&1 &
spinner $!
output "SV-86705r1_rule" $?


bash scripts/check-auditd.sh remote_server >/dev/null 2>&1 &
spinner $!
output "SV-86707r1_rule" $?


bash scripts/check-auditd.sh enable_krb5 >/dev/null 2>&1 &
spinner $!
output "SV-86709r1_rule" $?


bash scripts/check-auditd.sh disk_full_error_action >/dev/null 2>&1 &
spinner $!
output "SV-86711r2_rule" $?


bash scripts/check-auditd.sh space_left >/dev/null 2>&1 &
spinner $!
output "SV-86713r1_rule" $?


bash scripts/check-auditd.sh space_left_action >/dev/null 2>&1 &
spinner $!
output "SV-86715r1_rule" $?


bash scripts/check-auditd.sh action_mail_acct >/dev/null 2>&1 &
spinner $!
output "SV-86717r2_rule" $?


bash scripts/check-auditd-syscall.sh chown >/dev/null 2>&1 &
spinner $!
output "SV-86721r2_rule" $?


bash scripts/check-auditd-syscall.sh fchown >/dev/null 2>&1 &
spinner $!
output "SV-86723r2_rule" $?


bash scripts/check-auditd-syscall.sh lchown >/dev/null 2>&1 &
spinner $!
output "SV-86725r2_rule" $?


bash scripts/check-auditd-syscall.sh fchownat >/dev/null 2>&1 &
spinner $!
output "SV-86727r2_rule" $?


bash scripts/check-auditd-syscall.sh chmod >/dev/null 2>&1 &
spinner $!
output "SV-86729r2_rule" $?


bash scripts/check-auditd-syscall.sh fchmod >/dev/null 2>&1 &
spinner $!
output "SV-86731r2_rule" $?


bash scripts/check-auditd-syscall.sh fchmodat >/dev/null 2>&1 &
spinner $!
output "SV-86733r2_rule" $?


bash scripts/check-auditd-syscall.sh setxattr >/dev/null 2>&1 &
spinner $!
output "SV-86735r2_rule" $?


bash scripts/check-auditd-syscall.sh fsetxattr >/dev/null 2>&1 &
spinner $!
output "SV-86737r2_rule" $?


bash scripts/check-auditd-syscall.sh lsetxattr >/dev/null 2>&1 &
spinner $!
output "SV-86739r2_rule" $?


bash scripts/check-auditd-syscall.sh removexattr >/dev/null 2>&1 &
spinner $!
output "SV-86741r2_rule" $?


bash scripts/check-auditd-syscall.sh fremovexattr >/dev/null 2>&1 &
spinner $!
output "SV-86743r2_rule" $?


bash scripts/check-auditd-syscall.sh lremovexattr >/dev/null 2>&1 &
spinner $!
output "SV-86745r2_rule" $?


bash scripts/check-auditd-syscall.sh creat >/dev/null 2>&1 &
spinner $!
output "SV-86747r2_rule" $?


bash scripts/check-auditd-syscall.sh open >/dev/null 2>&1 &
spinner $!
output "SV-86749r2_rule" $?


bash scripts/check-auditd-syscall.sh openat >/dev/null 2>&1 &
spinner $!
output "SV-86751r2_rule" $?


bash scripts/check-auditd-syscall.sh open_by_handle_at >/dev/null 2>&1 &
spinner $!
output "SV-86753r2_rule" $?


bash scripts/check-auditd-syscall.sh truncate >/dev/null 2>&1 &
spinner $!
output "SV-86755r2_rule" $?


bash scripts/check-auditd-syscall.sh ftruncate >/dev/null 2>&1 &
spinner $!
output "SV-86757r2_rule" $?


bash scripts/check-auditd.sh tallylog >/dev/null 2>&1 &
spinner $!
output "SV-86767r2_rule" $?


bash scripts/check-auditd.sh faillock >/dev/null 2>&1 &
spinner $!
output "SV-86769r2_rule" $?


bash scripts/check-auditd.sh lastlog >/dev/null 2>&1 &
spinner $!
output "SV-86771r2_rule" $?


bash scripts/check-auditd.sh passwd >/dev/null 2>&1 &
spinner $!
output "SV-86773r3_rule" $?


bash scripts/check-auditd.sh unix_chkpwd >/dev/null 2>&1 &
spinner $!
output "SV-86775r3_rule" $?


bash scripts/check-auditd.sh gpasswd >/dev/null 2>&1 &
spinner $!
output "SV-86777r3_rule" $?


bash scripts/check-auditd.sh chage >/dev/null 2>&1 &
spinner $!
output "SV-86779r3_rule" $?


bash scripts/check-auditd.sh su >/dev/null 2>&1 &
spinner $!
output "SV-86783r3_rule" $?


bash scripts/check-auditd.sh sudo >/dev/null 2>&1 &
spinner $!
output "SV-86785r3_rule" $?


bash scripts/check-auditd.sh f-sudoers >/dev/null 2>&1 &
spinner $!
output "SV-86787r3_rule" $?


bash scripts/check-auditd.sh newgrp >/dev/null 2>&1 &
spinner $!
output "SV-86789r3_rule" $?


bash scripts/check-auditd.sh chsh >/dev/null 2>&1 &
spinner $!
output "SV-86791r3_rule" $?


bash scripts/check-auditd.sh sudoedit >/dev/null 2>&1 &
spinner $!
output "SV-86793r3_rule" $?


bash scripts/check-auditd.sh mount >/dev/null 2>&1 &
spinner $!
output "SV-86795r3_rule" $?


bash scripts/check-auditd.sh umount >/dev/null 2>&1 &
spinner $!
output "SV-86797r3_rule" $?


bash scripts/check-auditd.sh postdrop >/dev/null 2>&1 &
spinner $!
output "SV-86799r3_rule" $?


bash scripts/check-auditd.sh postqueue >/dev/null 2>&1 &
spinner $!
output "SV-86801r2_rule" $?


bash scripts/check-auditd.sh crontab >/dev/null 2>&1 &
spinner $!
output "SV-86807r2_rule" $?


bash scripts/check-auditd.sh pam_timestamp_check >/dev/null 2>&1 &
spinner $!
output "SV-86809r2_rule" $?


bash scripts/check-auditd-syscall.sh init_module >/dev/null 2>&1 &
spinner $!
output "SV-86811r2_rule" $?


bash scripts/check-auditd-syscall.sh delete_module >/dev/null 2>&1 &
spinner $!
output "SV-86813r2_rule" $?


bash scripts/check-auditd.sh insmod >/dev/null 2>&1 &
spinner $!
output "SV-86815r2_rule" $?


bash scripts/check-auditd.sh rmmod >/dev/null 2>&1 &
spinner $!
output "SV-86817r2_rule" $?


bash scripts/check-auditd.sh modprobe >/dev/null 2>&1 &
spinner $!
output "SV-86819r2_rule" $?


bash scripts/check-auditd.sh f-passwd >/dev/null 2>&1 &
spinner $!
output "SV-86821r3_rule" $?


bash scripts/check-auditd-syscall.sh rename >/dev/null 2>&1 &
spinner $!
output "SV-86823r2_rule" $?


bash scripts/check-auditd-syscall.sh renameat >/dev/null 2>&1 &
spinner $!
output "SV-86825r2_rule" $?


bash scripts/check-auditd-syscall.sh rmdir >/dev/null 2>&1 &
spinner $!
output "SV-86827r2_rule" $?


bash scripts/check-auditd-syscall.sh unlink >/dev/null 2>&1 &
spinner $!
output "SV-86829r2_rule" $?


bash scripts/check-auditd-syscall.sh unlinkat >/dev/null 2>&1 &
spinner $!
output "SV-86831r2_rule" $?


bash bash scripts/check-limits.sh maxlogins >/dev/null 2>&1 &
spinner $!
output "SV-86841r1_rule" $?


######CAT II

######CAT III

##########################################################################

if [ $ENABLE_HTML = "1" ];then
        html_overview_gen_middle        html_details_gen_middle
fi

#####Manual checking

cat manual.txt | while read line;do
        manual_output "$line"
done


if [ $ENABLE_HTML = "1" ];then
        html_overview_gen_epilogue
        html_details_gen_epilogue
fi

#####Statistics

sed -i -e "s/Pass count/Pass count: $SUCCESS_FLAG/" -e "s/Failed count/Failed count: $FAIL_FLAG/" STIG-for-Debian-$DATE_*.html
