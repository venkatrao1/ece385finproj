import math
pi = math.pi
with open('TrigLUTmif.txt', 'w') as trig:
    for i in range(512):
        trig.write("\t" + hex(i)[2:].upper() + " : ")
        origval = hex(int(round(math.sin((pi/1024)*i) * 2**36)))[2:]
        truncatedval = origval.upper()
        trig.write(truncatedval)
        trig.write(';\n')