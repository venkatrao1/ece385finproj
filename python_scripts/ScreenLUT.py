import math
FOV = 35
radFOV = math.radians(FOV)
with open ('ScreenLUTmif.txt', 'w') as writer:
    for d_ctr in range(512):
        addr = hex(int(d_ctr)).upper()[2:]
        writer.write("\t" + addr + " : ")
        value = 240/(math.tan(math.tau*245/2048)*math.tan(radFOV))
        writer.write(hex(int(round(((2**27)-1)/(d_ctr+1)))).upper()[2:])

        writer.write(";\n")