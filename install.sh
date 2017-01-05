#!/bin/bash

pkgdir="$1"

install -D -m755 pkgstats.sh "${pkgdir}/usr/bin/pkgstats"
install -D -m644 dist/pkgstats.timer "${pkgdir}/usr/lib/systemd/system/pkgstats.timer"
install -D -m644 dist/pkgstats.service "${pkgdir}/usr/lib/systemd/system/pkgstats.service"
install -d -m755 "${pkgdir}/usr/lib/systemd/system/multi-user.target.wants"
ln -srf ../pkgstats.timer "${pkgdir}/usr/lib/systemd/system/multi-user.target.wants/pkgstats.timer"


for fpath in po/*
do
	[[ "${fpath}" = 'po/PKGSTATS_ANTERGOS.pot' ]] && continue
		
	STRING_PO=`echo ${fpath#*/}`
	STRING=`echo ${STRING_PO%.po}`
	mkdir -p "${pkgdir}/usr/share/locale/${STRING}/LC_MESSAGES"
	msgfmt "${fpath}" -o "${pkgdir}/usr/share/locale/${STRING}/LC_MESSAGES/PKGSTATS_ANTERGOS.mo"
done

