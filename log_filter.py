from sys import argv
_, file_name = argv
lines = open(file_name).readlines()
stats_wh = open(file_name+'_stats.out', 'w')
throughput_wh = open(file_name+'_throughput.out', 'w')
for line in lines:
    if 'wait_for_pods.go:92' in line:
        wl = line.split()
        line_out = f"{wl[1]} {wl[7]} {wl[8]} {wl[12]} {eval(wl[13]):<3d} {wl[14]}" +\
            f" {eval(wl[17]):<3d} {wl[18]} {wl[19]} {eval(wl[20]):<3d} {wl[21]} {wl[22]}\n"
        stats_wh.write(line_out)
    elif 'scheduling_throughput.go:122' in line:
        wl = line.split()
        line_out = f"{wl[1]} {wl[4]} {eval(wl[8]):<3d} {wl[9]} {wl[10]} {wl[11]} {wl[12]}\n"
        throughput_wh.write(line_out)
    elif "wait_for_controlled_pods.go:217" in line:
        break
stats_wh.close()
throughput_wh.close()
