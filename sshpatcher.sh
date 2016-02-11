#!/bin/bash
#          #############################################
#            openssh tampered package detection script 
#          #############################################
#
#                                        Red Hat, Inc.   August, 2008
#
# This script can be executed to detect whether a package on the local
# system matches one of the tampered OpenSSH packages which were
# signed using the Red Hat signing key.
#
# Please see https://www.redhat.com/security/data/openssh-blacklist.html
#
# This bash script can be executed as a non-root user, or as root.  To
# execute the script after downloading it, run the command:
#
#     $ bash ./openssh-blacklist-1.0.sh
#
# If the script output includes any lines beginning with "ALERT" then
# a malicious package has been found on the system.  Otherwise, if no
# suspect packages were found, the script should produce only a single
# line of output beginning with the word "PASS".
#
# Alternatively, the script can be passed a list of RPM filenames:
#
#     $ bash ./openssh-blacklist-1.0.sh some.i386.rpm other.src.rpm
#
# the signature of each RPM (binary or source) will be checked against
# the blacklist and a "PASS" or "ALERT" message issued accordingly.
#
# The signed tampered packages were:
#
# openssh-3.9p1-8.RHEL4.24 for i386, x86_64 architecture
# openssh-3.9p1-9.el4 for i386, x86_64 architecture
# openssh-4.3p2-26 for x86_64 architecture
# openssh-4.3p2-26.el5 for x86_64 architecture
#
### Ends.

export LANG=C
unset LC_MESSAGES LC_CTYPE

# List of package and subpackage names affected:
packages=(
    openssh openssh-askpass openssh-askpass-gnome openssh-clients
    openssh-debuginfo openssh-server
)

# List of the SIGMD5 hashes of tampered packages (the SIGMD5 hash uniquely identifies a 
# particular package)
sigmd5s=(
    00b6c24146eb6222ec58342841ee31b1 021d1401b2882d864037da406e7b3bd1
    035253874639a1ebf3291189f027a561 08daefebf2a511852c88ed788717a148
    177b1013dc0692c16e69c5c779b74fcf 24c67508c480e25b2d8b02c75818efad
    27ed27c7eac779f43e7d69378a20034f 2a2f907c8d6961cc8bfbc146970c37e2
    2b0a85e1211ba739904654a7c64a4c90 2df270976cbbbbb05dbdf95473914241
    2ff426e48190519b1710ed23a379bbee 322cddd04ee5b7b8833615d3fbbcf553
    35b050b131dab0853f11111b5afca8b3 38f67a6ce63853ad337614dbd760b0db
    3b9e24c54dddfd1f54e33c6cdc90f45c 3fa1a1b446feb337fd7f4a7938a6385f
    41741fe3c73d919c3758bf78efc437c9 432b94026da05d6b11604a00856a17b2
    54bd06ebf5125debe0932b2f1f5f1c39 57f7e73ee28ba0cbbaad1a0a63388e4c
    59ad9703362991d8eff9d138351b37ac 71ef43e0d9bfdfada39b4cb778b69959
    760040ec4db1d16e878016489703ec6d 89892d38e3ccf667e7de545ea04fa05b
    8a65c4e7b8cd7e11b9f05264ed4c377b 8bf3baa4ffec125206c3ff308027a0c4
    982cd133ba95f2db580c67b3ff27cfde 990d27b6140d960ad1efd1edd5ec6898
    9bef2d9c4c581996129bd9d4b82faafa 9c90432084937eac6da3d5266d284207
    a1dea643f8b0bda52e3b6cad3f7c5eb6 b54197ff333a2c21d0ca3a5713300071
    b92ccd4cbd68b3d3cefccee3ed9b612c bb1905f7994937825cb9693ec175d4d5
    bc6b8b246be3f3f0a25dd8333ad3456b c0aff0b45ee7103de53348fcbedaf72e
    c7d520faab2673b66a13e58e0346021d ce97e8c02c146c8b1075aad1550b1554
    d19ae2199662e90ec897c8f753816ee0 de61e6e1afd2ca32679ff78a2c3a0767
    dfbc24a871599af214cd7ef72e3ef867 f68d010c6e54f3f8a973583339588262
    fc814c0e28b674da8afcfbdeecd1e18e 
)

# Set up MD5_xxx=1 for each bogus sigmd5, using the environment as a
# convenient hash table:
for md5 in ${sigmd5s[*]}; do
    eval MD5_${md5}=1
done

retval=0

# If any arguments given, treat as a list of package files to check:
if [ $# -ge 1 ]; then
    # First determine whether RPM knows --nosignature/manifest, to
    # avoid unnecessary warnings on stderr and parsing of non-RPM
    # files as manifest lists.
    if rpm --help | grep -q -- --nomanifest; then
	RPM="rpm --nosignature --nomanifest"
    elif rpm --help | grep -q -- --nosignature; then
	RPM="rpm --nosignature"
    else
	RPM="rpm"
    fi
    for pkg; do	
        # Check whether the package's sigmd5 matches one of the known bad signatures:
	md5=`$RPM --qf "%{SIGMD5}" -qp "${pkg}"`
	if test $? -ne 0; then
	    echo "WARNING: could not determine signature for package \"$pkg\""
	    continue
        fi
	eval match=\${MD5_${md5}:-0}
	if test ${match} -eq 1; then
	    echo "ALERT: package \"$pkg\" has bad signature ${md5}"
	    retval=1
	else
	    echo "PASS: signature of package \"$pkg\" not on blacklist"
	fi
    done
else
    # Otherwise, check each package on the default list:
    for md5 in `rpm -q --qf "%{SIGMD5}\n" ${packages[*]} | grep -v 'not installed'`; do
        # Check whether the package's sigmd5 matches one of the known bad signatures:
        eval match=\${MD5_${md5}:-0}
        if test ${match} -eq 1; then
            # And give a warning if it does:
	    package=`rpm -q --qf "%{NAME} %{SIGMD5}\n" ${packages[*]} | grep ${md5}`
	    echo "ALERT: suspect package ${package// */} found with bad signature ${md5}"
	    retval=1
	fi
    done

    if test ${retval} -eq 0; then
	echo "PASS: no suspect packages were found on this system"
    fi
fi

exit ${retval}
