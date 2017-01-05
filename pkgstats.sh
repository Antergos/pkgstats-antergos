#!/bin/bash
#
#  pkgstats.sh
#
#  Copyright © 2016-2017 Antergos
#  Copyright © 2008-2016 Arch Linux
#
#  This file is part of pkgstats.
#
#  pkgstats is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
#  pkgstats is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  The following additional terms are in effect as per Section 7 of the license:
#
#  The preservation of all legal notices and author attributions in
#  the material or in the Appropriate Legal Notices displayed
#  by works containing it is required.
#
#  You should have received a copy of the GNU General Public License
#  along with pkgstats; If not, see <http://www.gnu.org/licenses/>.


export TEXTDOMAIN="PKGSTATS_ANTERGOS"

GETTEXT() {
	gettext "$@"
}

NGETTEXT() {
	ngettext "$@"
}


# Defaults
pkgstatsver='2.3'
ant_pkgstatsver='2.3.1'
showonly=false
quiet=false
option='-qsS'


# ===>>> BEGIN Translatable Strings <<<=== #

# Help Message :: Usage Header
_usage_header=$(GETTEXT 'Usage')
# Help Message :: A single command line option
_option=$(NGETTEXT 'option' 'options' 1)
# Help Message :: Multiple command line options
_options=$(NGETTEXT 'option' 'options' 5)
# Help Message :: Option :: Show Version
_show_version=$(GETTEXT 'show version')
# Help Message :: Option :: Debug Mode
_enable_debug=$(GETTEXT 'enable debug mode')
# Help Message :: Option :: Show Help
_show_help=$(GETTEXT 'show this help message')
# Help Message :: Option :: Dry Run Line 1
_show_info_1=$(GETTEXT 'show what information would be sent')
# Help Message :: Option :: Dry Run Line 2
_show_info_2=$(GETTEXT 'but do not send anything')
# Help Message :: Option :: Quiet Mode
_quiet=$(GETTEXT 'be quiet except on errors')
# Help Message :: Description Line 1
_description_1=$(GETTEXT 'pkgstats sends a list of all installed packages,')
# Help Message :: Description Line 2
_description_2=$(GETTEXT 'the architecture, and the mirror you are using')
# Help Message :: Description Line 3
_description_3=$(GETTEXT 'to the Antergos and Arch Linux projects.')
# Help Message :: Description Line 4
_description_4=$(GETTEXT 'Statistics are available at:')
# Status Message :: Collecting
_collecting_data=$(GETTEXT 'Collecting data...')
# Status Message :: Submitting
_sending_data=$(GETTEXT 'Submitting data...')
# Status Message :: Failed to send data to [Antergos/Arch]
_sending_failed=$(GETTEXT 'Sorry, data could not be sent to')
# Display Version Message
_version=$(GETTEXT 'version')
# Show Results Message :: Packages List
_results_pkgs=$(NGETTEXT 'Package' 'Packages' 5)
# Show Results Message :: Kernel Modules List
_results_modules=$(NGETTEXT 'Module' 'Modules' 5)
# Show Results Message :: Package Architecture
_results_arch=$(GETTEXT 'Package arch')
# Show Results Message :: CPU Architecture
_results_cpuarch=$(GETTEXT 'CPU arch')
# Show Results Message :: Mirror
_results_mirror=$(GETTEXT 'mirror')

# ===>>> END Translatable Strings <<<=== #


collect_stats() {
	log "${_collecting_data}"

	pkglist="$(mktemp --tmpdir pkglist.XXXXXX)"
	moduleslist="$(mktemp --tmpdir modules.XXXXXX)"
	arch="$(uname -m)"
	mirror="$(get_mirror archlinux)"
	mirror_antergos="$(get_mirror)"
	cpuarch=''

	trap 'rm -f "${pkglist}" "${moduleslist}"' EXIT
	
	pacman -Qq > "${pkglist}"

	[[ -f /proc/modules ]] && awk '{ print $1 }' /proc/modules | sort -d > "${moduleslist}"
	
	if [[ -f /proc/cpuinfo ]]; then
		{ grep -qE '^flags\s*:.*\slm\s' /proc/cpuinfo && cpuarch='x86_64'; } || cpuarch='i686'
	fi
}


get_mirror() {
	local archlinux antergos
	archlinux='s#(.*/)core/os/.*#\1#;s#(.*://).*@#\1#'
	antergos='s#(.*/)antergos/(x86_64|i686)/(.*)#\1#'

	if [[ archlinux = "$1" ]]; then
		pacman -Sddp core/pacman 2>/dev/null | sed -E "${archlinux}"
	else
		pacman -Sddp antergos/pkgstats-antergos 2>/dev/null | sed -E "${antergos}"
	fi
}


log() {
	[[ true = "${quiet}" ]] || echo "$1"
}


maybe_show_stats() {
	[[ true = "${quiet}" ]] || show_stats
	return 0
}


send_stats() {
	log "${_sending_data}"
	result=0

	for _url in 'www.archlinux.de/?page=PostPackageList' 'build.antergos.com/api/pkgstats'
	do
		curl "${option}" \
			-A "pkgstats/${pkgstatsver}" \
			--data-urlencode "packages@${pkglist}" \
			--data-urlencode "modules@${moduleslist}" \
			--data-urlencode "arch=${arch}" \
			--data-urlencode "cpuarch=${cpuarch}" \
			--data-urlencode "mirror=${mirror}" \
			--data-urlencode "quiet=${quiet}" \
			--data-urlencode "antergos=1" \
			"https://${_url}" || { log "${_sending_failed}: ${_url}" >&2 && result=1; }

		pkgstatsver="${ant_pkgstatsver}"
	done

	return "${result}"
}


show_stats() {
	cat <<-EOS
		${_results_pkgs}:

			$(sed 's/^/    /g' ${pkglist})

		${_results_modules}:

			$(sed 's/^/    /g' ${moduleslist})

		${_results_arch}: ${arch}
		${_results_cpuarch}: ${cpuarch}
		pkgstats ${_version}: ${ant_pkgstatsver}
		archlinux ${_results_mirror}: ${mirror}
		antergos ${_results_mirror}:  ${mirror_antergos}
	EOS

	[[ true = "${showonly}" ]] && exit 0

	return 0
}


show_usage() {
	cat <<- EOU
	${_usage_header}: ${0} [${_option}]

	${_options}:
	    -v  ${_show_version}
	    -d  ${_enable_debug}
	    -h  ${_show_help}
	    -s  ${_show_info_1}
	        (${_show_info_2})
	    -q  ${_quiet}

	${_description_1}
	${_description_2}
	${_description_3}

	${_description_4}:
	    https://build.antergos.com/pkgstats
	    https://www.archlinux.de/?page=Statistics
	EOU
}



while getopts vdhsq parameter
do
	case ${parameter} in
		v) echo "pkgstats, ${_version} ${pkgstatsver}"; exit 0 ;;
		d) option="${option} --trace-ascii -" ;;
		s) showonly=true ;;
		q) quiet=true ;;
		*) show_usage; exit 1 ;;
	esac
done


collect_stats && maybe_show_stats && send_stats && exit 0

exit 1

