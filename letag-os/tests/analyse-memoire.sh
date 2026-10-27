#!/bin/sh
# Analyse détaillée de la mémoire (administrateur) : /proc/meminfo et PSS
# (part réelle de chaque processus, bibliothèques partagées réparties).
echo "=== meminfo"; grep -E '^(MemTotal|MemFree|MemAvailable|Buffers|Cached|SwapCached|Active\(anon\)|Inactive\(anon\)|AnonPages|Mapped|Shmem|KReclaimable|Slab|SUnreclaim|KernelStack|PageTables|Percpu|Unevictable|Mlocked|SwapTotal|SwapFree|Zswap|HugePages_Total)' /proc/meminfo
echo "=== PSS par programme (Mo)"
for p in /proc/[0-9]*; do
	n=$(cat $p/comm 2>/dev/null) || continue
	v=$(awk '/^Pss:/ {print $2}' $p/smaps_rollup 2>/dev/null)
	a=$(awk '/^Pss_Anon:/ {print $2}' $p/smaps_rollup 2>/dev/null)
	[ -n "$v" ] && echo "$n $v ${a:-0}"
done | awk '{t[$1]+=$2; an[$1]+=$3; s+=$2; sa+=$3} END {for (k in t) printf "%8.1f %8.1f  %s\n", t[k]/1024, an[k]/1024, k; printf "%8.1f %8.1f  TOTAL (PSS, dont anonyme)\n", s/1024, sa/1024}' | sort -rn | head -30
echo "=== tmpfs"; df -m -t tmpfs | awk 'NR==1 || $3>0'
