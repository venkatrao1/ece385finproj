import math
horizFov = (245/2048)*math.tau
step = math.sin(horizFov)/319
with open("RenderStepLUTmif.txt", 'w') as writer:
    for angle in range(1024):
        addr = hex(int(angle)).upper()[2:]
        tmp = math.sin((angle/2048)*math.tau)*step
        writer.write("\t" + addr + " : ")
        writer.write(hex(int(round(tmp*(2**36)*(2**8)))).upper()[2:])
        writer.write(";\n")