# outdated; works with old map data format, should work with minor changes though
import math

hillsize = 50;

def logistic(x):
    return 1/(1+math.exp(-10*(x-0.5)))

with open ('MapLUTGenerateFile.mif', 'w') as map:
    map.write("Width=9;\nDEPTH=65536;\nADDRESS_RADIX=HEX;\nDATA_RADIX=HEX;\nCONTENT BEGIN\n")
    for y in range(256):
        for x in range(256):
            addr = hex((y*256)+x)[2:].upper()
            map.write("\t" + addr + " : ")

            distance = math.sqrt((y-128)**2+(x-128)**2)
            color = 1
            if distance > 50:
                distance = hillsize
                color = 2

            height = round(logistic((hillsize - distance)/hillsize)*31) #invert so shaped like a cone, normalize to one, and sqrt to turn into mound
            if y == 15 and x > 20 and x < 40:
                height = 10 #create a different color wall across the map
                color = 4
            if y == 35 and x > 20 and x < 40:
                height = 10  # create a different color wall across the map
                color = 4
            if x == 20 and y > 15 and y < 35:
                height = 10  # create a different color wall across the map
                color = 4
            if x == 40 and y > 15 and y < 35:
                height = 10  # create a different color wall across the map
                color = 4
            if x>20 and x<40 and y>15 and y<35:
                xdist = abs(30-x)
                ydist = abs(25-y)
                height = 15 - (0.25 * (xdist + ydist))
                color = 5

            heightandcolor = hex(int(height)*16 + color) #make flat area and hill different colors
            map.write(str(heightandcolor)[2:].upper())

            map.write(";\n")
    map.write("END;")

