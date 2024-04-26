#!/bin/bash
# Switch port mapping, default OFFLINE virtual port
# You should edit the mapping table by yourself
# Variable format: IB{LF/SP}{Switch number}=(port1 port2 port3 ...)
# Example: IBSP01=(47 48 51 52 61 62 63 64)
# LEAF
IBLF01=(29 30 31 32 34 36 38 40 42 44 46 48 50 52 54 56 58 60 62 64 66 68 70 72 74 76 78 80 82 84 86 88 90 92 94 96 125 126 127 128)
IBLF02=(29 30 31 32 34 36 38 40 42 44 46 48 50 52 54 56 58 60 62 64 66 68 70 72 74 76 78 80 82 84 86 88 90 92 94 96 125 126 127 128)
IBLF03=(29 30 31 32 34 36 38 40 42 44 46 48 50 52 54 56 58 60 62 64 66 68 70 72 74 76 78 80 82 84 86 88 90 92 94 96 125 126 127 128)
IBLF04=(29 30 31 32 34 36 38 40 42 44 46 48 50 52 54 56 58 60 62 64 66 68 70 72 74 76 78 80 82 84 86 88 90 92 94 96 125 126 127 128)
IBLF05=(29 30 31 32 34 36 38 40 42 44 46 48 50 52 54 56 58 60 62 64 66 68 70 72 74 76 78 80 82 84 86 88 90 92 94 96 125 126 127 128)
IBLF06=(29 30 31 32 34 36 38 40 42 44 46 48 50 52 54 56 58 60 62 64 66 68 70 72 74 76 78 80 82 84 86 88 90 92 94 96 125 126 127 128)
IBLF07=(29 30 31 32 34 36 38 40 42 44 46 48 50 52 54 56 58 60 62 64 66 68 70 72 74 76 78 80 82 84 86 88 90 92 94 96 125 126 127 128)
IBLF08=(29 30 31 32 34 36 38 40 42 44 46 48 50 52 54 56 58 60 62 64 66 68 70 72 74 76 78 80 82 84 86 88 90 92 94 96 125 126 127 128)
IBLF09=(29 30 31 32 34 36 38 40 42 44 46 48 50 52 54 56 58 60 62 64 66 68 70 72 74 76 78 80 82 84 86 88 90 92 94 96 125 126 127 128)
IBLF10=(25 26 27 28 29 30 31 32 34 36 38 40 42 44 46 48 50 52 54 56 58 60 62 64 66 68 70 72 74 76 78 80 82 84 86 88 90 92 94 96 121 122 123 124 125 126 127 128)
IBLF11=(25 26 27 28 29 30 31 32 34 36 38 40 42 44 46 48 50 52 54 56 58 60 62 64 66 68 70 72 74 76 78 80 82 84 86 88 90 92 94 96 117 118 119 120 121 122 123 124 125 126 127 128)
IBLF12=(9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 34 36 37 38 39 40 42 44 45 46 47 48 50 52 53 54 55 56 58 60 61 62 63 64 66 68 69 70 71 72 74 76 77 78 79 80 82 84 85 86 87 88 90 92 93 94 95 96 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128)
IBLF13=(13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 34 36 37 38 39 40 42 44 45 46 47 48 50 52 53 54 55 56 58 60 61 62 63 64 66 68 69 70 71 72 74 76 77 78 79 80 82 84 85 86 87 88 90 92 93 94 95 96 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128)
IBLF14=(1 2 4 6 8 10 12 14 16 17 18 20 21 22 23 24 25 26 27 28 29 30 31 32 34 36 38 40 42 44 46 48 50 52 54 56 58 60 62 64 66 68 70 72 74 76 78 80 82 84 86 88 90 92 94 96 97 98 99 100 101 102 103 104 106 108 109 110 111 112 114 116 118 120 122 123 124 126 128)
IBLF15=(1 2 3 4 6 8 10 12 14 16 17 18 19 20 22 24 25 26 27 28 29 30 31 32 34 36 38 40 42 44 46 48 50 52 54 56 58 60 62 64 66 68 70 72 74 76 78 80 82 84 86 88 90 92 94 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 114 116 118 120 122 123 124 126 128)
# SPINE
IBSP01=(47 48 51 52 61 62 63 64)
IBSP02=(47 48 51 52 61 62 63 64)
IBSP03=(47 48 51 52 61 62 63 64)
IBSP04=(47 48 51 52 61 62 63 64)
IBSP05=(47 48 51 52 61 62 63 64)
IBSP06=(47 48 51 52 61 62 63 64)
IBSP07=(47 48 51 52 61 62 63 64)
IBSP08=(47 48 51 52 61 62 63 64)
# Total available switches
switch_total_num=23

# Main code start
# Get IB switch information
switch_names=(`ibswitches | sort -k 6 | awk '{print $6}' | tr -d '"'`)
switch_guids=(`ibswitches | sort -k 6 | awk '{print $3}'`)
echo "Check switch and port status by iblinkinfo"
echo "Format: physical port(virtual port)"
echo `date`

# Check All swithces online
switch_total_online=`ibswitches | wc -l`
if [[ ${switch_total_online} -lt ${switch_total_num} ]]; then
  echo "######Warning######"
  echo "Some switches might down, please check!!!"
else
  echo "All Switches online OK"
fi

# Get offline virtual port number
count=0
for x in "${switch_names[@]}" ; do
  scan_now=(`iblinkinfo -S ${switch_guids[${count}]} -l -d | awk '{print $5}' | tr -d '['`)
  switch_vports=(`iblinkinfo -S ${switch_guids[${count}]} -l | wc -l`)
  tmp_array=$x[@]
  # Check offline virtual port
  # A[]-B[]
  port_offline=()
  for i in "${scan_now[@]}"; do
      skip=
      for j in "${!tmp_array}"; do
         [[ $i == $j ]] && { skip=1; break; }
      done
    [[ -n $skip ]] || port_offline+=("$i")
  done

  if [[ "${port_offline}" -eq " " ]]; then
    echo "$x OK"
  else
    # Find physical port
    for y in "${port_offline[@]}"; do
      # Calculate physical port
      # Ceiling( X / Y ) = ( X + Y – 1 ) / Y
      if [[ $switch_vports == 65 ]]; then
        port=$(( ($y + 2 - 1) / 2 )) #65 vports
      elif [[ $switch_vports == 129 ]]; then
        port=$(( ($y + 4 - 1) / 4 )) #129 vports
      else
        echo "Warning, Not support virtual port number"
        port="Unkown"
      fi
      echo "$x port $port($y) Down"
    done
  fi
  count=$((count+1))
done